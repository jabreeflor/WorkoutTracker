import Foundation
import AVFoundation
import SwiftUI

// MARK: - Video Input Manager Protocol
protocol VideoInputManagerProtocol {
    func startVideoCapture(exerciseType: ExerciseType) async throws -> VideoSession
    func importVideo(from url: URL) async throws -> VideoContainer
    func validateVideoQuality(_ videoURL: URL) async throws -> VideoQualityAssessment
    func stopVideoCapture() async throws -> VideoSession?
}

// MARK: - Video Input Manager Implementation
@MainActor
class VideoInputManager: NSObject, ObservableObject, VideoInputManagerProtocol {
    // MARK: - Dependencies
    private let securityManager: VideoSecurityManager
    private let qualityValidator: VideoQualityValidator
    private let storageManager: SecureVideoStorage

    // MARK: - Published State
    @Published var captureState: VideoCaptureState = .idle
    @Published var importProgress: Double = 0.0
    @Published var lastError: VideoInputError?
    @Published var recordingDuration: TimeInterval = 0.0

    // MARK: - Private Properties
    private let captureSession = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var currentRecordingURL: URL?
    private var currentVideoSession: VideoSession?
    private var recordingTimer: Timer?
    
    // MARK: - Preview Layer
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    // MARK: - Initialization
    init(
        securityManager: VideoSecurityManager = VideoSecurityManager(),
        qualityValidator: VideoQualityValidator = VideoQualityValidator(),
        storageManager: SecureVideoStorage = SecureVideoStorage()
    ) {
        self.securityManager = securityManager
        self.qualityValidator = qualityValidator
        self.storageManager = storageManager
        super.init()
        
        configureCaptureSession()
    }
    
    deinit {
        // Use Task for async cleanup in deinit
        Task { @MainActor in
            stopCaptureSession()
        }
    }
    
    // MARK: - Video Capture
    func startVideoCapture(exerciseType: ExerciseType) async throws -> VideoSession {
        // Request camera access
        let authStatus = await requestCameraAccess()
        switch authStatus {
        case .authorized:
            break // Continue with recording
        case .denied, .restricted:
            throw VideoInputError.cameraAccessDenied
        case .notDetermined:
            // This shouldn't happen since requestCameraAccess handles it
            throw VideoInputError.cameraAccessDenied
        @unknown default:
            throw VideoInputError.cameraAccessDenied
        }
        
        // Prepare the session for recording
        captureState = .preparing
        let videoURL = try await securityManager.createSecureVideoURL()
        currentRecordingURL = videoURL
        
        // Create video session
        let session = VideoSession(
            id: UUID(),
            exerciseType: exerciseType,
            recordingURL: videoURL,
            startTime: Date()
        )
        currentVideoSession = session
        
        // Start the session on background thread to avoid UI blocking
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
                continuation.resume()
            }
        }
        
        // Verify we have active connections before starting recording
        guard !movieOutput.connections.isEmpty,
              let connection = movieOutput.connection(with: .video),
              connection.isEnabled else {
            throw VideoInputError.sessionConfigurationFailed
        }
        
        movieOutput.startRecording(to: videoURL, recordingDelegate: self)
        
        captureState = .recording(startTime: Date())
        startRecordingTimer()
        
        return session
    }
    
    func stopVideoCapture() async throws -> VideoSession? {
        guard case .recording = captureState else {
            throw VideoInputError.notCurrentlyRecording
        }
        
        captureState = .processing
        stopRecordingTimer()
        
        // Stop recording
        movieOutput.stopRecording()
        
        // Wait for recording to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        guard let session = currentVideoSession else {
            throw VideoInputError.sessionNotFound
        }
        
        // Update session with end time
        var completedSession = session
        completedSession.endTime = Date()
        
        captureState = .completed(completedSession)
        currentVideoSession = nil
        currentRecordingURL = nil
        
        return completedSession
    }
    
    // MARK: - Video Import
    func importVideo(from url: URL) async throws -> VideoContainer {
        importProgress = 0.0
        
        // Validate and import video from the given URL
        let qualityAssessment = try await validateVideoQuality(url)
        importProgress = 0.5
        
        let secureContainer = try await storageManager.securelyStore(videoURL: url, exerciseType: .unknown)
        importProgress = 1.0
        
        return VideoContainer(
            id: UUID(),
            secureURL: secureContainer.secureURL,
            metadata: VideoMetadata(exerciseType: .unknown, duration: qualityAssessment.duration),
            qualityAssessment: qualityAssessment,
            importDate: Date()
        )
    }
    
    // MARK: - Video Quality Validation
    func validateVideoQuality(_ videoURL: URL) async throws -> VideoQualityAssessment {
        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        guard durationSeconds > 0 else {
            throw VideoInputError.invalidVideoDuration
        }
        
        // Check video tracks
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw VideoInputError.noVideoTrackFound
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
        
        return VideoQualityAssessment(
            resolution: "\(Int(naturalSize.width))x\(Int(naturalSize.height))",
            frameRate: Float(nominalFrameRate),
            duration: durationSeconds,
            isValid: durationSeconds >= 5.0 && naturalSize.width >= 720, // Minimum requirements
            fileSize: try getFileSize(at: videoURL)
        )
    }
    
    // MARK: - Private Methods
    private func configureCaptureSession() {
        captureSession.beginConfiguration()
        
        // Set session preset for high quality
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        // Video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            captureSession.commitConfiguration()
            lastError = .sessionConfigurationFailed
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                captureSession.commitConfiguration()
                lastError = .sessionConfigurationFailed
                return
            }
        } catch {
            captureSession.commitConfiguration()
            lastError = .sessionConfigurationFailed
            return
        }
        
        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        } else {
            captureSession.commitConfiguration()
            lastError = .sessionConfigurationFailed
            return
        }
        
        captureSession.commitConfiguration()
        
        // Configure connections after committing configuration
        if let connection = movieOutput.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
            // Ensure connection is enabled
            connection.isEnabled = true
        } else {
            lastError = .sessionConfigurationFailed
            return
        }
    }
    
    private func stopCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
        stopRecordingTimer()
    }
    
    private func startRecordingTimer() {
        recordingDuration = 0.0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.recordingDuration += 0.1
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func requestCameraAccess() async -> AVAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return .authorized
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        case .denied, .restricted:
            return status
        @unknown default:
            return .denied
        }
    }
    
    // MARK: - Permission Status Monitoring
    func getCameraPermissionStatus() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func canRecordVideo() -> Bool {
        return getCameraPermissionStatus() == .authorized
    }
    
    private func getFileSize(at url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension VideoInputManager: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.lastError = .recordingFailed(error)
                self.captureState = .failed(.recordingFailed(error))
            } else {
                // Recording completed successfully
                print("Video recording completed successfully at: \(outputFileURL)")
            }
        }
    }
}

