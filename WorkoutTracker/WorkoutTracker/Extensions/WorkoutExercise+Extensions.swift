import CoreData
import Foundation

extension WorkoutExercise {
    
    var setData: [SetData] {
        get {
            guard let jsonString = setDataJSON, !jsonString.isEmpty else {
                return migrateFromLegacyData()
            }
            return [SetData].fromJSON(jsonString)
        }
        set {
            setDataJSON = newValue.toJSON()
            updateCalculatedFields()
        }
    }
    
    private func migrateFromLegacyData() -> [SetData] {
        guard sets > 0 else { return [] }
        
        var migrated: [SetData] = []
        for setNumber in 1...sets {
            let setData = SetData(
                setNumber: Int(setNumber),
                targetReps: Int(reps),
                targetWeight: weight
            )
            var completedSet = setData
            completedSet.actualReps = Int(reps)
            completedSet.actualWeight = weight
            completedSet.completed = true
            completedSet.timestamp = workoutSession?.date
            
            migrated.append(completedSet)
        }
        
        isEnhancedTracking = true
        return migrated
    }
    
    private func updateCalculatedFields() {
        let sets = setData
        totalVolume = sets.totalVolume
    }
    
    func addSet() {
        var currentSets = setData
        let newSetNumber = currentSets.count + 1
        
        let previousSet = currentSets.last
        let newSet = SetData(
            setNumber: newSetNumber,
            targetReps: previousSet?.targetReps ?? 10,
            targetWeight: previousSet?.targetWeight ?? 0.0
        )
        
        currentSets.append(newSet)
        setData = currentSets
    }
    
    func removeSet(at index: Int) {
        var currentSets = setData
        guard index < currentSets.count else { return }
        
        currentSets.remove(at: index)
        
        for (newIndex, var set) in currentSets.enumerated() {
            set.setNumber = newIndex + 1
            currentSets[newIndex] = set
        }
        
        setData = currentSets
    }
    
    func updateSet(at index: Int, with updatedSet: SetData) {
        var currentSets = setData
        guard index < currentSets.count else { return }
        
        currentSets[index] = updatedSet
        setData = currentSets
    }
    
    func completeSet(at index: Int) {
        var currentSets = setData
        guard index < currentSets.count else { return }
        
        currentSets[index].markCompleted()
        setData = currentSets
    }
    
    var isUsingEnhancedTracking: Bool {
        return isEnhancedTracking
    }
    
    func enableEnhancedTracking() {
        guard !isEnhancedTracking else { return }
        
        let migrated = migrateFromLegacyData()
        setData = migrated
        isEnhancedTracking = true
    }
    
    var completedSetsCount: Int {
        return setData.completedSets.count
    }
    
    var totalSetsCount: Int {
        return setData.count
    }
    
    var exerciseVolume: Double {
        return setData.totalVolume
    }
    
    var exerciseCompletionRate: Double {
        return setData.completionRate
    }
    
    var hasIncompleteSets: Bool {
        return setData.contains { !$0.isCompleted }
    }
    
    /// Updates the exercise rest time from the exercise's default settings
    @MainActor
    func updateRestTimeFromExerciseDefaults() {
        guard let exercise = self.exercise else { return }
        
        // Check if the exercise has a specific rest time set
        if let exerciseRestTime = RestTimeResolver.shared.getExerciseRestTime(for: exercise) {
            self.exerciseRestTime = Int32(exerciseRestTime)
        } else {
            // Use global default
            self.exerciseRestTime = Int32(RestTimeResolver.shared.getGlobalDefaultRestTime())
        }
    }
}