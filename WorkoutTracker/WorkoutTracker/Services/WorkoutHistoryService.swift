import CoreData
import Foundation

class WorkoutHistoryService: ObservableObject {
    static let shared = WorkoutHistoryService()
    private let context = CoreDataManager.shared.context
    
    private init() {}
    
    // MARK: - Previous Workout Data
    
    func getPreviousWorkoutData(for exercise: Exercise, excluding currentWorkout: WorkoutSession? = nil) -> [SetData]? {
        let fetchRequest: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: false)]
        fetchRequest.fetchLimit = 10 // Get recent workouts to search through
        
        do {
            let recentWorkouts = try context.fetch(fetchRequest)
            
            for workout in recentWorkouts {
                // Skip the current workout if provided
                if let current = currentWorkout, workout.id == current.id {
                    continue
                }
                
                guard let workoutExercises = workout.exercises?.allObjects as? [WorkoutExercise] else { continue }
                
                // Find the exercise in this workout
                if let workoutExercise = workoutExercises.first(where: { $0.exercise?.id == exercise.id }) {
                    let setData = workoutExercise.setData
                    if !setData.isEmpty {
                        return setData
                    }
                }
            }
        } catch {
            print("Error fetching previous workout data: \(error)")
        }
        
        return nil
    }
    
    func getProgressiveRecommendations(for exercise: Exercise, excluding currentWorkout: WorkoutSession? = nil) -> [SetData] {
        let previousData = getPreviousWorkoutData(for: exercise, excluding: currentWorkout)
        return ProgressiveOverloadEngine.shared.getRecommendations(
            for: exercise,
            lastWorkoutData: previousData
        )
    }
    
    // MARK: - Exercise History
    
    func getExerciseHistory(for exercise: Exercise, limit: Int = 5) -> [ExerciseHistoryEntry] {
        let fetchRequest: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: false)]
        
        do {
            let allWorkouts = try context.fetch(fetchRequest)
            var history: [ExerciseHistoryEntry] = []
            
            for workout in allWorkouts {
                guard history.count < limit else { break }
                guard let workoutExercises = workout.exercises?.allObjects as? [WorkoutExercise] else { continue }
                
                if let workoutExercise = workoutExercises.first(where: { $0.exercise?.id == exercise.id }) {
                    let entry = ExerciseHistoryEntry(
                        date: workout.date ?? Date(),
                        workoutName: workout.name ?? "Workout",
                        setData: workoutExercise.setData,
                        totalVolume: workoutExercise.setData.totalVolume,
                        maxWeight: workoutExercise.setData.map { $0.actualWeight }.max() ?? 0,
                        totalReps: workoutExercise.setData.reduce(0) { $0 + $1.actualReps }
                    )
                    history.append(entry)
                }
            }
            
            return history
        } catch {
            print("Error fetching exercise history: \(error)")
            return []
        }
    }
    
    // MARK: - Personal Records
    
    func getPersonalRecords(for exercise: Exercise) -> PersonalRecords {
        let history = getExerciseHistory(for: exercise, limit: 50) // More data for PR analysis
        
        var maxWeight: Double = 0
        var maxVolume: Double = 0
        var maxReps: Int = 0
        var bestSet: SetData?
        
        var maxWeightDate: Date?
        var maxVolumeDate: Date?
        var maxRepsDate: Date?
        
        for entry in history {
            // Max volume
            if entry.totalVolume > maxVolume {
                maxVolume = entry.totalVolume
                maxVolumeDate = entry.date
            }
            
            // Check each set for records
            for set in entry.setData where set.completed {
                // Max weight
                if set.actualWeight > maxWeight {
                    maxWeight = set.actualWeight
                    maxWeightDate = entry.date
                }
                
                // Max reps (at any weight)
                if set.actualReps > maxReps {
                    maxReps = set.actualReps
                    maxRepsDate = entry.date
                }
                
                // Best set (highest weight × reps)
                let setScore = set.actualWeight * Double(set.actualReps)
                let bestScore = (bestSet?.actualWeight ?? 0) * Double(bestSet?.actualReps ?? 0)
                
                if setScore > bestScore {
                    bestSet = set
                }
            }
        }
        
        return PersonalRecords(
            maxWeight: maxWeight > 0 ? WeightRecord(weight: maxWeight, date: maxWeightDate) : nil,
            maxVolume: maxVolume > 0 ? VolumeRecord(volume: maxVolume, date: maxVolumeDate) : nil,
            maxReps: maxReps > 0 ? RepsRecord(reps: maxReps, date: maxRepsDate) : nil,
            bestSet: bestSet
        )
    }
    
    // MARK: - Progress Tracking
    
    func getProgressTrend(for exercise: Exercise, period: ProgressPeriod = .month) -> ProgressTrend {
        let cutoffDate = Calendar.current.date(byAdding: period.dateComponent, value: -period.value, to: Date()) ?? Date()
        let history = getExerciseHistory(for: exercise, limit: 20)
        let recentHistory = history.filter { $0.date >= cutoffDate }
        
        guard recentHistory.count >= 2 else {
            return ProgressTrend(
                period: period,
                volumeChange: 0,
                strengthChange: 0,
                consistency: 0,
                workoutCount: recentHistory.count
            )
        }
        
        let firstWorkout = recentHistory.last!
        let lastWorkout = recentHistory.first!
        
        // Volume change
        let volumeChange = firstWorkout.totalVolume > 0 ? 
            (lastWorkout.totalVolume - firstWorkout.totalVolume) / firstWorkout.totalVolume : 0
        
        // Strength change (max weight)
        let strengthChange = firstWorkout.maxWeight > 0 ?
            (lastWorkout.maxWeight - firstWorkout.maxWeight) / firstWorkout.maxWeight : 0
        
        // Consistency (average completion rate)
        let totalSets = recentHistory.flatMap { $0.setData }.count
        let completedSets = recentHistory.flatMap { $0.setData }.filter { $0.completed }.count
        let consistency = totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0
        
        return ProgressTrend(
            period: period,
            volumeChange: volumeChange,
            strengthChange: strengthChange,
            consistency: consistency,
            workoutCount: recentHistory.count
        )
    }
    
    // MARK: - Workout Comparison
    
    func compareWorkouts(current: [SetData], previous: [SetData]) -> WorkoutComparison {
        return WorkoutComparison(currentSets: current, previousSets: previous)
    }
}

