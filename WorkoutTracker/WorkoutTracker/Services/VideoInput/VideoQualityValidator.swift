import Foundation
import AVFoundation

// MARK: - Video Quality Validator
class VideoQualityValidator {
    
    // MARK: - Quality Standards
    struct QualityStandards {
        static let minimumDuration: TimeInterval = 3.0 // 3 seconds minimum
        static let maximumDuration: TimeInterval = 300.0 // 5 minutes maximum
        static let minimumResolutionWidth: CGFloat = 480
        static let minimumResolutionHeight: CGFloat = 640
        static let minimumFrameRate: Float = 15.0
        static let maximumFileSize: Int64 = 500 * 1024 * 1024 // 500MB
    }
    
    // MARK: - Validation Methods
    func validateVideo(at url: URL) async throws -> VideoQualityReport {
        let asset = AVAsset(url: url)
        
        // Validate basic asset properties
        guard try await asset.load(.isReadable) else {
            throw VideoQualityError.fileNotReadable
        }
        
        // Get duration
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        // Get video tracks
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw VideoQualityError.noVideoTrack
        }
        
        // Get video properties
        let naturalSize = try await videoTrack.load(.naturalSize)
        let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
        
        // Get file size
        let fileSize = try getFileSize(at: url)
        
        // Create quality report
        let report = VideoQualityReport(
            duration: durationSeconds,
            resolution: naturalSize,
            frameRate: nominalFrameRate,
            fileSize: fileSize,
            isReadable: true
        )
        
        // Validate against standards
        try validateQualityReport(report)
        
        return report
    }
    
    private func validateQualityReport(_ report: VideoQualityReport) throws {
        var issues: [VideoQualityIssue] = []
        
        // Check duration
        if report.duration < QualityStandards.minimumDuration {
            issues.append(.durationTooShort(actual: report.duration, required: QualityStandards.minimumDuration))
        } else if report.duration > QualityStandards.maximumDuration {
            issues.append(.durationTooLong(actual: report.duration, maximum: QualityStandards.maximumDuration))
        }
        
        // Check resolution
        if report.resolution.width < QualityStandards.minimumResolutionWidth ||
           report.resolution.height < QualityStandards.minimumResolutionHeight {
            issues.append(.resolutionTooLow(
                actual: report.resolution,
                minimum: CGSize(
                    width: QualityStandards.minimumResolutionWidth,
                    height: QualityStandards.minimumResolutionHeight
                )
            ))
        }
        
        // Check frame rate
        if report.frameRate < QualityStandards.minimumFrameRate {
            issues.append(.frameRateTooLow(actual: report.frameRate, minimum: QualityStandards.minimumFrameRate))
        }
        
        // Check file size
        if report.fileSize > QualityStandards.maximumFileSize {
            issues.append(.fileSizeTooLarge(actual: report.fileSize, maximum: QualityStandards.maximumFileSize))
        }
        
        // Throw error if critical issues found
        if !issues.isEmpty {
            let criticalIssues = issues.filter { $0.isCritical }
            if !criticalIssues.isEmpty {
                throw VideoQualityError.qualityBelowStandards(issues: criticalIssues)
            }
        }
    }
    
    private func getFileSize(at url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
}

// MARK: - Video Security Manager
class VideoSecurityManager {
    private let fileManager = FileManager.default
    
    func createSecureVideoURL() async throws -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videosDirectory = documentsURL.appendingPathComponent("TempVideos", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: videosDirectory.path) {
            try fileManager.createDirectory(at: videosDirectory, withIntermediateDirectories: true, attributes: [
                .protectionKey: FileProtectionType.complete
            ])
        }
        
        // Generate unique filename
        let filename = "\(UUID().uuidString).mov"
        let videoURL = videosDirectory.appendingPathComponent(filename)
        
