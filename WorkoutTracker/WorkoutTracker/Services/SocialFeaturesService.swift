import Foundation
import CloudKit
import Combine

@MainActor
class SocialFeaturesService: ObservableObject {
    static let shared = SocialFeaturesService()
    
    private let cloudKitService = CloudKitService.shared
    private let authService = UserAuthenticationService.shared
    
    @Published var userFollowing: Set<String> = []
    @Published var userFollowers: Set<String> = []
    @Published var activityFeed: [SocialActivity] = []
    @Published var isLoadingFeed = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        authService.$currentUser
            .sink { [weak self] user in
                if user != nil {
                    Task {
                        await self?.loadUserSocialData()
                    }
                } else {
                    self?.clearSocialData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Following System
    
    func isFollowing(_ userID: String) -> Bool {
        return userFollowing.contains(userID)
    }
    
    func followUser(_ targetUser: SocialUser) async throws {
        guard let currentUser = authService.currentUser else {
            throw SocialError.notAuthenticated
        }
        
        // Create follow record
        let followRecordID = cloudKitService.createRecordID(for: .userFollow, identifier: "\(currentUser.cloudKitUserID)_\(targetUser.cloudKitUserID)")
        let followRecord = CKRecord(recordType: CloudKitService.RecordType.userFollow.rawValue, recordID: followRecordID)
        
        followRecord["followerID"] = currentUser.cloudKitUserID
        followRecord["followingID"] = targetUser.cloudKitUserID
        followRecord["followDate"] = Date()
        followRecord["isActive"] = true
        
        // Save follow record
        _ = try await cloudKitService.save(record: followRecord, to: .public)
        
        // Update follower/following counts
        try await updateFollowCounts(followerID: currentUser.cloudKitUserID, followingID: targetUser.cloudKitUserID, isFollowing: true)
        
        // Update local state
        DispatchQueue.main.async {
            self.userFollowing.insert(targetUser.cloudKitUserID)
        }
        
        // Create activity record
        try await createActivity(
            type: .follow,
            userID: currentUser.cloudKitUserID,
            targetUserID: targetUser.cloudKitUserID,
            content: "\(currentUser.displayName) started following \(targetUser.displayName)"
        )
    }
    
    func unfollowUser(_ targetUser: SocialUser) async throws {
        guard let currentUser = authService.currentUser else {
            throw SocialError.notAuthenticated
        }
        
        // Find and delete follow record
        let query = CKQuery(
            recordType: CloudKitService.RecordType.userFollow.rawValue,
            predicate: NSPredicate(format: "followerID == %@ AND followingID == %@", currentUser.cloudKitUserID, targetUser.cloudKitUserID)
        )
        
        let records = try await cloudKitService.query(with: query, in: .public)
        for record in records {
            try await cloudKitService.delete(recordID: record.recordID, from: .public)
        }
        
        // Update follower/following counts
        try await updateFollowCounts(followerID: currentUser.cloudKitUserID, followingID: targetUser.cloudKitUserID, isFollowing: false)
        
        // Update local state
        DispatchQueue.main.async {
            self.userFollowing.remove(targetUser.cloudKitUserID)
        }
    }
    
    private func updateFollowCounts(followerID: String, followingID: String, isFollowing: Bool) async throws {
        // Update follower's following count
        try await updateUserCount(userID: followerID, field: "followingCount", increment: isFollowing)
        
        // Update following user's follower count
        try await updateUserCount(userID: followingID, field: "followersCount", increment: isFollowing)
    }
    
    private func updateUserCount(userID: String, field: String, increment: Bool) async throws {
        let query = CKQuery(
            recordType: CloudKitService.RecordType.userProfile.rawValue,
            predicate: NSPredicate(format: "cloudKitUserID == %@", userID)
        )
        
        let records = try await cloudKitService.query(with: query, in: .public)
        guard let userRecord = records.first else { return }
        
        let currentCount = userRecord[field] as? Int ?? 0
        userRecord[field] = increment ? currentCount + 1 : max(0, currentCount - 1)
        userRecord["lastUpdated"] = Date()
        
        _ = try await cloudKitService.save(record: userRecord, to: .public)
    }
    
    // MARK: - Workout Sharing
    
    func shareWorkout(_ workoutSession: WorkoutSession, caption: String = "", isPublic: Bool = true) async throws {
        guard let currentUser = authService.currentUser else {
            throw SocialError.notAuthenticated
        }
        
        // Create shared workout record
        let sharedWorkoutID = cloudKitService.createRecordID(for: .sharedWorkout, identifier: UUID().uuidString)
        let sharedRecord = CKRecord(recordType: CloudKitService.RecordType.sharedWorkout.rawValue, recordID: sharedWorkoutID)
        
        sharedRecord["userID"] = currentUser.cloudKitUserID
        sharedRecord["userName"] = currentUser.displayName
        sharedRecord["workoutName"] = workoutSession.name
        sharedRecord["workoutDate"] = workoutSession.date
        sharedRecord["duration"] = workoutSession.duration
        sharedRecord["caption"] = caption
        sharedRecord["isPublic"] = isPublic
        sharedRecord["shareDate"] = Date()
        sharedRecord["likesCount"] = 0
        sharedRecord["commentsCount"] = 0
        
        // Convert workout exercises to shareable format
        if let exercises = workoutSession.exercises?.allObjects as? [WorkoutExercise] {
            let exerciseData = try JSONEncoder().encode(exercises.map { exercise in
                SharedExerciseData(
                    name: exercise.exercise?.name ?? "Unknown Exercise",
                    sets: exercise.setData.count,
                    totalReps: exercise.setData.reduce(into: 0, { $0 += $1.actualReps }),
                    totalVolume: exercise.setData.reduce(into: 0.0, { $0 += ($1.actualWeight * Double($1.actualReps)) }),
                    maxWeight: exercise.setData.map(\.actualWeight).max() ?? 0
                )
            })
            sharedRecord["exercisesData"] = exerciseData
        }
        
        // Calculate workout statistics
        let totalVolume = calculateWorkoutVolume(workoutSession)
        sharedRecord["totalVolume"] = totalVolume
        sharedRecord["exerciseCount"] = workoutSession.exercises?.count ?? 0
        
        // Save shared workout
        _ = try await cloudKitService.save(record: sharedRecord, to: .public)
        
        // Create activity record
        try await createActivity(
            type: .workoutShare,
            userID: currentUser.cloudKitUserID,
            workoutID: sharedWorkoutID.recordName,
            content: "\(currentUser.displayName) shared a workout: \(workoutSession.name ?? "Workout")"
        )
        
        // Update user's workout count
        try await updateUserCount(userID: currentUser.cloudKitUserID, field: "workoutCount", increment: true)
    }
    
    // MARK: - Likes System
    
    func likeSharedWorkout(_ sharedWorkoutID: String) async throws {
        guard let currentUser = authService.currentUser else {
            throw SocialError.notAuthenticated
        }
        
        // Create like record
        let likeRecordID = cloudKitService.createRecordID(for: .socialLike, identifier: "\(currentUser.cloudKitUserID)_\(sharedWorkoutID)")
        let likeRecord = CKRecord(recordType: CloudKitService.RecordType.socialLike.rawValue, recordID: likeRecordID)
        
        likeRecord["userID"] = currentUser.cloudKitUserID
        likeRecord["sharedWorkoutID"] = sharedWorkoutID
        likeRecord["likeDate"] = Date()
        
        _ = try await cloudKitService.save(record: likeRecord, to: .public)
        
        // Update like count on shared workout
        try await updateSharedWorkoutCount(sharedWorkoutID: sharedWorkoutID, field: "likesCount", increment: true)
    }
    
    func unlikeSharedWorkout(_ sharedWorkoutID: String) async throws {
        guard let currentUser = authService.currentUser else {
            throw SocialError.notAuthenticated
        }
        
        // Find and delete like record
        let query = CKQuery(
            recordType: CloudKitService.RecordType.socialLike.rawValue,
            predicate: NSPredicate(format: "userID == %@ AND sharedWorkoutID == %@", currentUser.cloudKitUserID, sharedWorkoutID)
        )
        
        let records = try await cloudKitService.query(with: query, in: .public)
        for record in records {
            try await cloudKitService.delete(recordID: record.recordID, from: .public)
        }
        
        // Update like count on shared workout
        try await updateSharedWorkoutCount(sharedWorkoutID: sharedWorkoutID, field: "likesCount", increment: false)
    }
    
    // MARK: - Comments System
    
    func commentOnSharedWorkout(_ sharedWorkoutID: String, comment: String) async throws {
        guard let currentUser = authService.currentUser else {
            throw SocialError.notAuthenticated
        }
        
        let commentRecordID = cloudKitService.createRecordID(for: .socialComment, identifier: UUID().uuidString)
        let commentRecord = CKRecord(recordType: CloudKitService.RecordType.socialComment.rawValue, recordID: commentRecordID)
        
        commentRecord["userID"] = currentUser.cloudKitUserID
        commentRecord["userName"] = currentUser.displayName
        commentRecord["sharedWorkoutID"] = sharedWorkoutID
        commentRecord["comment"] = comment
        commentRecord["commentDate"] = Date()
        
        _ = try await cloudKitService.save(record: commentRecord, to: .public)
        
        // Update comment count on shared workout
        try await updateSharedWorkoutCount(sharedWorkoutID: sharedWorkoutID, field: "commentsCount", increment: true)
    }
    
    func getCommentsForSharedWorkout(_ sharedWorkoutID: String) async throws -> [SocialComment] {
        let query = CKQuery(
            recordType: CloudKitService.RecordType.socialComment.rawValue,
            predicate: NSPredicate(format: "sharedWorkoutID == %@", sharedWorkoutID)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "commentDate", ascending: true)]
        
        let records = try await cloudKitService.query(with: query, in: .public)
        return records.map { SocialComment.from(cloudKitRecord: $0) }
    }
    
    private func updateSharedWorkoutCount(sharedWorkoutID: String, field: String, increment: Bool) async throws {
        let recordID = CKRecord.ID(recordName: sharedWorkoutID)
        let record = try await cloudKitService.fetch(recordID: recordID, from: .public)
        
        let currentCount = record[field] as? Int ?? 0
        record[field] = increment ? currentCount + 1 : max(0, currentCount - 1)
        
        _ = try await cloudKitService.save(record: record, to: .public)
    }
    
    // MARK: - Activity Feed
    
    func loadActivityFeed() async throws {
        guard let currentUser = authService.currentUser else {
            throw SocialError.notAuthenticated
        }
        
        DispatchQueue.main.async {
            self.isLoadingFeed = true
        }
        
        // Get activities from users the current user follows
        let followingIDs = Array(userFollowing)
        let query = CKQuery(
            recordType: "SocialActivity",
            predicate: NSPredicate(format: "userID IN %@", followingIDs + [currentUser.cloudKitUserID])
        )
        query.sortDescriptors = [NSSortDescriptor(key: "activityDate", ascending: false)]
        
        let records = try await cloudKitService.query(with: query, in: .public)
        let activities = records.map { SocialActivity.from(cloudKitRecord: $0) }
        
        DispatchQueue.main.async {
            self.activityFeed = activities
            self.isLoadingFeed = false
        }
    }
    
    func getSharedWorkouts(userID: String? = nil, limit: Int = 20) async throws -> [SharedWorkout] {
        var predicate: NSPredicate
        
        if let userID = userID {
            predicate = NSPredicate(format: "userID == %@ AND isPublic == %@", userID, NSNumber(value: true))
        } else {
            predicate = NSPredicate(format: "isPublic == %@", NSNumber(value: true))
        }
        
        let query = CKQuery(recordType: CloudKitService.RecordType.sharedWorkout.rawValue, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "shareDate", ascending: false)]
        
        let records = try await cloudKitService.query(with: query, in: .public)
        return Array(records.map { SharedWorkout.from(cloudKitRecord: $0) }.prefix(limit))
    }
    
