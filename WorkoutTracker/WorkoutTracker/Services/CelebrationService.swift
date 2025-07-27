import SwiftUI

/// Service for managing celebration effects throughout the app
class CelebrationService: ObservableObject {
    static let shared = CelebrationService()
    
    private init() {}
    
    @Published var activeCelebrations: [UUID: CelebrationState] = [:]
    
    struct CelebrationState {
        let type: CelebrationType
        let startTime: Date
        let duration: TimeInterval
        
        var isActive: Bool {
            Date().timeIntervalSince(startTime) < duration
        }
    }
    
    enum CelebrationType {
        case setCompletion
        case exerciseCompletion
        case workoutCompletion
        case personalRecord
        case timerCompletion
        case milestone(Int)
    }
    
    // MARK: - Celebration Triggers
    
    func celebrateSetCompletion(for id: UUID) {
        triggerCelebration(id: id, type: .setCompletion, duration: 1.0)
    }
    
    func celebrateExerciseCompletion(for id: UUID) {
        triggerCelebration(id: id, type: .exerciseCompletion, duration: 1.5)
    }
    
    func celebrateWorkoutCompletion(for id: UUID) {
        triggerCelebration(id: id, type: .workoutCompletion, duration: 2.0)
    }
    
    func celebratePersonalRecord(for id: UUID) {
        triggerCelebration(id: id, type: .personalRecord, duration: 2.5)
    }
    
    func celebrateTimerCompletion(for id: UUID) {
        triggerCelebration(id: id, type: .timerCompletion, duration: 1.0)
    }
    
    func celebrateMilestone(for id: UUID, milestone: Int) {
        triggerCelebration(id: id, type: .milestone(milestone), duration: 1.8)
    }
    
    // MARK: - Private Methods
    
    private func triggerCelebration(id: UUID, type: CelebrationType, duration: TimeInterval) {
        let celebration = CelebrationState(
            type: type,
            startTime: Date(),
            duration: duration
        )
        
        activeCelebrations[id] = celebration
        
        // Provide haptic feedback
        HapticService.shared.provideFeedback(for: .success)
        
        // Auto-cleanup after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.activeCelebrations.removeValue(forKey: id)
        }
    }
    
    // MARK: - Query Methods
    
    func isCelebrating(id: UUID) -> Bool {
        guard let celebration = activeCelebrations[id] else { return false }
        return celebration.isActive
    }
    
    func getCelebrationType(for id: UUID) -> CelebrationType? {
        return activeCelebrations[id]?.type
    }
    
    func cleanup() {
        let now = Date()
        activeCelebrations = activeCelebrations.filter { _, celebration in
            celebration.isActive
        }
    }
    
    // MARK: - Performance Optimization Methods
    
    func reduceComplexity() {
        // Reduce celebration duration for better performance
        let currentTime = Date()
        for (id, celebration) in activeCelebrations {
            if currentTime.timeIntervalSince(celebration.startTime) > 0.5 {
                activeCelebrations.removeValue(forKey: id)
            }
        }
    }
    
    func cleanupOldCelebrations() {
        cleanup() // Use existing cleanup method
    }
}