        return videoURL
    }
    
    func validateFileAccess(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw VideoSecurityError.fileNotFound
        }
        
        guard fileManager.isReadableFile(atPath: url.path) else {
            throw VideoSecurityError.fileNotReadable
        }
        
        // Check if file is within allowed directories
        let allowedDirectories = getAllowedDirectories()
        let isInAllowedDirectory = allowedDirectories.contains { allowedDir in
            url.path.hasPrefix(allowedDir.path)
        }
        
        guard isInAllowedDirectory else {
            throw VideoSecurityError.fileOutsideAllowedDirectory
        }
    }
    
    private func getAllowedDirectories() -> [URL] {
        var directories: [URL] = []
        
        // Documents directory
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            directories.append(documentsURL)
        }
        
        // Temporary directory
        directories.append(fileManager.temporaryDirectory)
        
        return directories
    }
}

// MARK: - Supporting Data Models
struct VideoQualityReport {
    let duration: TimeInterval
    let resolution: CGSize
    let frameRate: Float
    let fileSize: Int64
    let isReadable: Bool
    
    var qualityScore: Double {
        var score = 1.0
        
        // Duration score (optimal range: 10-60 seconds)
        if duration < 10 {
            score *= 0.8
        } else if duration > 60 {
            score *= 0.9
        }
        
        // Resolution score
        let resolutionScore = min(resolution.width / 1920.0, 1.0) * min(resolution.height / 1080.0, 1.0)
        score *= Double(resolutionScore)
        
        // Frame rate score (optimal: 30fps)
        let frameRateScore = min(Double(frameRate) / 30.0, 1.0)
        score *= frameRateScore
        
        return max(score, 0.0)
    }
    
    var isHighQuality: Bool {
        return qualityScore >= 0.8
    }
}

enum VideoQualityIssue {
    case durationTooShort(actual: TimeInterval, required: TimeInterval)
    case durationTooLong(actual: TimeInterval, maximum: TimeInterval)
    case resolutionTooLow(actual: CGSize, minimum: CGSize)
    case frameRateTooLow(actual: Float, minimum: Float)
    case fileSizeTooLarge(actual: Int64, maximum: Int64)
    
    var isCritical: Bool {
        switch self {
        case .durationTooShort, .resolutionTooLow, .frameRateTooLow:
            return true
        case .durationTooLong, .fileSizeTooLarge:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .durationTooShort(let actual, let required):
            return "Video too short: \(String(format: "%.1f", actual))s (minimum: \(String(format: "%.1f", required))s)"
        case .durationTooLong(let actual, let maximum):
            return "Video too long: \(String(format: "%.1f", actual))s (maximum: \(String(format: "%.1f", maximum))s)"
        case .resolutionTooLow(let actual, let minimum):
            return "Resolution too low: \(Int(actual.width))x\(Int(actual.height)) (minimum: \(Int(minimum.width))x\(Int(minimum.height)))"
        case .frameRateTooLow(let actual, let minimum):
            return "Frame rate too low: \(String(format: "%.1f", actual))fps (minimum: \(String(format: "%.1f", minimum))fps)"
        case .fileSizeTooLarge(let actual, let maximum):
            return "File size too large: \(ByteCountFormatter.string(fromByteCount: actual, countStyle: .file)) (maximum: \(ByteCountFormatter.string(fromByteCount: maximum, countStyle: .file)))"
        }
    }
}

enum VideoQualityError: LocalizedError {
    case fileNotReadable
    case noVideoTrack
    case qualityBelowStandards(issues: [VideoQualityIssue])
    
    var errorDescription: String? {
        switch self {
        case .fileNotReadable:
            return "Video file is not readable or corrupted."
        case .noVideoTrack:
            return "No video track found in the file."
        case .qualityBelowStandards(let issues):
            let issueDescriptions = issues.map { $0.description }.joined(separator: "\n")
            return "Video quality is below standards:\n\(issueDescriptions)"
        }
    }
}

enum VideoSecurityError: LocalizedError {
    case fileNotFound
    case fileNotReadable
    case fileOutsideAllowedDirectory
    case unauthorizedAccess
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Video file not found."
        case .fileNotReadable:
            return "Video file is not readable."
        case .fileOutsideAllowedDirectory:
            return "Video file is outside allowed directories."
        case .unauthorizedAccess:
            return "Unauthorized access to video file."
        }
    }
}
