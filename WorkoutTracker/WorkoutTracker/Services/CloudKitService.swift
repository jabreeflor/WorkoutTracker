import CloudKit
import Foundation
import Combine

@MainActor
final class CloudKitService: ObservableObject, @unchecked Sendable {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    
    @Published var isAvailable = false
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Record Types
    enum RecordType: String, CaseIterable {
        case workoutSession = "WorkoutSession"
        case workoutTemplate = "WorkoutTemplate"
        case exercise = "Exercise"
        case userProfile = "UserProfile"
        case userPreferences = "UserPreferences"
        case sharedWorkout = "SharedWorkout"
        case socialComment = "SocialComment"
        case socialLike = "SocialLike"
        case userFollow = "UserFollow"
    }
    
    // MARK: - Sync Status
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    private init() {
        self.container = CKContainer.default()
        self.publicDatabase = container.publicCloudDatabase
        self.privateDatabase = container.privateCloudDatabase
        
        checkAccountStatus()
        setupNotifications()
    }
    
    // MARK: - Account Management
    
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.accountStatus = status
                self?.isAvailable = status == .available
                
                if let error = error {
                    print("CloudKit account status error: \(error)")
                }
            }
        }
    }
    
    func requestPermissions() {
        // Note: .userDiscoverability is deprecated in iOS 17.0
        // This method is kept for backwards compatibility but should be updated
        print("Permission request: User discoverability permissions are no longer supported in iOS 17+")
        checkAccountStatus()
    }
    
    // MARK: - Database Operations
    
    func save(record: CKRecord, to database: DatabaseType = .private) async throws -> CKRecord {
        let targetDatabase = database == .private ? privateDatabase : publicDatabase
        return try await targetDatabase.save(record)
    }
    
    func fetch(recordID: CKRecord.ID, from database: DatabaseType = .private) async throws -> CKRecord {
        let targetDatabase = database == .private ? privateDatabase : publicDatabase
        return try await targetDatabase.record(for: recordID)
    }
    
    func query(with query: CKQuery, in database: DatabaseType = .private) async throws -> [CKRecord] {
        let targetDatabase = database == .private ? privateDatabase : publicDatabase
        let (matchResults, _) = try await targetDatabase.records(matching: query)
        
        var records: [CKRecord] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                records.append(record)
            case .failure(let error):
                print("Record fetch error: \(error)")
            }
        }
        return records
    }
    
    func delete(recordID: CKRecord.ID, from database: DatabaseType = .private) async throws {
        let targetDatabase = database == .private ? privateDatabase : publicDatabase
        _ = try await targetDatabase.deleteRecord(withID: recordID)
    }
    
    // MARK: - Batch Operations
    
    func batchSave(records: [CKRecord], to database: DatabaseType = .private) async throws -> [CKRecord] {
        let targetDatabase = database == .private ? privateDatabase : publicDatabase
        let operation = CKModifyRecordsOperation(recordsToSave: records)
        operation.configuration.isLongLived = true
        operation.configuration.timeoutIntervalForRequest = 60
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success():
                    continuation.resume(returning: records)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            targetDatabase.add(operation)
        }
    }
    
    // MARK: - Sync Operations
    
    func performFullSync() async {
        guard isAvailable else { return }
        
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        do {
            // Sync user preferences first
            try await syncUserPreferences()
            
            // Sync workout sessions
            try await syncWorkoutSessions()
            
            // Sync workout templates
            try await syncWorkoutTemplates()
            
            // Update last sync date
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                self.syncStatus = .success
            }
            
        } catch {
            DispatchQueue.main.async {
                self.syncStatus = .failed(error)
            }
        }
    }
    
    private func syncUserPreferences() async throws {
        // Implementation for syncing user preferences
        print("Syncing user preferences...")
    }
    
    private func syncWorkoutSessions() async throws {
        // Implementation for syncing workout sessions
        print("Syncing workout sessions...")
    }
    
    private func syncWorkoutTemplates() async throws {
        // Implementation for syncing workout templates
        print("Syncing workout templates...")
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accountChanged),
            name: .CKAccountChanged,
            object: nil
        )
    }
    
    @objc private func accountChanged() {
        checkAccountStatus()
    }
    
    // MARK: - Utilities
    
    func createRecordID(for type: RecordType, identifier: String) -> CKRecord.ID {
        return CKRecord.ID(recordName: "\(type.rawValue)_\(identifier)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

enum DatabaseType {
    case `private`
    case `public`
    case shared
}

// MARK: - CloudKit Extensions

extension CKRecord {
    func setValues(from dictionary: [String: Any]) {
        for (key, value) in dictionary {
            self[key] = value as? CKRecordValue
        }
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        for key in allKeys() {
            dict[key] = self[key]
        }
        return dict
    }
}

// MARK: - Error Handling

extension CloudKitService {
    func handleCloudKitError(_ error: Error) -> String {
        guard let ckError = error as? CKError else {
            return error.localizedDescription
        }
        
        switch ckError.code {
        case .accountTemporarilyUnavailable:
            return "iCloud account is temporarily unavailable. Please try again later."
        case .networkFailure, .networkUnavailable:
            return "Network connection is unavailable. Please check your internet connection."
        case .quotaExceeded:
            return "iCloud storage quota exceeded. Please free up space in iCloud."
        case .requestRateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .zoneBusy:
            return "iCloud is busy. Please try again in a moment."
        case .serviceUnavailable:
            return "iCloud service is temporarily unavailable."
        case .notAuthenticated:
            return "Please sign in to iCloud in Settings."
        default:
            return "iCloud sync error: \(ckError.localizedDescription)"
        }
    }
}