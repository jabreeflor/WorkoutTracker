import Foundation
import Vision
import CoreImage
import AVFoundation

// MARK: - Pose Detection Engine Protocol
protocol PoseDetectionEngineProtocol {
    func detectPoseSequence(in frames: [CGImage]) async throws -> [PoseKeypoints]
    func detectSinglePose(in image: CGImage) async throws -> PoseKeypoints?
    func validatePoseQuality(_ pose: PoseKeypoints, for exerciseType: ExerciseType) -> PoseQualityAssessment
    func extractFramesFromVideo(url: URL, frameInterval: TimeInterval) async throws -> [CGImage]
}

// MARK: - Pose Detection Engine Implementation
class PoseDetectionEngine: PoseDetectionEngineProtocol {
    private let poseDetector = VNDetectHumanBodyPoseRequest()
    
    init() {
        configurePoseDetector()
    }
    
    // MARK: - Frame Extraction
    func extractFramesFromVideo(url: URL, frameInterval: TimeInterval = 0.1) async throws -> [CGImage] {
        let asset = AVURLAsset(url: url)
        let reader = try AVAssetReader(asset: asset)
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw PoseDetectionError.noVideoTrack
        }
        
        let readerOutput = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
        )
        
        reader.add(readerOutput)
        reader.startReading()
        
        var frames: [CGImage] = []
        let duration = try await asset.load(.duration)
        let _ = CMTimeGetSeconds(duration) // totalDuration not used in current implementation
        let frameRate = try await videoTrack.load(.nominalFrameRate)
        
        // Calculate frame sampling
        let samplingRate = max(1, Int(Double(frameRate) * frameInterval))
        var frameCount = 0
        
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            frameCount += 1
            
            // Skip frames based on sampling rate
            if frameCount % samplingRate != 0 {
                continue
            }
            
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                continue
            }
            
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                continue
            }
            
            frames.append(cgImage)
            
            // Limit number of frames to prevent memory issues
            if frames.count >= 300 { // ~30 seconds at 10fps
                break
            }
        }
        
        return frames
    }
    
    // MARK: - Pose Detection
    func detectPoseSequence(in frames: [CGImage]) async throws -> [PoseKeypoints] {
        var poseSequence: [PoseKeypoints] = []
        
        for (index, frame) in frames.enumerated() {
            do {
                if let pose = try await detectSinglePose(in: frame) {
                    var poseWithTimestamp = pose
                    poseWithTimestamp.frameIndex = index
                    poseWithTimestamp.timestamp = Date().addingTimeInterval(Double(index) * 0.1)
                    poseSequence.append(poseWithTimestamp)
                }
            } catch {
                // Log error but continue processing other frames
                print("Failed to detect pose in frame \(index): \(error)")
                continue
            }
        }
        
        guard !poseSequence.isEmpty else {
            throw PoseDetectionError.insufficientValidPoses(detected: 0, required: 1)
        }
        
        return poseSequence
    }
    
    func detectSinglePose(in image: CGImage) async throws -> PoseKeypoints? {
        let request = VNImageRequestHandler(cgImage: image, options: [:])
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try request.perform([poseDetector])
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        guard let observation = poseDetector.results?.first else {
            return nil
        }
        
        return try extractKeypoints(from: observation, image: image)
    }
    
    // MARK: - Pose Quality Validation
    func validatePoseQuality(_ pose: PoseKeypoints, for exerciseType: ExerciseType) -> PoseQualityAssessment {
        let requiredJoints = getRequiredJoints(for: exerciseType)
        let detectedJoints = pose.allValidJoints
        
        // Calculate completeness score
        let completenessScore = Double(detectedJoints.count) / Double(requiredJoints.count)
        
        // Calculate confidence score
        let confidenceScore = detectedJoints.reduce(0.0) { sum, joint in
            sum + Double(joint.confidence)
        } / Double(max(detectedJoints.count, 1))
        
        // Calculate stability score (based on confidence variance)
        let confidences = detectedJoints.map { Double($0.confidence) }
        let meanConfidence = confidences.reduce(0, +) / Double(max(confidences.count, 1))
        let variance = confidences.reduce(0) { sum, conf in
            sum + pow(conf - meanConfidence, 2)
        } / Double(max(confidences.count, 1))
        let stabilityScore = max(0.0, 1.0 - sqrt(variance))
        
        // Overall quality calculation
        let overallQuality = (completenessScore * 0.4 + confidenceScore * 0.4 + stabilityScore * 0.2)
        
        // Find missing joints
        let detectedJointNames = Set(detectedJoints.map { $0.jointName })
        let missingJoints = requiredJoints.filter { joint in
            !detectedJointNames.contains(String(describing: joint))
        }
        
        return PoseQualityAssessment(
            overallQuality: Float(overallQuality),
            confidenceScore: Float(confidenceScore),
            completenessScore: Float(completenessScore),
            stabilityScore: Float(stabilityScore),
            missingJoints: missingJoints,
            isAcceptable: overallQuality >= 0.6 && completenessScore >= 0.7
        )
    }
    
    // MARK: - Private Methods
    private func configurePoseDetector() {
        poseDetector.revision = VNDetectHumanBodyPoseRequestRevision1
    }
    
    private func extractKeypoints(from observation: VNHumanBodyPoseObservation, image: CGImage) throws -> PoseKeypoints {
        let landmarks = try observation.recognizedPoints(.all)
        
        // Convert normalized points to image coordinates
        let imageSize = CGSize(width: image.width, height: image.height)
        
        func convertPoint(_ point: VNRecognizedPoint?, jointName: VNHumanBodyPoseObservation.JointName) -> BodyKeypoint? {
            guard let point = point, point.confidence > 0.3 else { return nil }
            
            let imagePoint = CGPoint(
                x: point.location.x * imageSize.width,
                y: (1.0 - point.location.y) * imageSize.height // Flip Y coordinate
            )
            
            return BodyKeypoint(
                position: imagePoint,
                confidence: point.confidence,
                jointName: String(describing: jointName)
            )
        }
        
        return PoseKeypoints(
            id: UUID(),
            frameIndex: 0, // Will be set by caller
            timestamp: Date(),
            head: convertPoint(landmarks[.nose], jointName: .nose),
            neck: convertPoint(landmarks[.neck], jointName: .neck),
            leftShoulder: convertPoint(landmarks[.leftShoulder], jointName: .leftShoulder),
            rightShoulder: convertPoint(landmarks[.rightShoulder], jointName: .rightShoulder),
            leftElbow: convertPoint(landmarks[.leftElbow], jointName: .leftElbow),
            rightElbow: convertPoint(landmarks[.rightElbow], jointName: .rightElbow),
            leftWrist: convertPoint(landmarks[.leftWrist], jointName: .leftWrist),
            rightWrist: convertPoint(landmarks[.rightWrist], jointName: .rightWrist),
            leftHip: convertPoint(landmarks[.leftHip], jointName: .leftHip),
            rightHip: convertPoint(landmarks[.rightHip], jointName: .rightHip),
            leftKnee: convertPoint(landmarks[.leftKnee], jointName: .leftKnee),
            rightKnee: convertPoint(landmarks[.rightKnee], jointName: .rightKnee),
            leftAnkle: convertPoint(landmarks[.leftAnkle], jointName: .leftAnkle),
            rightAnkle: convertPoint(landmarks[.rightAnkle], jointName: .rightAnkle),
            overallConfidence: observation.confidence
        )
    }
    
    private func getRequiredJoints(for exerciseType: ExerciseType) -> [VNHumanBodyPoseObservation.JointName] {
        switch exerciseType {
        case .squat:
            return [.leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
                   .leftShoulder, .rightShoulder, .neck]
        case .deadlift:
            return [.leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
                   .leftShoulder, .rightShoulder, .leftWrist, .rightWrist, .neck]
        case .benchPress:
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
                   .leftWrist, .rightWrist, .neck]
        case .shoulderPress:
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
                   .leftWrist, .rightWrist, .neck, .leftHip, .rightHip]
        case .pullUp:
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
                   .leftWrist, .rightWrist, .neck, .leftHip, .rightHip]
        case .unknown:
            return [.nose, .leftEye, .rightEye, .leftEar, .rightEar,
                   .neck, .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
                   .leftWrist, .rightWrist, .leftHip, .rightHip, .leftKnee, .rightKnee,
                   .leftAnkle, .rightAnkle, .root]
        }
    }
}