// MARK: - Supporting Types

struct ExerciseHistoryEntry {
    let date: Date
    let workoutName: String
    let setData: [SetData]
    let totalVolume: Double
    let maxWeight: Double
    let totalReps: Int
}

struct PersonalRecords {
    let maxWeight: WeightRecord?
    let maxVolume: VolumeRecord?
    let maxReps: RepsRecord?
    let bestSet: SetData?
}

struct WeightRecord {
    let weight: Double
    let date: Date?
}

struct VolumeRecord {
    let volume: Double
    let date: Date?
}

struct RepsRecord {
    let reps: Int
    let date: Date?
}

struct ProgressTrend {
    let period: ProgressPeriod
    let volumeChange: Double // Percentage change
    let strengthChange: Double // Percentage change
    let consistency: Double // 0.0 to 1.0
    let workoutCount: Int
    
    var volumeChangeFormatted: String {
        let percentage = Int(volumeChange * 100)
        return percentage > 0 ? "+\(percentage)%" : "\(percentage)%"
    }
    
    var strengthChangeFormatted: String {
        let percentage = Int(strengthChange * 100)
        return percentage > 0 ? "+\(percentage)%" : "\(percentage)%"
    }
    
    var consistencyFormatted: String {
        return "\(Int(consistency * 100))%"
    }
}

enum ProgressPeriod {
    case week, month, quarter
    
    var value: Int {
        switch self {
        case .week: return 1
        case .month: return 1
        case .quarter: return 3
        }
    }
    
    var dateComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        case .quarter: return .month
        }
    }
    
    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .quarter: return "Last 3 Months"
        }
    }
}

struct WorkoutComparison {
    let volumeChange: Double
    let weightChange: Double
    let setCountChange: Int
    let improvementAreas: [String]
    let declineAreas: [String]
    
    init(currentSets: [SetData], previousSets: [SetData]) {
        let currentVolume = currentSets.totalVolume
        let previousVolume = previousSets.totalVolume
        
        self.volumeChange = previousVolume > 0 ? (currentVolume - previousVolume) / previousVolume : 0
        
        let currentMaxWeight = currentSets.map { $0.actualWeight }.max() ?? 0
        let previousMaxWeight = previousSets.map { $0.actualWeight }.max() ?? 0
        
        self.weightChange = previousMaxWeight > 0 ? (currentMaxWeight - previousMaxWeight) / previousMaxWeight : 0
        
        self.setCountChange = currentSets.count - previousSets.count
        
        var improvements: [String] = []
        var declines: [String] = []
        
        if volumeChange > 0.05 {
            improvements.append("Volume increased by \(Int(volumeChange * 100))%")
        } else if volumeChange < -0.05 {
            declines.append("Volume decreased by \(Int(abs(volumeChange) * 100))%")
        }
        
        if weightChange > 0.01 {
            improvements.append("Max weight increased")
        } else if weightChange < -0.01 {
            declines.append("Max weight decreased")
        }
        
        if setCountChange > 0 {
            improvements.append("Added \(setCountChange) more set(s)")
        } else if setCountChange < 0 {
            declines.append("Did \(abs(setCountChange)) fewer set(s)")
        }
        
        self.improvementAreas = improvements
        self.declineAreas = declines
    }
}