// MARK: - Supporting Data Models
struct VideoSession: Identifiable, Equatable {
    let id: UUID
    let exerciseType: ExerciseType
    let recordingURL: URL
    let startTime: Date
    var endTime: Date?
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    static func == (lhs: VideoSession, rhs: VideoSession) -> Bool {
        return lhs.id == rhs.id
    }
}

struct VideoContainer: Identifiable {
    let id: UUID
    let secureURL: URL
    let metadata: VideoMetadata
    let qualityAssessment: VideoQualityAssessment
    let importDate: Date
}

struct VideoMetadata: Codable {
    let exerciseType: ExerciseType
    let duration: TimeInterval
    let creationDate: Date
    
    init(exerciseType: ExerciseType, duration: TimeInterval) {
        self.exerciseType = exerciseType
        self.duration = duration
        self.creationDate = Date()
    }
}

struct VideoQualityAssessment {
    let resolution: String
    let frameRate: Float
    let duration: TimeInterval
    let isValid: Bool
    let fileSize: Int64
}

enum VideoCaptureState: Equatable {
    case idle
    case preparing
    case recording(startTime: Date)
    case processing
    case completed(VideoSession)
    case failed(VideoInputError)
}

enum VideoInputError: LocalizedError, Equatable {
    case cameraAccessDenied
    case cameraNotAvailable
    case invalidVideoDuration
    case noVideoTrackFound
    case notCurrentlyRecording
    case sessionNotFound
    case sessionConfigurationFailed
    case recordingFailed(Error)
    
    static func == (lhs: VideoInputError, rhs: VideoInputError) -> Bool {
        switch (lhs, rhs) {
        case (.cameraAccessDenied, .cameraAccessDenied),
             (.cameraNotAvailable, .cameraNotAvailable),
             (.invalidVideoDuration, .invalidVideoDuration),
             (.noVideoTrackFound, .noVideoTrackFound),
             (.notCurrentlyRecording, .notCurrentlyRecording),
             (.sessionNotFound, .sessionNotFound),
             (.sessionConfigurationFailed, .sessionConfigurationFailed):
            return true
        case (.recordingFailed(let lhsError), .recordingFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .cameraAccessDenied:
            return "Camera access is required to record workout videos. Please enable camera access in Settings."
        case .cameraNotAvailable:
            return "Camera is not available on this device."
        case .invalidVideoDuration:
            return "Video duration is invalid or too short."
        case .noVideoTrackFound:
            return "No video track found in the file."
        case .notCurrentlyRecording:
            return "No active recording session found."
        case .sessionNotFound:
            return "Video session not found."
        case .sessionConfigurationFailed:
            return "Failed to configure camera session."
        case .recordingFailed(let error):
            return "Recording failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Exercise Type Enum
enum ExerciseType: String, CaseIterable, Codable {
    case squat = "squat"
    case deadlift = "deadlift"
    case benchPress = "benchPress"
    case shoulderPress = "shoulderPress"
    case pullUp = "pullUp"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .squat: return "Squat"
        case .deadlift: return "Deadlift"
        case .benchPress: return "Bench Press"
        case .shoulderPress: return "Shoulder Press"
        case .pullUp: return "Pull Up"
        case .unknown: return "Unknown"
        }
    }
}
