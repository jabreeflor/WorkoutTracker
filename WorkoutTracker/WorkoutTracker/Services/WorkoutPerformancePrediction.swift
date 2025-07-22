import Foundation
import CoreML
import CoreData

class WorkoutPerformancePrediction {
    static let shared = WorkoutPerformancePrediction()
    private let context = CoreDataManager.shared.context
    
    private init() {}
    
    // MARK: - Prediction Models
    
    func predictNextWorkoutPerformance(
        for exercise: Exercise,
        targetWeight: Double,
        targetReps: Int,
        daysFromNow: Int = 0
    ) -> PerformancePrediction? {
        guard let historicalData = getHistoricalData(for: exercise) else {
            return nil
        }
        
        let features = prepareFeatures(
            historicalData: historicalData,
            targetWeight: targetWeight,
            targetReps: targetReps,
            daysFromNow: daysFromNow
        )
        
        return generatePrediction(features: features, exercise: exercise)
    }
    
    func predictProgressionTimeline(
        for exercise: Exercise,
        targetWeight: Double,
        currentWeight: Double
    ) -> ProgressionTimeline? {
        guard let historicalData = getHistoricalData(for: exercise),
              historicalData.count >= 3 else {
            return nil
        }
        
        let progressionRate = calculateProgressionRate(historicalData: historicalData)
        let weightDifference = targetWeight - currentWeight
        
        guard progressionRate > 0 else {
            return ProgressionTimeline(
                targetWeight: targetWeight,
                estimatedWeeks: nil,
                confidence: 0.0,
                milestones: [],
                recommendation: "Need more consistent training data to predict progression"
            )
        }
        
        let estimatedWeeks = Int(ceil(weightDifference / progressionRate))
        let milestones = generateMilestones(
            from: currentWeight,
            to: targetWeight,
            progressionRate: progressionRate
        )
        
        let confidence = calculateConfidence(
            historicalData: historicalData,
            progressionRate: progressionRate
        )
        
        return ProgressionTimeline(
            targetWeight: targetWeight,
            estimatedWeeks: estimatedWeeks,
            confidence: confidence,
            milestones: milestones,
            recommendation: generateRecommendation(confidence: confidence, weeks: estimatedWeeks)
        )
    }
    
    func predictOptimalRestTime(
        for exercise: Exercise,
        currentSet: SetData,
        previousSets: [SetData]
    ) -> RestTimePrediction? {
        guard !previousSets.isEmpty else {
            return RestTimePrediction(
                recommendedSeconds: Int(getDefaultRestTime(for: exercise)),
                confidence: 0.5,
                reasoning: "Default rest time for exercise type"
            )
        }
        
        let features = RestFeatures(
            exerciseType: exercise.primaryMuscleGroup ?? "unknown",
            currentWeight: currentSet.targetWeight,
            targetReps: currentSet.targetReps,
            setNumber: currentSet.setNumber,
            previousSetPerformance: calculatePreviousSetPerformance(previousSets),
            fatigueLevel: calculateFatigueLevel(previousSets)
        )
        
        return predictRestTime(features: features)
    }
    
    // MARK: - Data Preparation
    
