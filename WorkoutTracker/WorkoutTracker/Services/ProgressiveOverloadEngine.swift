import CoreData
import Foundation

class ProgressiveOverloadEngine {
    static let shared = ProgressiveOverloadEngine()
    private let context = CoreDataManager.shared.context
    
    private init() {}
    
    // MARK: - Public Interface
    
    func getRecommendations(
        for exercise: Exercise,
        lastWorkoutData: [SetData]?,
        userPreferences: ProgressionPreferences = .default
    ) -> [SetData] {
        guard let lastData = lastWorkoutData, !lastData.isEmpty else {
            return generateDefaultRecommendations(for: exercise, preferences: userPreferences)
        }
        
        return generateProgressiveRecommendations(
            exercise: exercise,
            lastData: lastData,
            preferences: userPreferences
        )
    }
    
    func analyzePerformance(currentSets: [SetData], previousSets: [SetData]?) -> PerformanceAnalysis {
        return PerformanceAnalysis(
            currentSets: currentSets,
            previousSets: previousSets
        )
    }
    
    func suggestDeload(for exercise: Exercise, recentWorkouts: [WorkoutSession]) -> DeloadRecommendation? {
        let recentPerformance = extractPerformanceHistory(exercise: exercise, workouts: recentWorkouts)
        return analyzeForDeload(performance: recentPerformance)
    }
    
    // MARK: - Recommendation Generation
    
    private func generateDefaultRecommendations(
        for exercise: Exercise,
        preferences: ProgressionPreferences
    ) -> [SetData] {
        let defaultSets = getDefaultSetCount(for: exercise)
        let defaultReps = getDefaultReps(for: exercise)
        let defaultWeight = getDefaultWeight(for: exercise)
        
        return (1...defaultSets).map { setNumber in
            SetData(
                setNumber: setNumber,
                targetReps: defaultReps,
                targetWeight: defaultWeight
            )
        }
    }
    
