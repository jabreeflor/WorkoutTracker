import Foundation
import CoreData
import Combine

@MainActor
class SetTrackingService: ObservableObject {
    // MARK: - Published Properties
    @Published var currentExercise: WorkoutExercise?
    @Published var activeSets: [SetData] = []
    @Published var currentSetIndex: Int = 0
    @Published var previousWorkoutSets: [SetData]? = nil
    @Published var isLoading: Bool = false
    @Published var progressionSuggestion: ProgressionSuggestion? = nil
    
    // MARK: - Services
    let restTimerService = RestTimerService()
    
    // MARK: - Private Properties
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Public Methods
    
    /// Loads sets for the specified exercise
    /// - Parameter exercise: The workout exercise to load sets for
    func loadSets(for exercise: WorkoutExercise) {
        isLoading = true
        currentExercise = exercise
        
        // Load existing sets or create default ones
        if exercise.isUsingEnhancedTracking {
            activeSets = exercise.setData
        } else {
            // Enable enhanced tracking and migrate legacy data
            exercise.enableEnhancedTracking()
            activeSets = exercise.setData
        }
        
        // If no sets exist, create a default one
        if activeSets.isEmpty {
            addSet()
        }
        
        // Find the first incomplete set
        currentSetIndex = activeSets.firstIndex(where: { !$0.completed }) ?? 0
        
        // Load previous workout data
        Task {
            await loadPreviousWorkoutData()
            await generateProgressionSuggestion()
            isLoading = false
        }
    }
    
    /// Adds a new set to the current exercise
    func addSet() {
        guard let exercise = currentExercise else { return }
        
        // Get the last set for reference values
        let lastSet = activeSets.last
        
        // Create a new set with values from the last set or defaults
        let newSetNumber = activeSets.count + 1
        let newSet = SetData(
            setNumber: newSetNumber,
            targetReps: lastSet?.targetReps ?? 10,
            targetWeight: lastSet?.targetWeight ?? 0.0
        )
        
        // Add to active sets and save
        activeSets.append(newSet)
        exercise.setData = activeSets
        saveChanges()
    }
    
    /// Removes a set at the specified index
    /// - Parameter index: The index of the set to remove
    func removeSet(at index: Int) {
        guard let exercise = currentExercise, index < activeSets.count else { return }
        
        // Remove the set
        activeSets.remove(at: index)
        
        // Renumber remaining sets
        for i in 0..<activeSets.count {
            var set = activeSets[i]
            set.setNumber = i + 1
            activeSets[i] = set
        }
        
        // Update current index if needed
        if currentSetIndex >= activeSets.count {
            currentSetIndex = max(0, activeSets.count - 1)
        }
        
        // Save changes
        exercise.setData = activeSets
        saveChanges()
    }
    
    /// Updates the target values for a set at the specified index
    /// - Parameters:
    ///   - index: The index of the set to update
    ///   - weight: The new target weight
    ///   - reps: The new target reps
    func updateTargetValues(at index: Int, weight: Double, reps: Int) {
        guard let exercise = currentExercise, index < activeSets.count else { return }
        
        // Update the set
        var set = activeSets[index]
        set.targetWeight = weight
        set.targetReps = reps
        activeSets[index] = set
        
        // Save changes
        exercise.setData = activeSets
        saveChanges()
    }
    
    /// Completes a set at the specified index with the actual weight and reps
    /// - Parameters:
    ///   - index: The index of the set to complete
    ///   - weight: The actual weight used
    ///   - reps: The actual reps performed
    ///   - rpe: Optional rate of perceived exertion (1-10)
    func completeSet(at index: Int, weight: Double, reps: Int, rpe: Int? = nil) {
        guard let exercise = currentExercise, index < activeSets.count else { return }
        
        // Update the set
        var set = activeSets[index]
        set.actualWeight = weight
        set.actualReps = reps
        set.completed = true
        set.timestamp = Date()
        activeSets[index] = set
        
        // Save changes
        exercise.setData = activeSets
        saveChanges()
        
        // Auto-advance to next set if available
        if index == currentSetIndex && index < activeSets.count - 1 {
            currentSetIndex = index + 1
        }
        
        // Start rest timer if not the last set
        if index < activeSets.count - 1 {
            startRestTimer()
        }
    }
    
    /// Uncompletes a set at the specified index
    /// - Parameter index: The index of the set to uncomplete
    func uncompleteSet(at index: Int) {
        guard let exercise = currentExercise, index < activeSets.count else { return }
        
        // Update the set
        var set = activeSets[index]
        set.completed = false
        set.timestamp = nil
        activeSets[index] = set
        
        // Save changes
        exercise.setData = activeSets
        saveChanges()
    }
    
    /// Applies a progression suggestion to all sets
    /// - Parameter suggestion: The progression suggestion to apply
    func applyProgressionSuggestion(_ suggestion: ProgressionSuggestion) {
        guard let exercise = currentExercise else { return }
        
        // Apply the suggestion to all sets
        for i in 0..<activeSets.count {
            var set = activeSets[i]
            
            switch suggestion.type {
            case .increaseWeight:
                if let newWeight = suggestion.newWeight {
                    set.targetWeight = newWeight
                }
            case .increaseReps:
                if let newReps = suggestion.newReps {
                    set.targetReps = newReps
                }
            case .deload:
                if let newWeight = suggestion.newWeight {
                    set.targetWeight = newWeight
                }
            case .maintain:
                // No changes needed
                break
            }
            
            activeSets[i] = set
        }
        
        // Save changes
        exercise.setData = activeSets
        saveChanges()
        
        // Clear the suggestion
        progressionSuggestion = nil
    }
    