    // MARK: - Private Methods
    
    private func loadUserSocialData() async {
        guard let currentUser = authService.currentUser else { return }
        
        do {
            // Load following list
            let followingQuery = CKQuery(
                recordType: CloudKitService.RecordType.userFollow.rawValue,
                predicate: NSPredicate(format: "followerID == %@", currentUser.cloudKitUserID)
            )
            
            let followingRecords = try await cloudKitService.query(with: followingQuery, in: .public)
            let followingIDs = Set(followingRecords.compactMap { $0["followingID"] as? String })
            
            // Load followers list
            let followersQuery = CKQuery(
                recordType: CloudKitService.RecordType.userFollow.rawValue,
                predicate: NSPredicate(format: "followingID == %@", currentUser.cloudKitUserID)
            )
            
            let followersRecords = try await cloudKitService.query(with: followersQuery, in: .public)
            let followerIDs = Set(followersRecords.compactMap { $0["followerID"] as? String })
            
            DispatchQueue.main.async {
                self.userFollowing = followingIDs
                self.userFollowers = followerIDs
            }
            
            // Load activity feed
            try await loadActivityFeed()
            
        } catch {
            print("Error loading social data: \(error)")
        }
    }
    
    private func clearSocialData() {
        userFollowing.removeAll()
        userFollowers.removeAll()
        activityFeed.removeAll()
    }
    
