import Foundation
import SwiftUI
import AVFoundation
import Combine

// MARK: - AI Coach Video Analysis Service
@MainActor
class AICoachVideoAnalysisService: ObservableObject {
    
    // MARK: - Dependencies
    let videoInputManager: VideoInputManagerProtocol
    private let poseDetectionEngine: PoseDetectionEngineProtocol
    private let formEvaluationEngine: FormEvaluationEngineProtocol
    private let secureStorage: SecureVideoStorageProtocol
    
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var lastAnalysisResult: VideoFormAnalysisResult?
    @Published var lastError: AICoachError?
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0.0
    
    // MARK: - Private Properties
    private var currentAnalysisTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(
        videoInputManager: VideoInputManagerProtocol? = nil,
        poseDetectionEngine: PoseDetectionEngineProtocol = PoseDetectionEngine(),
        formEvaluationEngine: FormEvaluationEngineProtocol = FormEvaluationEngine(),
        secureStorage: SecureVideoStorageProtocol = SecureVideoStorage()
    ) {
        self.videoInputManager = videoInputManager ?? VideoInputManager()
        self.poseDetectionEngine = poseDetectionEngine
        self.formEvaluationEngine = formEvaluationEngine
        self.secureStorage = secureStorage
        
        // Observe video input manager state
        if let inputManager = videoInputManager as? VideoInputManager {
            inputManager.$captureState
                .sink { [weak self] state in
                    self?.handleCaptureStateChange(state)
                }
                .store(in: &cancellables)
            
            inputManager.$recordingDuration
                .sink { [weak self] duration in
                    self?.recordingDuration = duration
                }
                .store(in: &cancellables)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        currentAnalysisTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Start recording a video for form analysis
    func startVideoRecording(exerciseType: ExerciseType) async {
        do {
            isRecording = true
            let session = try await videoInputManager.startVideoCapture(exerciseType: exerciseType)
            print("Started recording video for \(exerciseType.displayName)")
        } catch {
            lastError = .videoRecordingFailed(error)
            isRecording = false
        }
    }
    
    /// Stop recording and analyze the captured video
    func stopVideoRecordingAndAnalyze() async -> VideoFormAnalysisResult? {
        do {
            isRecording = false
            guard let session = try await videoInputManager.stopVideoCapture() else {
                throw AICoachError.noVideoSession
            }
            
            return await analyzeVideoSession(session)
        } catch {
            lastError = .videoProcessingFailed(error)
            return nil
        }
    }
    
    /// Analyze an imported video file
    func analyzeImportedVideo(url: URL, exerciseType: ExerciseType) async -> VideoFormAnalysisResult? {
        do {
            // Import and validate video
            let container = try await videoInputManager.importVideo(from: url)
            
            // Create session for analysis
            let session = VideoSession(
                id: UUID(),
                exerciseType: exerciseType,
                recordingURL: container.secureURL,
                startTime: container.importDate
            )
            
            return await analyzeVideoSession(session)
        } catch {
            lastError = .videoImportFailed(error)
            return nil
        }
    }
    
    /// Get all previously analyzed videos
    func getAllAnalyzedVideos() async -> [VideoFormAnalysisResult] {
        do {
            let storedVideos = try await secureStorage.getAllStoredVideos()
            // In a full implementation, you'd load the analysis results from storage
            // For now, return empty array
            return []
        } catch {
            lastError = .storageError(error)
            return []
        }
    }
    
    /// Delete a video and its analysis
    func deleteVideo(identifier: String) async {
        do {
            try await secureStorage.securelyDelete(identifier: identifier)
        } catch {
            lastError = .storageError(error)
        }
    }
    
    /// Enforce retention policy (delete old videos)
    func enforceRetentionPolicy() async {
        do {
            try await secureStorage.enforceRetentionPolicy()
        } catch {
            lastError = .storageError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func analyzeVideoSession(_ session: VideoSession) async -> VideoFormAnalysisResult? {
        // Cancel any existing analysis
        currentAnalysisTask?.cancel()
        
        currentAnalysisTask = Task {
            await performVideoAnalysis(session)
        }
        
        await currentAnalysisTask?.value
        return lastAnalysisResult
    }
    
    private func performVideoAnalysis(_ session: VideoSession) async {
        isAnalyzing = true
        analysisProgress = 0.0
        lastError = nil
        
        do {
            // Step 1: Extract frames from video (20% of progress)
            updateProgress(0.05, status: "Preparing video...")
            
            let frames = try await poseDetectionEngine.extractFramesFromVideo(
                url: session.recordingURL,
                frameInterval: 0.1 // 10 FPS sampling
            )
            
            guard !frames.isEmpty else {
                throw AICoachError.noFramesExtracted
            }
            
            updateProgress(0.2, status: "Extracted \(frames.count) frames")
            
            // Step 2: Detect poses in frames (40% of progress)
            updateProgress(0.25, status: "Detecting poses...")
            
            let poseSequence = try await poseDetectionEngine.detectPoseSequence(in: frames)
            
            guard !poseSequence.isEmpty else {
                throw AICoachError.noPosesDetected
            }
            
            updateProgress(0.6, status: "Detected poses in \(poseSequence.count) frames")
            
            // Step 3: Evaluate form (30% of progress)
            updateProgress(0.65, status: "Analyzing form...")
            
            let formAnalysis = try await formEvaluationEngine.evaluateForm(
                poseSequence,
                exerciseType: session.exerciseType
            )
            
            updateProgress(0.85, status: "Generating feedback...")
            
            // Step 4: Generate feedback (10% of progress)
            let feedback = formEvaluationEngine.generateFeedback(
                from: formAnalysis,
                userLevel: getCurrentUserFitnessLevel()
            )
            
            // Create final result
            let result = VideoFormAnalysisResult(
                id: UUID(),
                session: session,
                formAnalysis: formAnalysis,
                feedback: feedback,
                poseQuality: calculateOverallPoseQuality(poseSequence),
                videoQuality: await getVideoQuality(session.recordingURL),
                analysisDate: Date()
            )
            
            updateProgress(1.0, status: "Analysis complete!")
            
            // Store result
            lastAnalysisResult = result
            
            // Clean up temporary files if needed
            await cleanupTemporaryFiles(session)
            
        } catch {
            lastError = .analysisError(error)
            print("Video analysis failed: \(error)")
        }
        
        isAnalyzing = false
    }
    
    private func updateProgress(_ progress: Double, status: String) {
        Task { @MainActor in
            self.analysisProgress = progress
            print("Analysis progress: \(Int(progress * 100))% - \(status)")
        }
    }
    
    private func handleCaptureStateChange(_ state: VideoCaptureState) {
        switch state {
        case .idle:
            isRecording = false
        case .preparing:
            isRecording = true
        case .recording:
            isRecording = true
        case .processing:
            isRecording = false
        case .completed:
            isRecording = false
        case .failed(let error):
            isRecording = false
            lastError = .videoRecordingFailed(error)
        }
    }
    
    private func calculateOverallPoseQuality(_ poseSequence: [PoseKeypoints]) -> PoseQualityMetrics {
        guard !poseSequence.isEmpty else {
            return PoseQualityMetrics(
                averageConfidence: 0.0,
                completenessScore: 0.0,
                consistencyScore: 0.0,
                overallScore: 0.0
            )
        }
        
        let averageConfidence = poseSequence.reduce(0.0) { sum, pose in
            sum + Double(pose.overallConfidence)
        } / Double(poseSequence.count)
        
        let validJointCounts = poseSequence.map { $0.allValidJoints.count }
        let maxJoints = validJointCounts.max() ?? 1
        let completenessScore = validJointCounts.reduce(0) { $0 + $1 } / (poseSequence.count * maxJoints)
        
        // Calculate consistency (variance in confidence)
        let confidences = poseSequence.map { Double($0.overallConfidence) }
        let meanConfidence = confidences.reduce(0, +) / Double(confidences.count)
        let variance = confidences.reduce(0) { sum, conf in
            sum + pow(conf - meanConfidence, 2)
        } / Double(confidences.count)
        let consistencyScore = max(0.0, 1.0 - sqrt(variance))
        
        let overallScore = (averageConfidence * 0.4 + Double(completenessScore) * 0.4 + consistencyScore * 0.2)
        
        return PoseQualityMetrics(
            averageConfidence: averageConfidence,
            completenessScore: Double(completenessScore),
            consistencyScore: consistencyScore,
            overallScore: overallScore
        )
    }
    
    private func getVideoQuality(_ url: URL) async -> VideoQualityMetrics {
        do {
            let validator = VideoQualityValidator()
            let report = try await validator.validateVideo(at: url)
            
            return VideoQualityMetrics(
                resolution: report.resolution,
                frameRate: report.frameRate,
                duration: report.duration,
                qualityScore: report.qualityScore,
                isHighQuality: report.isHighQuality
            )
        } catch {
            return VideoQualityMetrics(
                resolution: CGSize.zero,
                frameRate: 0,
                duration: 0,
                qualityScore: 0,
                isHighQuality: false
            )
        }
    }
    
    private func getCurrentUserFitnessLevel() -> UserFitnessLevel {
        // In a real implementation, this would be retrieved from user profile
        // For now, default to beginner
        return .beginner
    }
    
    private func cleanupTemporaryFiles(_ session: VideoSession) async {
        // Clean up any temporary files created during analysis
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFiles = (try? FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)) ?? []
        
        for file in tempFiles {
            if file.pathExtension == "mov" || file.pathExtension == "mp4" {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}

// MARK: - Supporting Data Models
struct VideoFormAnalysisResult: Identifiable {
    let id: UUID
    let session: VideoSession
    let formAnalysis: FormAnalysisResult
    let feedback: FormFeedback
    let poseQuality: PoseQualityMetrics
    let videoQuality: VideoQualityMetrics
    let analysisDate: Date
    
    var exerciseType: ExerciseType {
        session.exerciseType
    }
    
    var overallScore: Double {
        formAnalysis.overallScore
    }
    
    var duration: TimeInterval {
        session.duration ?? videoQuality.duration
    }
}

struct PoseQualityMetrics {
    let averageConfidence: Double
    let completenessScore: Double
    let consistencyScore: Double
    let overallScore: Double
    
    var qualityLevel: String {
        switch overallScore {
        case 0.8...1.0: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        default: return "Poor"
        }
    }
}

struct VideoQualityMetrics {
    let resolution: CGSize
    let frameRate: Float
    let duration: TimeInterval
    let qualityScore: Double
    let isHighQuality: Bool
    
    var resolutionString: String {
        return "\(Int(resolution.width))x\(Int(resolution.height))"
    }
}

enum AICoachError: LocalizedError {
    case videoRecordingFailed(Error)
    case videoProcessingFailed(Error)
    case videoImportFailed(Error)
    case noVideoSession
    case noFramesExtracted
    case noPosesDetected
    case analysisError(Error)
    case storageError(Error)
    
    var errorDescription: String? {
        switch self {
        case .videoRecordingFailed(let error):
            return "Failed to record video: \(error.localizedDescription)"
        case .videoProcessingFailed(let error):
            return "Failed to process video: \(error.localizedDescription)"
        case .videoImportFailed(let error):
            return "Failed to import video: \(error.localizedDescription)"
        case .noVideoSession:
            return "No video session available for analysis."
        case .noFramesExtracted:
            return "Could not extract frames from video."
        case .noPosesDetected:
            return "No poses detected in video. Please ensure you're clearly visible."
        case .analysisError(let error):
            return "Analysis failed: \(error.localizedDescription)"
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        }
    }
}