    // MARK: - Private Methods
    
    /// Loads data from the previous workout for the same exercise
    private func loadPreviousWorkoutData() async {
        guard let exercise = currentExercise,
              let currentExerciseId = exercise.exercise?.id else {
            previousWorkoutSets = nil
            return
        }
        
        // Get the current workout session date
        guard let currentSessionDate = exercise.workoutSession?.date else {
            previousWorkoutSets = nil
            return
        }
        
        // Find the previous workout session with the same exercise
        let fetchRequest: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date < %@ AND ANY exercises.exercise.id == %@", 
                                            currentSessionDate as NSDate, 
                                            currentExerciseId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let context = coreDataManager.context
            let previousSessions = try context.fetch(fetchRequest)
            
            if let previousSession = previousSessions.first,
               let previousExercises = previousSession.exercises?.allObjects as? [WorkoutExercise],
               let previousExercise = previousExercises.first(where: { $0.exercise?.id == currentExerciseId }) {
                
                // Get the set data from the previous exercise
                await MainActor.run {
                    self.previousWorkoutSets = previousExercise.setData
                }
            } else {
                await MainActor.run {
                    self.previousWorkoutSets = nil
                }
            }
        } catch {
            print("Error fetching previous workout data: \(error)")
            await MainActor.run {
                self.previousWorkoutSets = nil
            }
        }
    }
    
    /// Generates a progression suggestion based on previous workout data
    private func generateProgressionSuggestion() async {
        guard let _ = currentExercise,
              let previousSets = previousWorkoutSets,
              !previousSets.isEmpty else {
            progressionSuggestion = nil
            return
        }
        
        // Get the current and previous workout data
        let _ = activeSets
        
        // Calculate completion rate for previous workout
        let previousCompletionRate = previousSets.completionRate
        
        // Calculate average weight and reps from previous workout
        let previousAvgWeight = previousSets.averageWeight
        let previousAvgReps = previousSets.averageReps
        
        // Generate suggestion based on previous performance
        if previousCompletionRate >= 0.9 {
            // If completed 90%+ of sets in previous workout, suggest increasing weight
            if previousAvgWeight > 0 {
                let increment = previousAvgWeight < 100 ? 2.5 : 5.0
                let newWeight = previousAvgWeight + increment
                
                await MainActor.run {
                    self.progressionSuggestion = ProgressionSuggestion(
                        type: .increaseWeight,
                        newWeight: newWeight,
                        newReps: nil,
                        confidence: 0.8,
                        reasoning: "You completed all sets last time. Ready for more weight!"
                    )
                }
            }
        } else if previousCompletionRate >= 0.7 {
            // If completed 70-90% of sets, suggest increasing reps
            if previousAvgReps > 0 {
                let newReps = Int(previousAvgReps) + 1
                
                await MainActor.run {
                    self.progressionSuggestion = ProgressionSuggestion(
                        type: .increaseReps,
                        newWeight: nil,
                        newReps: newReps,
                        confidence: 0.7,
                        reasoning: "You're doing well. Try adding one more rep before increasing weight."
                    )
                }
            }
        } else if previousCompletionRate < 0.5 {
            // If completed less than 50% of sets, suggest deloading
            if previousAvgWeight > 0 {
                let newWeight = previousAvgWeight * 0.9 // 10% deload
                
                await MainActor.run {
                    self.progressionSuggestion = ProgressionSuggestion(
                        type: .deload,
                        newWeight: newWeight,
                        newReps: nil,
                        confidence: 0.75,
                        reasoning: "You struggled last time. Try reducing the weight to build back up."
                    )
                }
            }
        } else {
            // Otherwise, suggest maintaining current weight/reps
            await MainActor.run {
                self.progressionSuggestion = ProgressionSuggestion(
                    type: .maintain,
                    newWeight: nil,
                    newReps: nil,
                    confidence: 0.6,
                    reasoning: "Keep working at this weight until you can complete all sets."
                )
            }
        }
    }
    
    /// Starts the rest timer
    private func startRestTimer() {
        guard let exercise = currentExercise else { return }
        
        // Get rest time from exercise or use default
        let restTime = exercise.exerciseRestTime > 0 ? Int(exercise.exerciseRestTime) : 60
        
        // Start the timer
        restTimerService.start(duration: TimeInterval(restTime))
    }
    
    /// Saves changes to Core Data
    private func saveChanges() {
        do {
            try coreDataManager.context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - Progression Suggestion

struct ProgressionSuggestion {
    let type: ProgressionType
    let newWeight: Double?
    let newReps: Int?
    let confidence: Double // 0.0 - 1.0
    let reasoning: String
    
    enum ProgressionType {
        case increaseWeight
        case increaseReps
        case maintain
        case deload
    }
}