// MARK: - Enhanced Data Models
struct PoseKeypoints: Identifiable, Codable {
    let id: UUID
    var frameIndex: Int = 0
    var timestamp: Date
    let head: BodyKeypoint?
    let neck: BodyKeypoint?
    let leftShoulder: BodyKeypoint?
    let rightShoulder: BodyKeypoint?
    let leftElbow: BodyKeypoint?
    let rightElbow: BodyKeypoint?
    let leftWrist: BodyKeypoint?
    let rightWrist: BodyKeypoint?
    let leftHip: BodyKeypoint?
    let rightHip: BodyKeypoint?
    let leftKnee: BodyKeypoint?
    let rightKnee: BodyKeypoint?
    let leftAnkle: BodyKeypoint?
    let rightAnkle: BodyKeypoint?
    let overallConfidence: Float
    
    var allJoints: [BodyKeypoint] {
        return [head, neck, leftShoulder, rightShoulder, leftElbow, rightElbow,
                leftWrist, rightWrist, leftHip, rightHip, leftKnee, rightKnee,
                leftAnkle, rightAnkle].compactMap { $0 }
    }
    
    var allValidJoints: [BodyKeypoint] {
        return allJoints.filter { $0.confidence > 0.5 }
    }
    
    var centerOfMass: CGPoint? {
        let validJoints = allValidJoints
        guard !validJoints.isEmpty else { return nil }
        
        let totalX = validJoints.reduce(0) { $0 + $1.position.x }
        let totalY = validJoints.reduce(0) { $0 + $1.position.y }
        
        return CGPoint(
            x: totalX / CGFloat(validJoints.count),
            y: totalY / CGFloat(validJoints.count)
        )
    }
}

