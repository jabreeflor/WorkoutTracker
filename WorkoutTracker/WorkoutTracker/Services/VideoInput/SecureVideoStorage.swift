import Foundation
import Security
import CryptoKit

// MARK: - Secure Video Storage Protocol
protocol SecureVideoStorageProtocol {
    func securelyStore(videoURL: URL, exerciseType: ExerciseType) async throws -> SecureVideoContainer
    func retrieveVideo(identifier: String) async throws -> URL
    func securelyDelete(identifier: String) async throws
    func enforceRetentionPolicy() async throws
    func getAllStoredVideos() async throws -> [VideoStorageMetadata]
}

// MARK: - Secure Video Storage Implementation
class SecureVideoStorage: SecureVideoStorageProtocol {
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let fileCoordinator = NSFileCoordinator()
    private let cryptographicProvider = CryptographicProvider()
    private let keychain = KeychainManager()
    
    // Storage directories
    private lazy var videosDirectory: URL = {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videosURL = documentsURL.appendingPathComponent("SecureVideos", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: videosURL.path) {
            try? fileManager.createDirectory(at: videosURL, withIntermediateDirectories: true)
        }
        
        return videosURL
    }()
    
    private lazy var metadataDirectory: URL = {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let metadataURL = documentsURL.appendingPathComponent("VideoMetadata", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: metadataURL.path) {
            try? fileManager.createDirectory(at: metadataURL, withIntermediateDirectories: true)
        }
        
        return metadataURL
    }()
    
    // MARK: - Secure Storage
    func securelyStore(videoURL: URL, exerciseType: ExerciseType) async throws -> SecureVideoContainer {
        let identifier = UUID().uuidString
        
        // Create secure file URLs
        let encryptedVideoURL = videosDirectory.appendingPathComponent("\(identifier).enc")
        
        // Encrypt video data
        try await encryptVideoFile(from: videoURL, to: encryptedVideoURL, identifier: identifier)
        
        // Create metadata
        let metadata = try await createMetadata(
            identifier: identifier,
            originalURL: videoURL,
            encryptedURL: encryptedVideoURL,
            exerciseType: exerciseType
        )
        
        // Save metadata
        try await saveMetadata(metadata)
        
        // Set file protection attributes
        try setFileProtection(for: encryptedVideoURL)
        
        return SecureVideoContainer(
            identifier: identifier,
            secureURL: encryptedVideoURL,
            metadata: metadata
        )
    }
    
    // MARK: - Video Retrieval
    func retrieveVideo(identifier: String) async throws -> URL {
        let metadata = try await getMetadata(for: identifier)
        
        // Update last access date
        var updatedMetadata = metadata
        updatedMetadata.lastAccessDate = Date()
        try await saveMetadata(updatedMetadata)
        
        // For now, return the encrypted URL
        // In a full implementation, you might decrypt to a temporary file
        return metadata.encryptedURL
    }
    
    // MARK: - Secure Deletion
    func securelyDelete(identifier: String) async throws {
        let metadata = try await getMetadata(for: identifier)
        
        // Securely delete the encrypted video file
        try await securelyDeleteFile(at: metadata.encryptedURL)
        
        // Delete metadata
        let metadataURL = metadataDirectory.appendingPathComponent("\(identifier).json")
        try await securelyDeleteFile(at: metadataURL)
        
        // Remove encryption key from keychain
        try keychain.deleteEncryptionKey(for: identifier)
    }
    
    // MARK: - Retention Policy Enforcement
    func enforceRetentionPolicy() async throws {
        let expirationDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days
        let allVideos = try await getAllStoredVideos()
        
        for video in allVideos where video.creationDate < expirationDate {
            try await securelyDelete(identifier: video.identifier)
        }
    }
    