    private func getHistoricalData(for exercise: Exercise) -> [WorkoutDataPoint]? {
        let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        request.predicate = NSPredicate(format: "exercises.exercise == %@", exercise)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let sessions = try context.fetch(request)
            let dataPoints = sessions.compactMap { session -> WorkoutDataPoint? in
                guard let workoutExercises = session.exercises?.allObjects as? [WorkoutExercise],
                      let exerciseData = workoutExercises.first(where: { $0.exercise == exercise }),
                      let date = session.date else {
                    return nil
                }
                
                let sets = exerciseData.setData
                guard !sets.isEmpty else { return nil }
                
                return WorkoutDataPoint(
                    date: date,
                    maxWeight: sets.map { $0.actualWeight }.max() ?? 0,
                    totalVolume: sets.totalVolume,
                    averageReps: sets.averageReps,
                    setCount: sets.count,
                    completionRate: sets.completionRate,
                    restTimes: sets.compactMap { $0.restTime }
                )
            }
            
            return dataPoints.count >= 2 ? dataPoints : nil
        } catch {
            print("Error fetching historical data: \(error)")
            return nil
        }
    }
    
    private func prepareFeatures(
        historicalData: [WorkoutDataPoint],
        targetWeight: Double,
        targetReps: Int,
        daysFromNow: Int
    ) -> PredictionFeatures {
        let recentData = Array(historicalData.suffix(5))
        
        let avgVolume = recentData.map { $0.totalVolume }.reduce(0, +) / Double(recentData.count)
        let avgWeight = recentData.map { $0.maxWeight }.reduce(0, +) / Double(recentData.count)
        let avgReps = recentData.map { $0.averageReps }.reduce(0, +) / Double(recentData.count)
        let avgCompletion = recentData.map { $0.completionRate }.reduce(0, +) / Double(recentData.count)
        
        let trendMultiplier = calculateTrendMultiplier(historicalData: recentData)
        let daysSinceLastWorkout = daysFromNow == 0 ? 0 : daysFromNow
        
        return PredictionFeatures(
            targetWeight: targetWeight,
            targetReps: targetReps,
            recentAverageVolume: avgVolume,
            recentAverageWeight: avgWeight,
            recentAverageReps: avgReps,
            recentCompletionRate: avgCompletion,
            trendMultiplier: trendMultiplier,
            daysSinceLastWorkout: daysSinceLastWorkout,
            workoutCount: historicalData.count
        )
    }
    
    // MARK: - Prediction Logic
    
    private func generatePrediction(features: PredictionFeatures, exercise: Exercise) -> PerformancePrediction {
        // Try Core ML prediction first
        if let mlPrediction = tryCoreMlPrediction(features: features) {
            return mlPrediction
        }
        
        // Fallback to algorithmic prediction
        return generateAlgorithmicPrediction(features: features, exercise: exercise)
    }
    
    private func tryCoreMlPrediction(features: PredictionFeatures) -> PerformancePrediction? {
        guard CoreMLModelManager.shared.isModelAvailable() else {
            return nil
        }
        
        let mlPrediction = CoreMLModelManager.shared.predictPerformance(
            targetWeight: features.targetWeight,
            targetReps: features.targetReps,
            recentAverageVolume: features.recentAverageVolume,
            recentAverageWeight: features.recentAverageWeight,
            recentCompletionRate: features.recentCompletionRate,
            trendMultiplier: features.trendMultiplier,
            daysSinceLastWorkout: features.daysSinceLastWorkout,
            workoutCount: features.workoutCount
        )
        
        guard let successProbability = mlPrediction else {
            return nil
        }
        
        let predictedReps = Int(round(Double(features.targetReps) * successProbability))
        let confidence = calculatePredictionConfidence(
            workoutCount: features.workoutCount,
            completionRate: features.recentCompletionRate,
            trendStrength: abs(features.trendMultiplier)
        )
        
        return PerformancePrediction(
            predictedReps: predictedReps,
            predictedWeight: features.targetWeight,
            successProbability: successProbability,
            confidence: confidence,
            reasoning: "AI prediction based on personalized model"
        )
    }
    
    private func generateAlgorithmicPrediction(features: PredictionFeatures, exercise: Exercise) -> PerformancePrediction {
        let weightDifficultyFactor = features.targetWeight / features.recentAverageWeight
        let repsDifficultyFactor = Double(features.targetReps) / features.recentAverageReps
        
        let baseProbability = features.recentCompletionRate
        let trendAdjustment = features.trendMultiplier * 0.2
        let weightAdjustment = max(0, 1.0 - (weightDifficultyFactor - 1.0) * 0.5)
        let repsAdjustment = max(0, 1.0 - (repsDifficultyFactor - 1.0) * 0.3)
        
        let restAdjustment = features.daysSinceLastWorkout > 0 ? 
            calculateRestAdjustment(days: features.daysSinceLastWorkout) : 0
        
        let successProbability = min(1.0, max(0.0, 
            baseProbability + trendAdjustment + restAdjustment
        )) * weightAdjustment * repsAdjustment
        
        let predictedReps = Int(round(Double(features.targetReps) * successProbability))
        let predictedWeight = features.targetWeight
        
        let confidence = calculatePredictionConfidence(
            workoutCount: features.workoutCount,
            completionRate: features.recentCompletionRate,
            trendStrength: abs(features.trendMultiplier)
        )
        
        return PerformancePrediction(
            predictedReps: predictedReps,
            predictedWeight: predictedWeight,
            successProbability: successProbability,
            confidence: confidence,
            reasoning: generatePredictionReasoning(
                successProbability: successProbability,
                weightDifficulty: weightDifficultyFactor,
                trend: features.trendMultiplier
            )
        )
    }
    
    private func calculateProgressionRate(historicalData: [WorkoutDataPoint]) -> Double {
        guard historicalData.count >= 3 else { return 0 }
        
        let weights = historicalData.map { $0.maxWeight }
        let timeSpans = historicalData.enumerated().compactMap { (index, point) -> Double? in
            guard index > 0 else { return nil }
            let previousPoint = historicalData[index - 1]
            let daysBetween = Calendar.current.dateComponents([.day], from: previousPoint.date, to: point.date).day ?? 7
            return Double(daysBetween) / 7.0 // Convert to weeks
        }
        
        var totalWeightGain = 0.0
        var totalWeeks = 0.0
        
        for i in 1..<weights.count {
            let weightGain = weights[i] - weights[i-1]
            if weightGain > 0 {
                totalWeightGain += weightGain
                totalWeeks += timeSpans[i-1]
            }
        }
        
        return totalWeeks > 0 ? totalWeightGain / totalWeeks : 0
    }
    
    private func calculateConfidence(
        historicalData: [WorkoutDataPoint],
        progressionRate: Double
    ) -> Double {
        let dataPointsScore = min(1.0, Double(historicalData.count) / 10.0)
        let consistencyScore = calculateConsistencyScore(historicalData: historicalData)
        let progressionScore = progressionRate > 0 ? 1.0 : 0.5
        
        return (dataPointsScore + consistencyScore + progressionScore) / 3.0
    }
    
    private func calculateConsistencyScore(historicalData: [WorkoutDataPoint]) -> Double {
        guard historicalData.count >= 2 else { return 0.5 }
        
        let volumes = historicalData.map { $0.totalVolume }
        let mean = volumes.reduce(0, +) / Double(volumes.count)
        let variance = volumes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(volumes.count)
        let coefficientOfVariation = sqrt(variance) / mean
        
        return max(0.0, 1.0 - coefficientOfVariation)
    }
    
    // MARK: - Helper Methods
    
    private func calculateTrendMultiplier(historicalData: [WorkoutDataPoint]) -> Double {
        guard historicalData.count >= 3 else { return 0 }
        
        let recent = Array(historicalData.suffix(3))
        let volumes = recent.map { $0.totalVolume }
        
        let firstVolume = volumes.first!
        let lastVolume = volumes.last!
        
        return (lastVolume - firstVolume) / firstVolume
    }
    
    private func calculateRestAdjustment(days: Int) -> Double {
        switch days {
        case 0: return 0.0
        case 1: return 0.1
        case 2: return 0.05
        case 3...7: return 0.0
        default: return -0.1
        }
    }
    
    private func calculatePredictionConfidence(
        workoutCount: Int,
        completionRate: Double,
        trendStrength: Double
    ) -> Double {
        let dataScore = min(1.0, Double(workoutCount) / 10.0)
        let consistencyScore = completionRate
        let trendScore = min(1.0, trendStrength * 2.0)
        
        return (dataScore + consistencyScore + trendScore) / 3.0
    }
    
    private func generatePredictionReasoning(
        successProbability: Double,
        weightDifficulty: Double,
        trend: Double
    ) -> String {
        var reasons: [String] = []
        
        if successProbability > 0.8 {
            reasons.append("High success probability based on recent performance")
        } else if successProbability < 0.5 {
            reasons.append("Challenging target based on current progression")
        }
        
        if weightDifficulty > 1.2 {
            reasons.append("Weight increase is above typical progression")
        }
        
        if trend > 0.1 {
            reasons.append("Recent upward trend supports progression")
        } else if trend < -0.1 {
            reasons.append("Recent decline suggests more conservative approach")
        }
        
        return reasons.isEmpty ? "Prediction based on historical performance patterns" : reasons.joined(separator: ". ")
    }
    
    private func generateMilestones(
        from currentWeight: Double,
        to targetWeight: Double,
        progressionRate: Double
    ) -> [ProgressionMilestone] {
        var milestones: [ProgressionMilestone] = []
        let increment = progressionRate
        var weight = currentWeight
        var week = 0
        
        while weight < targetWeight {
            weight += increment
            week += 1
            
            if weight >= targetWeight {
                weight = targetWeight
            }
            
            let milestone = ProgressionMilestone(
                weight: weight,
                estimatedWeek: week,
                confidence: max(0.3, 1.0 - (Double(week) * 0.02))
            )
            milestones.append(milestone)
            
            if weight >= targetWeight { break }
        }
        
        return milestones
    }
    
    private func generateRecommendation(confidence: Double, weeks: Int) -> String {
        if confidence > 0.8 {
            return "High confidence prediction. Stay consistent with current training."
        } else if confidence > 0.6 {
            return "Moderate confidence. Consider tracking form quality and recovery."
        } else if weeks > 52 {
            return "Long-term goal. Break into smaller milestones and reassess regularly."
        } else {
            return "Low confidence. More training data needed for accurate prediction."
        }
    }
    
    // MARK: - Rest Time Prediction
    
    private func predictRestTime(features: RestFeatures) -> RestTimePrediction {
        let baseRestTime = getDefaultRestTime(for: features.exerciseType)
        let fatigueAdjustment = features.fatigueLevel * 30
        let weightAdjustment = (features.currentWeight / 100.0) * 15
        
        let recommendedSeconds = Int(baseRestTime + fatigueAdjustment + weightAdjustment)
        let clampedSeconds = max(60, min(300, recommendedSeconds))
        
        return RestTimePrediction(
            recommendedSeconds: clampedSeconds,
            confidence: 0.7,
            reasoning: "Based on exercise type, fatigue level, and weight"
        )
    }
    
    private func getDefaultRestTime(for exercise: Exercise) -> Double {
        switch exercise.primaryMuscleGroup?.lowercased() {
        case "chest", "back", "legs":
            return 120.0
        case "shoulders", "arms":
            return 90.0
        case "core":
            return 60.0
        default:
            return 120.0
        }
    }
    
    private func getDefaultRestTime(for muscleGroup: String) -> Double {
        switch muscleGroup.lowercased() {
        case "chest", "back", "legs":
            return 120.0
        case "shoulders", "arms":
            return 90.0
        case "core":
            return 60.0
        default:
            return 120.0
        }
    }
    
    private func calculatePreviousSetPerformance(_ sets: [SetData]) -> Double {
        let completedSets = sets.filter { $0.completed }
        guard !completedSets.isEmpty else { return 0.5 }
        
        let performanceScores = completedSets.map { set in
            Double(set.actualReps) / Double(set.targetReps)
        }
        
        return performanceScores.reduce(0, +) / Double(performanceScores.count)
    }
    
    private func calculateFatigueLevel(_ sets: [SetData]) -> Double {
        guard sets.count > 1 else { return 0.0 }
        
        let performances = sets.map { Double($0.actualReps) / Double($0.targetReps) }
        let declineRate = (performances.first! - performances.last!) / performances.first!
        
        return max(0.0, declineRate)
    }
}