struct BodyKeypoint: Codable {
    let position: CGPoint
    let confidence: Float
    var jointName: String
    
    init(position: CGPoint, confidence: Float, jointName: String) {
        self.position = position
        self.confidence = confidence
        self.jointName = jointName
    }
}

struct PoseQualityAssessment {
    let overallQuality: Float
    let confidenceScore: Float
    let completenessScore: Float
    let stabilityScore: Float
    let missingJoints: [VNHumanBodyPoseObservation.JointName]
    let isAcceptable: Bool
    
    var qualityLevel: QualityLevel {
        switch overallQuality {
        case 0.8...1.0: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        default: return .poor
        }
    }
    
    enum QualityLevel: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .fair: return "orange"
            case .poor: return "red"
            }
        }
    }
}

enum PoseDetectionError: LocalizedError {
    case noVideoTrack
    case noFramesProvided
    case insufficientValidPoses(detected: Int, required: Int)
    case visionFrameworkError(Error)
    case requestExecutionFailed(Error)
    case invalidPoseData
    case frameExtractionFailed
    
    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "No video track found in the video file."
        case .noFramesProvided:
            return "No frames were provided for pose detection."
        case .insufficientValidPoses(let detected, let required):
            return "Insufficient valid poses detected: \(detected) (required: \(required))"
        case .visionFrameworkError(let error):
            return "Vision framework error: \(error.localizedDescription)"
        case .requestExecutionFailed(let error):
            return "Request execution failed: \(error.localizedDescription)"
        case .invalidPoseData:
            return "Invalid or corrupted pose data."
        case .frameExtractionFailed:
            return "Failed to extract frames from video."
        }
    }
}
