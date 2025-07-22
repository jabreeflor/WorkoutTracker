import Foundation
import CoreData
import SwiftUI

@MainActor
class ExerciseInsightsService: ObservableObject {
    private let predictionService = WorkoutPerformancePrediction.shared
    
    // MARK: - Exercise Performance Analysis
    
    func getTopPerformingExercises(
        exercises: [Exercise],
        timeframe: TimeFrame,
        context: NSManagedObjectContext
    ) -> [ExercisePerformance] {
        let cutoffDate = timeframe.cutoffDate
        
        return exercises.compactMap { exercise in
            guard let workoutExercises = exercise.workoutExercises?.allObjects as? [WorkoutExercise] else {
                return nil
            }
            
            let recentWorkouts = workoutExercises.filter { workoutExercise in
                guard let session = workoutExercise.workoutSession,
                      let date = session.date else { return false }
                return date >= cutoffDate
            }
            
            guard !recentWorkouts.isEmpty else { return nil }
            
            let totalVolume = recentWorkouts.reduce(0.0) { $0 + $1.totalVolume }
            let averageVolume = totalVolume / Double(recentWorkouts.count)
            let workoutCount = recentWorkouts.count
            
            // Calculate progression rate
            let sortedWorkouts = recentWorkouts.sorted { 
                ($0.workoutSession?.date ?? Date.distantPast) < ($1.workoutSession?.date ?? Date.distantPast)
            }
            
            let progressionRate = calculateProgressionRate(workouts: sortedWorkouts)
            let consistencyScore = calculateConsistencyScore(workouts: sortedWorkouts, timeframe: timeframe)
            
            return ExercisePerformance(
                exercise: exercise,
                averageVolume: averageVolume,
                totalWorkouts: workoutCount,
                progressionRate: progressionRate,
                consistencyScore: consistencyScore,
                lastWorkoutDate: sortedWorkouts.last?.workoutSession?.date
            )
        }
        .sorted { $0.overallScore > $1.overallScore }
    }
    
    // MARK: - Exercise Insights Generation
    
    func generateExerciseInsights(
        for exercise: Exercise,
        timeframe: TimeFrame,
        context: NSManagedObjectContext
    ) async -> ExerciseInsights {
        let cutoffDate = timeframe.cutoffDate
        
        guard let workoutExercises = exercise.workoutExercises?.allObjects as? [WorkoutExercise] else {
            return ExerciseInsights.empty(for: exercise)
        }
        
        let recentWorkouts = workoutExercises
            .filter { 
                guard let date = $0.workoutSession?.date else { return false }
                return date >= cutoffDate
            }
            .sorted { 
                ($0.workoutSession?.date ?? Date.distantPast) < ($1.workoutSession?.date ?? Date.distantPast)
            }
        
        guard !recentWorkouts.isEmpty else {
            return ExerciseInsights.empty(for: exercise)
        }
        
        // Generate predictions for next workout
        let nextWorkoutPrediction = predictionService.predictNextWorkoutPerformance(
            for: exercise,
            targetWeight: getRecommendedNextWeight(from: recentWorkouts),
            targetReps: getRecommendedNextReps(from: recentWorkouts)
        )
        
        // Generate progression timeline
        let currentMaxWeight = recentWorkouts.compactMap { workout in
            workout.setData.map { $0.actualWeight }.max()
        }.max() ?? 0
        
        let targetWeight = currentMaxWeight * 1.1 // 10% increase goal
        let progressionTimeline = predictionService.predictProgressionTimeline(
            for: exercise,
            targetWeight: targetWeight,
            currentWeight: currentMaxWeight
        )
        
        // Analyze strength trends
        let strengthTrends = analyzeStrengthTrends(workouts: recentWorkouts)
        
        // Generate insights and recommendations
        let insights = generateInsightStrings(
            exercise: exercise,
            workouts: recentWorkouts,
            trends: strengthTrends
        )
        
        return ExerciseInsights(
            exercise: exercise,
            nextWorkoutPrediction: nextWorkoutPrediction,
            progressionTimeline: progressionTimeline,
            strengthTrends: strengthTrends,
            insights: insights,
            workoutCount: recentWorkouts.count,
            timeframe: timeframe
        )
    }
    
