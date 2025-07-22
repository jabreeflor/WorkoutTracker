import Foundation

public struct WorkoutExerciseData: Equatable {
    let exercise: Exercise
    var sets: Int = 1
    var reps: Int = 10
    var weight: Double = 0.0
    var setData: [SetData] = []
    var isUsingEnhancedTracking: Bool = false
    
    public init(exercise: Exercise) {
        self.exercise = exercise
        self.sets = 3
        self.reps = 10
        self.weight = 0.0
        self.setData = []
        self.isUsingEnhancedTracking = false
    }
    
    public mutating func enableEnhancedTracking() {
        guard !isUsingEnhancedTracking else { return }
        
        let safeReps = max(1, reps)
        let safeWeight = max(0, weight)
        let safeSets = max(1, sets)
        
        // Initialize set data based on current legacy values
        setData = (1...safeSets).map { setNumber in
            SetData(
                setNumber: setNumber,
                targetReps: safeReps,
                targetWeight: safeWeight
            )
        }
        
        isUsingEnhancedTracking = true
    }
    
    var totalVolume: Double {
        if isUsingEnhancedTracking {
            return setData.totalVolume
        } else {
            return Double(sets) * Double(reps) * weight
        }
    }
    
    var completedSetsCount: Int {
        if isUsingEnhancedTracking {
            return setData.filter { $0.completed }.count
        } else {
            return sets // Assume all sets completed in legacy mode
        }
    }
    
    var allSetsCompleted: Bool {
        if isUsingEnhancedTracking {
            return !setData.isEmpty && setData.allSatisfy { $0.completed }
        } else {
            return true // Legacy mode assumes completion
        }
    }
    
    public static func == (lhs: WorkoutExerciseData, rhs: WorkoutExerciseData) -> Bool {
        return lhs.exercise.objectID == rhs.exercise.objectID &&
               lhs.sets == rhs.sets &&
               lhs.reps == rhs.reps &&
               lhs.weight == rhs.weight &&
               lhs.setData == rhs.setData &&
               lhs.isUsingEnhancedTracking == rhs.isUsingEnhancedTracking
    }
}