    private func generateProgressiveRecommendations(
        exercise: Exercise,
        lastData: [SetData],
        preferences: ProgressionPreferences
    ) -> [SetData] {
        var recommendations: [SetData] = []
        
        for (index, lastSet) in lastData.enumerated() {
            let recommendation = generateSetRecommendation(
                setNumber: index + 1,
                lastSet: lastSet,
                exercise: exercise,
                preferences: preferences,
                setPosition: SetPosition.from(index: index, total: lastData.count)
            )
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    private func generateSetRecommendation(
        setNumber: Int,
        lastSet: SetData,
        exercise: Exercise,
        preferences: ProgressionPreferences,
        setPosition: SetPosition
    ) -> SetData {
        let progression = calculateProgression(
            lastSet: lastSet,
            exercise: exercise,
            preferences: preferences,
            setPosition: setPosition
        )
        
        var newSet = SetData(setNumber: setNumber)
        
        switch progression.type {
        case .increaseWeight:
            newSet.targetWeight = lastSet.actualWeight + progression.weightIncrease
            newSet.targetReps = lastSet.targetReps
            
        case .increaseReps:
            newSet.targetWeight = lastSet.actualWeight
            newSet.targetReps = lastSet.targetReps + progression.repIncrease
            
        case .maintain:
            newSet.targetWeight = lastSet.actualWeight
            newSet.targetReps = lastSet.targetReps
            
        case .deload:
            newSet.targetWeight = lastSet.actualWeight * 0.9 // 10% reduction
            newSet.targetReps = lastSet.targetReps
        }
        
        // Set actual values to targets initially
        newSet.actualWeight = newSet.targetWeight
        newSet.actualReps = newSet.targetReps
        
        return newSet
    }
    
    // MARK: - Progression Logic
    
    private func calculateProgression(
        lastSet: SetData,
        exercise: Exercise,
        preferences: ProgressionPreferences,
        setPosition: SetPosition
    ) -> Progression {
        let completionRate = Double(lastSet.actualReps) / Double(lastSet.targetReps)
        let muscleGroup = MuscleGroup.from(exercise.primaryMuscleGroup)
        
        // If user exceeded target reps significantly, increase weight
        if completionRate >= 1.2 && lastSet.actualReps >= lastSet.targetReps + 2 {
            return Progression(
                type: .increaseWeight,
                weightIncrease: getWeightIncrement(for: muscleGroup, preferences: preferences),
                repIncrease: 0
            )
        }
        
        // If user hit target reps exactly or slightly exceeded, try weight increase
        if completionRate >= 1.0 && completionRate < 1.2 {
            return Progression(
                type: .increaseWeight,
                weightIncrease: getWeightIncrement(for: muscleGroup, preferences: preferences),
                repIncrease: 0
            )
        }
        
        // If user was close to target, try rep increase
        if completionRate >= 0.8 && completionRate < 1.0 {
            return Progression(
                type: .increaseReps,
                weightIncrease: 0,
                repIncrease: 1
            )
        }
        
        // If user significantly under-performed, maintain or deload
        if completionRate < 0.8 {
            return Progression(
                type: lastSet.actualReps < lastSet.targetReps - 3 ? .deload : .maintain,
                weightIncrease: 0,
                repIncrease: 0
            )
        }
        
        return Progression(type: .maintain, weightIncrease: 0, repIncrease: 0)
    }
    
    private func getWeightIncrement(for muscleGroup: MuscleGroup, preferences: ProgressionPreferences) -> Double {
        switch muscleGroup {
        case .chest, .back, .legs:
            return preferences.largeIncrement
        case .shoulders, .arms:
            return preferences.smallIncrement
        case .core:
            return preferences.bodyweightIncrement
        }
    }
    
    // MARK: - Performance Analysis
    
    private func extractPerformanceHistory(exercise: Exercise, workouts: [WorkoutSession]) -> [PerformancePoint] {
        return workouts.compactMap { workout in
            guard let workoutExercises = workout.exercises?.allObjects as? [WorkoutExercise] else { return nil }
            
            let exerciseData = workoutExercises.first { $0.exercise == exercise }
            guard let data = exerciseData else { return nil }
            
            let sets = data.setData
            guard !sets.isEmpty else { return nil }
            
            return PerformancePoint(
                date: workout.date ?? Date(),
                totalVolume: sets.totalVolume,
                averageWeight: sets.averageWeight,
                averageReps: sets.averageReps,
                setCount: sets.count
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func analyzeForDeload(performance: [PerformancePoint]) -> DeloadRecommendation? {
        guard performance.count >= 3 else { return nil }
        
        let recent = Array(performance.suffix(3))
        let volumeTrend = calculateVolumeTrend(points: recent)
        
        // Recommend deload if volume has decreased for 3 consecutive workouts
        if volumeTrend < -0.1 { // 10% volume decrease
            return DeloadRecommendation(
                reason: .volumeDecline,
                recommendedReduction: 0.2, // 20% reduction
                duration: 1 // 1 week
            )
        }
        
        return nil
    }
    
    private func calculateVolumeTrend(points: [PerformancePoint]) -> Double {
        guard points.count >= 2 else { return 0 }
        
        let first = points.first!.totalVolume
        let last = points.last!.totalVolume
        
        return (last - first) / first
    }
    
    // MARK: - Helper Methods
    
    private func getDefaultSetCount(for exercise: Exercise) -> Int {
        switch exercise.primaryMuscleGroup?.lowercased() {
        case "core":
            return 4
        case "calves":
            return 4
        default:
            return 3
        }
    }
    
    private func getDefaultReps(for exercise: Exercise) -> Int {
        switch exercise.primaryMuscleGroup?.lowercased() {
        case "core":
            return 15
        case "calves":
            return 15
        default:
            return 10
        }
    }
    
    private func getDefaultWeight(for exercise: Exercise) -> Double {
        switch exercise.equipment?.lowercased() {
        case "bodyweight":
            return 0.0
        default:
            return 45.0 // Empty barbell weight
        }
    }
}

// MARK: - Supporting Types

struct ProgressionPreferences {
    let largeIncrement: Double      // For chest, back, legs
    let smallIncrement: Double      // For shoulders, arms
    let bodyweightIncrement: Double // For bodyweight exercises
    let conservativeMode: Bool      // Slower progression
    
    static let `default` = ProgressionPreferences(
        largeIncrement: 5.0,
        smallIncrement: 2.5,
        bodyweightIncrement: 0.0,
        conservativeMode: false
    )
    
    static let conservative = ProgressionPreferences(
        largeIncrement: 2.5,
        smallIncrement: 1.25,
        bodyweightIncrement: 0.0,
        conservativeMode: true
    )
}

struct Progression {
    let type: ProgressionType
    let weightIncrease: Double
    let repIncrease: Int
}

enum ProgressionType {
    case increaseWeight
    case increaseReps
    case maintain
    case deload
}

enum MuscleGroup {
    case chest, back, legs, shoulders, arms, core
    
    static func from(_ string: String?) -> MuscleGroup {
        guard let string = string?.lowercased() else { return .chest }
        
        switch string {
        case "chest", "upper chest", "lower chest":
            return .chest
        case "back", "upper back", "lower back":
            return .back
        case "quadriceps", "hamstrings", "glutes", "calves":
            return .legs
        case "shoulders", "rear delts":
            return .shoulders
        case "biceps", "triceps", "forearms":
            return .arms
        case "core", "obliques":
            return .core
        default:
            return .chest
        }
    }
}

enum SetPosition {
    case first, middle, last, only
    
    static func from(index: Int, total: Int) -> SetPosition {
        if total == 1 { return .only }
        if index == 0 { return .first }
        if index == total - 1 { return .last }
        return .middle
    }
}

struct PerformancePoint {
    let date: Date
    let totalVolume: Double
    let averageWeight: Double
    let averageReps: Double
    let setCount: Int
}

struct PerformanceAnalysis {
    let volumeChange: Double
    let strengthGain: Double
    let consistencyScore: Double
    let recommendation: String
    
    init(currentSets: [SetData], previousSets: [SetData]?) {
        guard let previous = previousSets else {
            self.volumeChange = 0
            self.strengthGain = 0
            self.consistencyScore = 1.0
            self.recommendation = "First workout - establish baseline"
            return
        }
        
        let currentVolume = currentSets.totalVolume
        let previousVolume = previous.totalVolume
        
        self.volumeChange = previousVolume > 0 ? (currentVolume - previousVolume) / previousVolume : 0
        
        let currentMaxWeight = currentSets.map { $0.actualWeight }.max() ?? 0
        let previousMaxWeight = previous.map { $0.actualWeight }.max() ?? 0
        
        self.strengthGain = previousMaxWeight > 0 ? (currentMaxWeight - previousMaxWeight) / previousMaxWeight : 0
        
        let completedCurrent = currentSets.filter { $0.completed }.count
        let _ = previous.filter { $0.completed }.count
        
        self.consistencyScore = Double(completedCurrent) / Double(max(currentSets.count, 1))
        
        // Generate recommendation
        if volumeChange > 0.1 {
            self.recommendation = "Great progress! Volume increased by \(Int(volumeChange * 100))%"
        } else if volumeChange < -0.1 {
            self.recommendation = "Volume decreased. Consider reducing weight or adding rest."
        } else if strengthGain > 0 {
            self.recommendation = "Good strength improvement! Keep progressing gradually."
        } else {
            self.recommendation = "Maintaining current level. Focus on form and consistency."
        }
    }
}

struct DeloadRecommendation {
    let reason: DeloadReason
    let recommendedReduction: Double // Percentage (0.2 = 20%)
    let duration: Int // Weeks
}

enum DeloadReason {
    case volumeDecline
    case strengthPlateau
    case formBreakdown
    case fatigue
}