    // MARK: - Recommendations Generation
    
    func generateRecommendations(
        exercises: [Exercise],
        workoutSessions: [WorkoutSession],
        timeframe: TimeFrame,
        context: NSManagedObjectContext
    ) async -> [ExerciseRecommendation] {
        var recommendations: [ExerciseRecommendation] = []
        let cutoffDate = timeframe.cutoffDate
        
        // Analyze workout frequency
        let recentSessions = workoutSessions.filter { 
            guard let date = $0.date else { return false }
            return date >= cutoffDate
        }
        
        recommendations += analyzeWorkoutFrequency(sessions: recentSessions, timeframe: timeframe)
        recommendations += analyzeMuscleGroupBalance(exercises: exercises, timeframe: timeframe, context: context)
        recommendations += analyzeProgressionOpportunities(exercises: exercises, timeframe: timeframe, context: context)
        recommendations += analyzeVolumeDistribution(exercises: exercises, timeframe: timeframe, context: context)
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Exercise Comparisons
    
    func generateExerciseComparisons(
        exercises: [Exercise],
        timeframe: TimeFrame,
        context: NSManagedObjectContext
    ) -> [ExerciseComparison] {
        guard exercises.count >= 2 else { return [] }
        
        var comparisons: [ExerciseComparison] = []
        let _ = timeframe.cutoffDate
        
        // Compare exercises within same muscle groups
        let groupedExercises = Dictionary(grouping: exercises) { exercise in
            exercise.primaryMuscleGroup ?? "Unknown"
        }
        
        for (muscleGroup, groupExercises) in groupedExercises {
            guard groupExercises.count >= 2 else { continue }
            
            for i in 0..<groupExercises.count {
                for j in (i+1)..<groupExercises.count {
                    let exercise1 = groupExercises[i]
                    let exercise2 = groupExercises[j]
                    
                    if let comparison = compareExercises(
                        exercise1: exercise1,
                        exercise2: exercise2,
                        muscleGroup: muscleGroup,
                        timeframe: timeframe,
                        context: context
                    ) {
                        comparisons.append(comparison)
                    }
                }
            }
        }
        
        return Array(comparisons.prefix(6)) // Limit to 6 comparisons
    }
    
    // MARK: - Helper Methods
    
    private func calculateProgressionRate(workouts: [WorkoutExercise]) -> Double {
        guard workouts.count >= 2 else { return 0.0 }
        
        let weights = workouts.compactMap { workout in
            workout.setData.map { $0.actualWeight }.max()
        }
        
        guard weights.count >= 2 else { return 0.0 }
        
        let firstWeight = weights.first!
        let lastWeight = weights.last!
        
        return firstWeight > 0 ? (lastWeight - firstWeight) / firstWeight : 0.0
    }
    
    private func calculateConsistencyScore(workouts: [WorkoutExercise], timeframe: TimeFrame) -> Double {
        let expectedWorkouts = timeframe.expectedWorkoutCount
        let actualWorkouts = workouts.count
        
        return min(1.0, Double(actualWorkouts) / Double(expectedWorkouts))
    }
    
    private func getRecommendedNextWeight(from workouts: [WorkoutExercise]) -> Double {
        guard let lastWorkout = workouts.last else { return 45.0 }
        
        let maxWeight = lastWorkout.setData.map { $0.actualWeight }.max() ?? 45.0
        return maxWeight + 2.5 // Conservative 2.5lb increase
    }
    
    private func getRecommendedNextReps(from workouts: [WorkoutExercise]) -> Int {
        guard let lastWorkout = workouts.last else { return 8 }
        
        let avgReps = lastWorkout.setData.map { $0.actualReps }.reduce(0, +) / lastWorkout.setData.count
        return max(6, min(12, avgReps)) // Keep in 6-12 rep range
    }
    
    private func analyzeStrengthTrends(workouts: [WorkoutExercise]) -> StrengthTrends {
        guard workouts.count >= 3 else {
            return StrengthTrends(
                volumeTrend: .stable,
                strengthTrend: .stable,
                enduranceTrend: .stable,
                trendStrength: 0.0
            )
        }
        
        let volumes = workouts.map { $0.totalVolume }
        let maxWeights = workouts.compactMap { workout in
            workout.setData.map { $0.actualWeight }.max()
        }
        let avgReps = workouts.map { workout in
            let totalReps = workout.setData.map { $0.actualReps }.reduce(0, +)
            return Double(totalReps) / Double(workout.setData.count)
        }
        
        let volumeTrend = calculateTrend(values: volumes)
        let strengthTrend = calculateTrend(values: maxWeights)
        let enduranceTrend = calculateTrend(values: avgReps)
        
        let trendStrength = abs(volumeTrend.value) + abs(strengthTrend.value) + abs(enduranceTrend.value)
        
        return StrengthTrends(
            volumeTrend: volumeTrend.direction,
            strengthTrend: strengthTrend.direction,
            enduranceTrend: enduranceTrend.direction,
            trendStrength: trendStrength / 3.0
        )
    }
    
    private func calculateTrend(values: [Double]) -> (direction: TrendDirection, value: Double) {
        guard values.count >= 3 else { return (.stable, 0.0) }
        
        let first = values.prefix(values.count / 2).reduce(0, +) / Double(values.count / 2)
        let last = values.suffix(values.count / 2).reduce(0, +) / Double(values.count / 2)
        
        let change = first > 0 ? (last - first) / first : 0.0
        
        if change > 0.05 {
            return (.improving, change)
        } else if change < -0.05 {
            return (.declining, abs(change))
        } else {
            return (.stable, abs(change))
        }
    }
    
    private func generateInsightStrings(
        exercise: Exercise,
        workouts: [WorkoutExercise],
        trends: StrengthTrends
    ) -> [String] {
        var insights: [String] = []
        
        // Volume insights
        switch trends.volumeTrend {
        case .improving:
            insights.append("Your training volume is increasing steadily - great progress!")
        case .declining:
            insights.append("Training volume has decreased recently - consider increasing workout frequency")
        case .stable:
            insights.append("Training volume is consistent - good foundation for progression")
        }
        
        // Strength insights
        switch trends.strengthTrend {
        case .improving:
            insights.append("You're getting stronger! Keep up the progressive overload")
        case .declining:
            insights.append("Strength has plateaued - try varying rep ranges or intensity")
        case .stable:
            insights.append("Strength is maintaining - consider a deload or technique focus")
        }
        
        // Workout frequency insight
        if workouts.count >= 8 {
            insights.append("Excellent workout consistency for this exercise")
        } else if workouts.count >= 4 {
            insights.append("Good workout frequency - aim for more consistency")
        } else {
            insights.append("Consider training this exercise more frequently for better results")
        }
        
        return insights
    }
    
    // MARK: - Recommendation Analysis Methods
    
    private func analyzeWorkoutFrequency(
        sessions: [WorkoutSession],
        timeframe: TimeFrame
    ) -> [ExerciseRecommendation] {
        let expectedSessions = timeframe.expectedWorkoutCount
        let actualSessions = sessions.count
        
        if actualSessions < expectedSessions * 2 / 3 {
            return [ExerciseRecommendation(
                id: UUID(),
                type: .frequency,
                title: "Increase Workout Frequency",
                description: "You've completed \(actualSessions) workouts in the last \(timeframe.displayName.lowercased()). Aim for \(expectedSessions) for better results.",
                actionText: "Schedule more workouts",
                priority: .high,
                exerciseName: nil
            )]
        }
        
        return []
    }
    
    private func analyzeMuscleGroupBalance(
        exercises: [Exercise],
        timeframe: TimeFrame,
        context: NSManagedObjectContext
    ) -> [ExerciseRecommendation] {
        var recommendations: [ExerciseRecommendation] = []
        let cutoffDate = timeframe.cutoffDate
        
        // Count workouts per muscle group
        var muscleGroupCounts: [String: Int] = [:]
        
        for exercise in exercises {
            guard let muscleGroup = exercise.primaryMuscleGroup,
                  let workoutExercises = exercise.workoutExercises?.allObjects as? [WorkoutExercise] else {
                continue
            }
            
            let recentCount = workoutExercises.filter { workoutExercise in
                guard let date = workoutExercise.workoutSession?.date else { return false }
                return date >= cutoffDate
            }.count
            
            muscleGroupCounts[muscleGroup, default: 0] += recentCount
        }
        
        // Find imbalances
        let totalWorkouts = muscleGroupCounts.values.reduce(0, +)
        guard totalWorkouts > 0 else { return [] }
        
        for (muscleGroup, count) in muscleGroupCounts {
            let percentage = Double(count) / Double(totalWorkouts)
            
            if percentage < 0.1 && count < 3 { // Less than 10% and fewer than 3 workouts
                recommendations.append(ExerciseRecommendation(
                    id: UUID(),
                    type: .balance,
                    title: "Train \(muscleGroup) More",
                    description: "Your \(muscleGroup.lowercased()) training is lagging behind other muscle groups.",
                    actionText: "Add \(muscleGroup.lowercased()) exercises",
                    priority: .medium,
                    exerciseName: nil
                ))
            }
        }
        
        return recommendations
    }
    
    private func analyzeProgressionOpportunities(
        exercises: [Exercise],
        timeframe: TimeFrame,
        context: NSManagedObjectContext
    ) -> [ExerciseRecommendation] {
        var recommendations: [ExerciseRecommendation] = []
        let cutoffDate = timeframe.cutoffDate
        
        for exercise in exercises {
            guard let workoutExercises = exercise.workoutExercises?.allObjects as? [WorkoutExercise] else {
                continue
            }
            
            let recentWorkouts = workoutExercises.filter { workoutExercise in
                guard let date = workoutExercise.workoutSession?.date else { return false }
                return date >= cutoffDate
            }.sorted { 
                ($0.workoutSession?.date ?? Date.distantPast) < ($1.workoutSession?.date ?? Date.distantPast)
            }
            
            guard recentWorkouts.count >= 3 else { continue }
            
            // Check for stagnation (no weight increase in last 3 workouts)
            let lastThreeWeights = recentWorkouts.suffix(3).compactMap { workout in
                workout.setData.map { $0.actualWeight }.max()
            }
            
            if lastThreeWeights.count == 3 && lastThreeWeights.allSatisfy({ $0 == lastThreeWeights.first }) {
                recommendations.append(ExerciseRecommendation(
                    id: UUID(),
                    type: .progression,
                    title: "Progress \(exercise.name ?? "Exercise")",
                    description: "No weight increase in last 3 workouts. Time to challenge yourself!",
                    actionText: "Increase weight or reps",
                    priority: .medium,
                    exerciseName: exercise.name
                ))
            }
        }
        
        return recommendations
    }
    
    private func analyzeVolumeDistribution(
        exercises: [Exercise],
        timeframe: TimeFrame,
        context: NSManagedObjectContext
    ) -> [ExerciseRecommendation] {
        // Implementation for volume distribution analysis
        // This could analyze if certain exercises are getting too much or too little volume
        return []
    }
    
    private func compareExercises(
        exercise1: Exercise,
        exercise2: Exercise,
        muscleGroup: String,
        timeframe: TimeFrame,
        context: NSManagedObjectContext
    ) -> ExerciseComparison? {
        let cutoffDate = timeframe.cutoffDate
        
        let performance1 = getExercisePerformanceMetrics(exercise: exercise1, cutoffDate: cutoffDate)
        let performance2 = getExercisePerformanceMetrics(exercise: exercise2, cutoffDate: cutoffDate)
        
        guard performance1.workoutCount > 0 && performance2.workoutCount > 0 else {
            return nil
        }
        
        let comparison = ExerciseComparison(
            id: UUID(),
            exercise1: exercise1,
            exercise2: exercise2,
            muscleGroup: muscleGroup,
            volume1: performance1.totalVolume,
            volume2: performance2.totalVolume,
            progression1: performance1.progressionRate,
            progression2: performance2.progressionRate,
            frequency1: performance1.workoutCount,
            frequency2: performance2.workoutCount
        )
        
        return comparison
    }
    
    private func getExercisePerformanceMetrics(exercise: Exercise, cutoffDate: Date) -> (totalVolume: Double, progressionRate: Double, workoutCount: Int) {
        guard let workoutExercises = exercise.workoutExercises?.allObjects as? [WorkoutExercise] else {
            return (0, 0, 0)
        }
        
        let recentWorkouts = workoutExercises.filter { workoutExercise in
            guard let date = workoutExercise.workoutSession?.date else { return false }
            return date >= cutoffDate
        }
        
        let totalVolume = recentWorkouts.reduce(0.0) { $0 + $1.totalVolume }
        let progressionRate = calculateProgressionRate(workouts: recentWorkouts)
        
        return (totalVolume, progressionRate, recentWorkouts.count)
    }
}

// MARK: - Supporting Types

struct ExercisePerformance {
    let exercise: Exercise
    let averageVolume: Double
    let totalWorkouts: Int
    let progressionRate: Double
    let consistencyScore: Double
    let lastWorkoutDate: Date?
    
