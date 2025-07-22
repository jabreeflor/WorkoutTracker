import Foundation
import CoreData

class TrainingDataPreparer {
    static let shared = TrainingDataPreparer()
    private let context = CoreDataManager.shared.context
    
    private init() {}
    
    // MARK: - Data Preparation
    
    func prepareTrainingData(for exercise: Exercise) -> [WorkoutModelData] {
        guard let historicalWorkouts = fetchHistoricalWorkouts(for: exercise) else {
            return []
        }
        
        var trainingData: [WorkoutModelData] = []
        
        for i in 5..<historicalWorkouts.count {
            let currentWorkout = historicalWorkouts[i]
            let previousWorkouts = Array(historicalWorkouts[max(0, i-5)..<i])
            
            if let modelData = createModelData(
                currentWorkout: currentWorkout,
                previousWorkouts: previousWorkouts,
                exercise: exercise
            ) {
                trainingData.append(modelData)
            }
        }
        
        return trainingData
    }
    
    func prepareAllTrainingData() -> [ExerciseTrainingData] {
        let exercises = fetchAllExercises()
        
        return exercises.compactMap { exercise in
            let data = prepareTrainingData(for: exercise)
            return data.isEmpty ? nil : ExerciseTrainingData(exercise: exercise, data: data)
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchHistoricalWorkouts(for exercise: Exercise) -> [HistoricalWorkoutData]? {
        let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        request.predicate = NSPredicate(format: "exercises.exercise == %@", exercise)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let sessions = try context.fetch(request)
            
            let workoutData = sessions.compactMap { session -> HistoricalWorkoutData? in
                guard let workoutExercises = session.exercises?.allObjects as? [WorkoutExercise],
                      let exerciseData = workoutExercises.first(where: { $0.exercise == exercise }),
                      let date = session.date else {
                    return nil
                }
                
                let sets = exerciseData.setData
                guard !sets.isEmpty else { return nil }
                
                return HistoricalWorkoutData(
                    date: date,
                    sets: sets,
                    exercise: exercise
                )
            }
            
            return workoutData.count >= 6 ? workoutData : nil
            
        } catch {
            print("Error fetching historical workouts: \(error)")
            return nil
        }
    }
    
    private func fetchAllExercises() -> [Exercise] {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching exercises: \(error)")
            return []
        }
    }
    
    // MARK: - Model Data Creation
    
    private func createModelData(
        currentWorkout: HistoricalWorkoutData,
        previousWorkouts: [HistoricalWorkoutData],
        exercise: Exercise
    ) -> WorkoutModelData? {
        guard !previousWorkouts.isEmpty else { return nil }
        
        let currentSets = currentWorkout.sets
        let previousSets = previousWorkouts.flatMap { $0.sets }
        
        let features = calculateFeatures(
            currentSets: currentSets,
            previousSets: previousSets,
            previousWorkouts: previousWorkouts
        )
        
        let outcome = calculateOutcome(sets: currentSets)
        
        let daysSinceLastWorkout = calculateDaysSinceLastWorkout(
            currentDate: currentWorkout.date,
            previousWorkouts: previousWorkouts
        )
        
        return WorkoutModelData(
            targetWeight: features.targetWeight,
            targetReps: features.targetReps,
            recentAverageVolume: features.recentAverageVolume,
            recentAverageWeight: features.recentAverageWeight,
            recentCompletionRate: features.recentCompletionRate,
            trendMultiplier: features.trendMultiplier,
            daysSinceLastWorkout: daysSinceLastWorkout,
            workoutCount: previousWorkouts.count,
            actualSuccessProbability: outcome.successProbability
        )
    }
    
    private func calculateFeatures(
        currentSets: [SetData],
        previousSets: [SetData],
        previousWorkouts: [HistoricalWorkoutData]
    ) -> TrainingFeatures {
        let targetWeight = currentSets.first?.targetWeight ?? 0
        let targetReps = currentSets.first?.targetReps ?? 0
        
        let recentAverageVolume = previousSets.totalVolume / Double(previousWorkouts.count)
        let recentAverageWeight = previousSets.averageWeight
        let recentCompletionRate = previousSets.completionRate
        
        let trendMultiplier = calculateTrendMultiplier(workouts: previousWorkouts)
        
        return TrainingFeatures(
            targetWeight: targetWeight,
            targetReps: targetReps,
            recentAverageVolume: recentAverageVolume,
            recentAverageWeight: recentAverageWeight,
            recentCompletionRate: recentCompletionRate,
            trendMultiplier: trendMultiplier
        )
    }
    