// MARK: - Supporting Types

struct WorkoutDataPoint {
    let date: Date
    let maxWeight: Double
    let totalVolume: Double
    let averageReps: Double
    let setCount: Int
    let completionRate: Double
    let restTimes: [Int]
}

struct PredictionFeatures {
    let targetWeight: Double
    let targetReps: Int
    let recentAverageVolume: Double
    let recentAverageWeight: Double
    let recentAverageReps: Double
    let recentCompletionRate: Double
    let trendMultiplier: Double
    let daysSinceLastWorkout: Int
    let workoutCount: Int
}

struct PerformancePrediction {
    let predictedReps: Int
    let predictedWeight: Double
    let successProbability: Double
    let confidence: Double
    let reasoning: String
}

struct ProgressionTimeline {
    let targetWeight: Double
    let estimatedWeeks: Int?
    let confidence: Double
    let milestones: [ProgressionMilestone]
    let recommendation: String
}

struct ProgressionMilestone {
    let weight: Double
    let estimatedWeek: Int
    let confidence: Double
}

struct RestFeatures {
    let exerciseType: String
    let currentWeight: Double
    let targetReps: Int
    let setNumber: Int
    let previousSetPerformance: Double
    let fatigueLevel: Double
}

struct RestTimePrediction {
    let recommendedSeconds: Int
    let confidence: Double
    let reasoning: String
}