    // MARK: - Get All Stored Videos
    func getAllStoredVideos() async throws -> [VideoStorageMetadata] {
        let metadataFiles = try fileManager.contentsOfDirectory(at: metadataDirectory, includingPropertiesForKeys: nil)
        var videos: [VideoStorageMetadata] = []
        
        for fileURL in metadataFiles where fileURL.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: fileURL)
                let metadata = try JSONDecoder().decode(VideoStorageMetadata.self, from: data)
                videos.append(metadata)
            } catch {
                // Log error but continue processing other files
                print("Failed to decode metadata from \(fileURL): \(error)")
            }
        }
        
        return videos.sorted { $0.creationDate > $1.creationDate }
    }
    
    // MARK: - Private Methods
    private func encryptVideoFile(from sourceURL: URL, to destinationURL: URL, identifier: String) async throws {
        // Generate encryption key
        let key = SymmetricKey(size: .bits256)
        
        // Store key in keychain
        try keychain.storeEncryptionKey(key, for: identifier)
        
        // Read source file
        let sourceData = try Data(contentsOf: sourceURL)
        
        // Encrypt data
        let encryptedData = try ChaChaPoly.seal(sourceData, using: key)
        
        // Combine nonce and ciphertext
        var combinedData = Data()
        combinedData.append(encryptedData.nonce.withUnsafeBytes { Data($0) })
        combinedData.append(encryptedData.ciphertext)
        
        // Write encrypted data
        try combinedData.write(to: destinationURL)
    }
    
    private func createMetadata(
        identifier: String,
        originalURL: URL,
        encryptedURL: URL,
        exerciseType: ExerciseType
    ) async throws -> VideoStorageMetadata {
        let originalAttributes = try fileManager.attributesOfItem(atPath: originalURL.path)
        let encryptedAttributes = try fileManager.attributesOfItem(atPath: encryptedURL.path)
        
        let originalSize = originalAttributes[.size] as? Int64 ?? 0
        let encryptedSize = encryptedAttributes[.size] as? Int64 ?? 0
        
        return VideoStorageMetadata(
            identifier: identifier,
            exerciseType: exerciseType,
            originalSize: originalSize,
            encryptedSize: encryptedSize,
            creationDate: Date(),
            lastAccessDate: Date(),
            encryptedURL: encryptedURL
        )
    }
    
    private func saveMetadata(_ metadata: VideoStorageMetadata) async throws {
        let metadataURL = metadataDirectory.appendingPathComponent("\(metadata.identifier).json")
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL)
        try setFileProtection(for: metadataURL)
    }
    
    private func getMetadata(for identifier: String) async throws -> VideoStorageMetadata {
        let metadataURL = metadataDirectory.appendingPathComponent("\(identifier).json")
        
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            throw VideoStorageError.videoNotFound(identifier: identifier)
        }
        
        let data = try Data(contentsOf: metadataURL)
        return try JSONDecoder().decode(VideoStorageMetadata.self, from: data)
    }
    
    private func setFileProtection(for url: URL) throws {
        try fileManager.setAttributes([
            .protectionKey: FileProtectionType.complete
        ], ofItemAtPath: url.path)
    }
    
    private func securelyDeleteFile(at url: URL) async throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        // Overwrite file with random data before deletion (simple secure deletion)
        let fileSize = try fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
        let randomData = Data((0..<fileSize).map { _ in UInt8.random(in: 0...255) })
        
        try randomData.write(to: url)
        try fileManager.removeItem(at: url)
    }
}

// MARK: - Supporting Data Models
struct SecureVideoContainer {
    let identifier: String
    let secureURL: URL
    let metadata: VideoStorageMetadata
}

struct VideoStorageMetadata: Codable {
    let identifier: String
    let exerciseType: ExerciseType
    let originalSize: Int64
    let encryptedSize: Int64
    let creationDate: Date
    var lastAccessDate: Date
    let encryptedURL: URL
}

enum VideoStorageError: LocalizedError {
    case videoNotFound(identifier: String)
    case encryptionFailed
    case decryptionFailed
    case fileSizeUnknown
    case retentionPolicyViolation
    case metadataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .videoNotFound(let identifier):
            return "Video with identifier \(identifier) not found."
        case .encryptionFailed:
            return "Failed to encrypt video data."
        case .decryptionFailed:
            return "Failed to decrypt video data."
        case .fileSizeUnknown:
            return "Unable to determine file size."
        case .retentionPolicyViolation:
            return "Video exceeds retention policy limits."
        case .metadataCorrupted:
            return "Video metadata is corrupted or unreadable."
        }
    }
}

// MARK: - Cryptographic Provider
class CryptographicProvider {
    func encryptFile(at sourceURL: URL, to destinationURL: URL, using key: SymmetricKey) throws {
        let data = try Data(contentsOf: sourceURL)
        let encryptedData = try ChaChaPoly.seal(data, using: key)
        
        var combinedData = Data()
        combinedData.append(encryptedData.nonce.withUnsafeBytes { Data($0) })
        combinedData.append(encryptedData.ciphertext)
        
        try combinedData.write(to: destinationURL)
    }
    
    func decryptFile(at sourceURL: URL, to destinationURL: URL, using key: SymmetricKey) throws {
        let encryptedData = try Data(contentsOf: sourceURL)
        
        let nonceSize = 12 // ChaCha20Poly1305 nonce size
        let tagSize = 16 // ChaCha20Poly1305 tag size
        
        let nonce = try ChaChaPoly.Nonce(data: encryptedData.prefix(nonceSize))
        let tag = encryptedData.suffix(tagSize)
        let ciphertext = encryptedData.dropFirst(nonceSize).dropLast(tagSize)
        
        let sealedBox = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: key)
        
        try decryptedData.write(to: destinationURL)
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    private let service = "com.workouttracker.video.encryption"
    
    func storeEncryptionKey(_ key: SymmetricKey, for identifier: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing key first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    func getEncryptionKey(for identifier: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw KeychainError.retrieveFailed(status)
        }
        
        return SymmetricKey(data: keyData)
    }
    
    func deleteEncryptionKey(for identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store encryption key in keychain: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve encryption key from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete encryption key from keychain: \(status)"
        }
    }
}