    private func createActivity(type: SocialActivityType, userID: String, targetUserID: String? = nil, workoutID: String? = nil, content: String) async throws {
        let activityRecordID = cloudKitService.createRecordID(for: .socialComment, identifier: UUID().uuidString) // Reusing comment type for activities
        let activityRecord = CKRecord(recordType: "SocialActivity", recordID: activityRecordID)
        
        activityRecord["type"] = type.rawValue
        activityRecord["userID"] = userID
        activityRecord["targetUserID"] = targetUserID
        activityRecord["workoutID"] = workoutID
        activityRecord["content"] = content
        activityRecord["activityDate"] = Date()
        
        _ = try await cloudKitService.save(record: activityRecord, to: .public)
    }
    
    private func calculateWorkoutVolume(_ workoutSession: WorkoutSession) -> Double {
        guard let exercises = workoutSession.exercises?.allObjects as? [WorkoutExercise] else {
            return 0
        }
        
        return exercises.reduce(0) { total, exercise in
            total + exercise.setData.reduce(0) { setTotal, setData in
                setTotal + (setData.actualWeight * Double(setData.actualReps))
            }
        }
    }
}

// MARK: - Supporting Types

enum SocialError: LocalizedError {
    case notAuthenticated
    case userNotFound
    case alreadyFollowing
    case notFollowing
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be authenticated to perform social actions"
        case .userNotFound:
            return "User not found"
        case .alreadyFollowing:
            return "Already following this user"
        case .notFollowing:
            return "Not following this user"
        }
    }
}