    var overallScore: Double {
        return (progressionRate * 0.4) + (consistencyScore * 0.3) + (min(1.0, averageVolume / 1000.0) * 0.3)
    }
}

struct ExerciseInsights {
    let exercise: Exercise
    let nextWorkoutPrediction: PerformancePrediction?
    let progressionTimeline: ProgressionTimeline?
    let strengthTrends: StrengthTrends
    let insights: [String]
    let workoutCount: Int
    let timeframe: TimeFrame
    
    static func empty(for exercise: Exercise) -> ExerciseInsights {
        return ExerciseInsights(
            exercise: exercise,
            nextWorkoutPrediction: nil,
            progressionTimeline: nil,
            strengthTrends: StrengthTrends(
                volumeTrend: .stable,
                strengthTrend: .stable,
                enduranceTrend: .stable,
                trendStrength: 0.0
            ),
            insights: ["Need more workout data to generate insights"],
            workoutCount: 0,
            timeframe: .month
        )
    }
}

struct StrengthTrends {
    let volumeTrend: TrendDirection
    let strengthTrend: TrendDirection
    let enduranceTrend: TrendDirection
    let trendStrength: Double
}

enum TrendDirection {
    case improving, stable, declining
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

struct ExerciseRecommendation: Identifiable {
    let id: UUID
    let type: RecommendationType
    let title: String
    let description: String
    let actionText: String
    let priority: Priority
    let exerciseName: String?
    
    enum RecommendationType {
        case frequency, balance, progression, volume, recovery
    }
    
    enum Priority {
        case high, medium, low
        
        var rawValue: Int {
            switch self {
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
    }
}

struct ExerciseComparison: Identifiable {
    let id: UUID
    let exercise1: Exercise
    let exercise2: Exercise
    let muscleGroup: String
    let volume1: Double
    let volume2: Double
    let progression1: Double
    let progression2: Double
    let frequency1: Int
    let frequency2: Int
    
    var betterVolumeExercise: Exercise {
        return volume1 > volume2 ? exercise1 : exercise2
    }
    
    var betterProgressionExercise: Exercise {
        return progression1 > progression2 ? exercise1 : exercise2
    }
}

extension TimeFrame {
    var expectedWorkoutCount: Int {
        switch self {
        case .week: return 3
        case .month: return 12
        case .quarter: return 36
        case .year: return 144
        }
    }
}