    private func calculateOutcome(sets: [SetData]) -> TrainingOutcome {
        let completedSets = sets.filter { $0.completed }
        let totalSets = sets.count
        
        let successProbability = totalSets > 0 ? Double(completedSets.count) / Double(totalSets) : 0
        
        let repSuccess = completedSets.map { set in
            Double(set.actualReps) / Double(set.targetReps)
        }.reduce(0, +) / Double(max(1, completedSets.count))
        
        let weightSuccess = completedSets.allSatisfy { $0.actualWeight >= $0.targetWeight } ? 1.0 : 0.0
        
        let combinedSuccess = (successProbability + repSuccess + weightSuccess) / 3.0
        
        return TrainingOutcome(
            successProbability: min(1.0, max(0.0, combinedSuccess)),
            completedSets: completedSets.count,
            totalSets: totalSets
        )
    }
    
    private func calculateTrendMultiplier(workouts: [HistoricalWorkoutData]) -> Double {
        guard workouts.count >= 3 else { return 0 }
        
        let recentWorkouts = Array(workouts.suffix(3))
        let volumes = recentWorkouts.map { $0.sets.totalVolume }
        
        let firstVolume = volumes.first!
        let lastVolume = volumes.last!
        
        return firstVolume > 0 ? (lastVolume - firstVolume) / firstVolume : 0
    }
    
    private func calculateDaysSinceLastWorkout(
        currentDate: Date,
        previousWorkouts: [HistoricalWorkoutData]
    ) -> Int {
        guard let lastWorkout = previousWorkouts.last else { return 0 }
        
        let components = Calendar.current.dateComponents(
            [.day],
            from: lastWorkout.date,
            to: currentDate
        )
        
        return components.day ?? 0
    }
    
    // MARK: - Data Export
    
    func exportTrainingData(to url: URL) -> Bool {
        let allData = prepareAllTrainingData()
        
        do {
            let jsonData = try JSONEncoder().encode(allData)
            try jsonData.write(to: url)
            return true
        } catch {
            print("Failed to export training data: \(error)")
            return false
        }
    }
    
    func exportCSVData(for exercise: Exercise, to url: URL) -> Bool {
        let data = prepareTrainingData(for: exercise)
        
        var csvContent = "target_weight,target_reps,recent_average_volume,recent_average_weight,recent_completion_rate,trend_multiplier,days_since_last_workout,workout_count,success_probability\n"
        
        for item in data {
            csvContent += "\(item.targetWeight),\(item.targetReps),\(item.recentAverageVolume),\(item.recentAverageWeight),\(item.recentCompletionRate),\(item.trendMultiplier),\(item.daysSinceLastWorkout),\(item.workoutCount),\(item.actualSuccessProbability)\n"
        }
        
        do {
            try csvContent.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Failed to export CSV data: \(error)")
            return false
        }
    }
    
    // MARK: - Data Validation
    
    func validateTrainingData(_ data: [WorkoutModelData]) -> DataValidationResult {
        let validSamples = data.filter { sample in
            sample.targetWeight > 0 &&
            sample.targetReps > 0 &&
            sample.recentAverageVolume >= 0 &&
            sample.recentAverageWeight > 0 &&
            sample.recentCompletionRate >= 0 &&
            sample.recentCompletionRate <= 1 &&
            sample.workoutCount > 0 &&
            sample.actualSuccessProbability >= 0 &&
            sample.actualSuccessProbability <= 1
        }
        
        let validationRate = Double(validSamples.count) / Double(data.count)
        
        return DataValidationResult(
            totalSamples: data.count,
            validSamples: validSamples.count,
            validationRate: validationRate,
            isValid: validationRate > 0.8 && validSamples.count >= 10
        )
    }
}

// MARK: - Supporting Types

struct HistoricalWorkoutData {
    let date: Date
    let sets: [SetData]
    let exercise: Exercise
}

struct TrainingFeatures {
    let targetWeight: Double
    let targetReps: Int
    let recentAverageVolume: Double
    let recentAverageWeight: Double
    let recentCompletionRate: Double
    let trendMultiplier: Double
}

struct TrainingOutcome {
    let successProbability: Double
    let completedSets: Int
    let totalSets: Int
}

struct ExerciseTrainingData: Codable {
    let exerciseName: String
    let exerciseId: String
    let data: [WorkoutModelData]
    
    init(exercise: Exercise, data: [WorkoutModelData]) {
        self.exerciseName = exercise.name ?? "Unknown"
        self.exerciseId = exercise.objectID.uriRepresentation().absoluteString
        self.data = data
    }
}

struct DataValidationResult {
    let totalSamples: Int
    let validSamples: Int
    let validationRate: Double
    let isValid: Bool
    
    var issues: [String] {
        var problems: [String] = []
        
        if totalSamples < 10 {
            problems.append("Insufficient training data (need at least 10 samples)")
        }
        
        if validationRate < 0.8 {
            problems.append("Too many invalid samples (\(Int((1-validationRate)*100))% invalid)")
        }
        
        if validSamples < 10 {
            problems.append("Not enough valid samples for training")
        }
        
        return problems
    }
}