enum SocialActivityType: String, CaseIterable {
    case follow = "follow"
    case workoutShare = "workout_share"
    case like = "like"
    case comment = "comment"
    case achievement = "achievement"
}

struct SocialActivity: Identifiable {
    let id = UUID()
    let type: SocialActivityType
    let userID: String
    let targetUserID: String?
    let workoutID: String?
    let content: String
    let activityDate: Date
    
    static func from(cloudKitRecord record: CKRecord) -> SocialActivity {
        return SocialActivity(
            type: SocialActivityType(rawValue: record["type"] as? String ?? "") ?? .follow,
            userID: record["userID"] as? String ?? "",
            targetUserID: record["targetUserID"] as? String,
            workoutID: record["workoutID"] as? String,
            content: record["content"] as? String ?? "",
            activityDate: record["activityDate"] as? Date ?? Date()
        )
    }
}

struct SocialUser: Identifiable {
    let id: String
    let cloudKitUserID: String
    let displayName: String
    let bio: String
    let fitnessLevel: String
    let profileImageURL: String?
    let isPrivate: Bool
    let followersCount: Int
    let followingCount: Int
    let workoutsSharedCount: Int
    let joinDate: Date
    
    static func from(cloudKitRecord record: CKRecord) -> SocialUser {
        return SocialUser(
            id: record.recordID.recordName,
            cloudKitUserID: record["userID"] as? String ?? "",
            displayName: record["displayName"] as? String ?? "",
            bio: record["bio"] as? String ?? "",
            fitnessLevel: record["fitnessLevel"] as? String ?? "Beginner",
            profileImageURL: record["profileImageURL"] as? String,
            isPrivate: record["isPrivate"] as? Bool ?? false,
            followersCount: record["followersCount"] as? Int ?? 0,
            followingCount: record["followingCount"] as? Int ?? 0,
            workoutsSharedCount: record["workoutsSharedCount"] as? Int ?? 0,
            joinDate: record["joinDate"] as? Date ?? Date()
        )
    }
}

struct SharedWorkout: Identifiable {
    let id = UUID()
    let recordID: String
    let userID: String
    let userName: String
    let workoutName: String
    let workoutDate: Date
    let duration: Int32
    let caption: String
    let shareDate: Date
    let likesCount: Int
    let commentsCount: Int
    let totalVolume: Double
    let exerciseCount: Int
    let exercisesData: [SharedExerciseData]
    
    static func from(cloudKitRecord record: CKRecord) -> SharedWorkout {
        var exercisesData: [SharedExerciseData] = []
        if let data = record["exercisesData"] as? Data {
            exercisesData = (try? JSONDecoder().decode([SharedExerciseData].self, from: data)) ?? []
        }
        
        return SharedWorkout(
            recordID: record.recordID.recordName,
            userID: record["userID"] as? String ?? "",
            userName: record["userName"] as? String ?? "",
            workoutName: record["workoutName"] as? String ?? "",
            workoutDate: record["workoutDate"] as? Date ?? Date(),
            duration: record["duration"] as? Int32 ?? 0,
            caption: record["caption"] as? String ?? "",
            shareDate: record["shareDate"] as? Date ?? Date(),
            likesCount: record["likesCount"] as? Int ?? 0,
            commentsCount: record["commentsCount"] as? Int ?? 0,
            totalVolume: record["totalVolume"] as? Double ?? 0,
            exerciseCount: record["exerciseCount"] as? Int ?? 0,
            exercisesData: exercisesData
        )
    }
}

struct SharedExerciseData: Codable {
    let name: String
    let sets: Int
    let totalReps: Int
    let totalVolume: Double
    let maxWeight: Double
}

struct SocialComment: Identifiable {
    let id = UUID()
    let userID: String
    let userName: String
    let sharedWorkoutID: String
    let comment: String
    let commentDate: Date
    
    static func from(cloudKitRecord record: CKRecord) -> SocialComment {
        return SocialComment(
            userID: record["userID"] as? String ?? "",
            userName: record["userName"] as? String ?? "",
            sharedWorkoutID: record["sharedWorkoutID"] as? String ?? "",
            comment: record["comment"] as? String ?? "",
            commentDate: record["commentDate"] as? Date ?? Date()
        )
    }
}