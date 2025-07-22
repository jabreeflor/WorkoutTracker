import SwiftUI
import CoreData

struct WorkoutSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)],
        animation: .default
    ) private var exercises: FetchedResults<Exercise>
    
    let template: WorkoutTemplate?
    
    @State private var workoutName = "My Workout"
    @State private var selectedExercises: [WorkoutExerciseData] = []
    @State private var showingExerciseSelection = false
    @State private var startTime = Date()
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var currentWorkoutSession: WorkoutSession?
    @StateObject private var restTimerService = RestTimerService()
    
    init(template: WorkoutTemplate? = nil) {
        self.template = template
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with workout name and timer
                VStack(spacing: 8) {
                    TextField("Workout Name", text: $workoutName)
                        .font(.title2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Text("Duration: \(formatTime(elapsedTime))")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("Started: \(startTime, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Add Exercise Button
                Button(action: {
                    showingExerciseSelection = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Exercise")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Rest Timer (if active)
                if restTimerService.isActive {
                    RestTimerView(
                        timerService: restTimerService,
                        onMinusPressed: {
                            uncompleteLastCompletedSet()
                        }
                    )
                }
                
                // Exercise List
                if selectedExercises.isEmpty {
                    VStack {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No exercises added yet")
                            .foregroundColor(.gray)
                        Text("Tap 'Add Exercise' to get started!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(selectedExercises.enumerated()), id: \.offset) { index, exerciseData in
                                WorkoutExerciseRow(
                                    exerciseData: Binding(
                                        get: { 
                                            guard index < selectedExercises.count else { 
                                                return WorkoutExerciseData(exercise: exerciseData.exercise)
                                            }
                                            return selectedExercises[index] 
                                        },
                                        set: { newValue in
                                            guard index < selectedExercises.count else { return }
                                            print("DEBUG: Updating exercise at index \(index) - Sets: \(newValue.sets), Reps: \(newValue.reps), Weight: \(newValue.weight)")
                                            selectedExercises[index] = newValue
                                        }
                                    ),
                                    previousWorkoutData: getPreviousWorkoutData(for: exerciseData.exercise),
                                    isWorkoutActive: true,
                                    onDelete: {
                                        if index < selectedExercises.count {
                                            selectedExercises.remove(at: index)
                                        }
                                    },
                                    onRestTimerStart: { duration in
                                        restTimerService.start(duration: TimeInterval(duration))
                                    }
                                )
                                .id("exercise-\(index)-\(exerciseData.exercise.objectID)")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Bottom buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    
                    Button("Save Workout") {
                        saveWorkout()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedExercises.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .disabled(selectedExercises.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Active Workout")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingExerciseSelection) {
                ModernExerciseSelectionView(selectedExercises: $selectedExercises, exercises: Array(exercises))
            }
            .onAppear {
                startTimer()
                loadTemplateData()
                createWorkoutSession()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func loadTemplateData() {
        guard let template = template else { return }
        
        workoutName = template.name ?? "My Workout"
        
        if let templateExercises = template.templateExercises?.allObjects as? [TemplateExercise] {
            let sortedExercises = templateExercises.sorted { $0.orderIndex < $1.orderIndex }
            
            selectedExercises = sortedExercises.compactMap { templateExercise in
                guard let exercise = templateExercise.exercise else { return nil }
                
                var exerciseData = WorkoutExerciseData(exercise: exercise)
                exerciseData.sets = Int(templateExercise.defaultSets)
                exerciseData.reps = Int(templateExercise.defaultReps)
                exerciseData.weight = templateExercise.defaultWeight
                
                return exerciseData
            }
        }
    }
    
    private func createWorkoutSession() {
        guard currentWorkoutSession == nil else { return }
        
        let workout = WorkoutSession(context: viewContext)
        workout.id = UUID()
        workout.name = workoutName
        workout.date = startTime
        workout.duration = 0
        currentWorkoutSession = workout
        
        do {
            try viewContext.save()
        } catch {
            print("Error creating workout session: \(error)")
        }
    }
    
    private func saveWorkout() {
        guard let workout = currentWorkoutSession else {
            print("No current workout session to save")
            return
        }
        
        // Update workout session details
        workout.name = workoutName
        workout.duration = Int32(elapsedTime)
        
        // Save or update workout exercises with enhanced tracking
        for exerciseData in selectedExercises {
            let workoutExercise = WorkoutExercise(context: viewContext)
            workoutExercise.id = UUID()
            workoutExercise.exercise = exerciseData.exercise
            workoutExercise.workoutSession = workout
            
            // Use enhanced tracking if available, otherwise fallback to legacy
            if exerciseData.isUsingEnhancedTracking && !exerciseData.setData.isEmpty {
                workoutExercise.isEnhancedTracking = true
                workoutExercise.setDataJSON = exerciseData.setData.toJSON()
                workoutExercise.totalVolume = exerciseData.setData.totalVolume
                // Update legacy fields for backward compatibility
                workoutExercise.sets = Int32(exerciseData.setData.count)
                workoutExercise.reps = Int32(exerciseData.setData.first?.targetReps ?? exerciseData.reps)
                workoutExercise.weight = exerciseData.setData.first?.targetWeight ?? exerciseData.weight
            } else {
                // Fallback to legacy tracking
                workoutExercise.sets = Int32(exerciseData.sets)
                workoutExercise.reps = Int32(exerciseData.reps)
                workoutExercise.weight = exerciseData.weight
                workoutExercise.isEnhancedTracking = false
                workoutExercise.totalVolume = Double(exerciseData.sets) * Double(exerciseData.reps) * exerciseData.weight
            }
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving workout: \(error)")
        }
    }
    
    private func getPreviousWorkoutData(for exercise: Exercise) -> [SetData]? {
        let fetchRequest: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date < %@ AND ANY exercises.exercise == %@", 
                                            startTime as NSDate, 
                                            exercise)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let previousSessions = try viewContext.fetch(fetchRequest)
            if let previousSession = previousSessions.first,
               let previousExercises = previousSession.exercises?.allObjects as? [WorkoutExercise],
               let previousExercise = previousExercises.first(where: { $0.exercise == exercise }) {
                return previousExercise.setData
            }
        } catch {
            print("Error fetching previous workout data: \(error)")
        }
        
        return nil
    }
    
    private func uncompleteLastCompletedSet() {
        // Find the most recent completed set across all exercises and mark it as incomplete
        var mostRecentCompletedSet: (exerciseIndex: Int, setIndex: Int, timestamp: Date)?
        
        for (exerciseIndex, exerciseData) in selectedExercises.enumerated() {
            for (setIndex, setData) in exerciseData.setData.enumerated() {
                if setData.completed, let timestamp = setData.timestamp {
                    if mostRecentCompletedSet == nil || timestamp > mostRecentCompletedSet!.timestamp {
                        mostRecentCompletedSet = (exerciseIndex, setIndex, timestamp)
                    }
                }
            }
        }
        
        // Uncomplete the most recent completed set
        if let recentSet = mostRecentCompletedSet {
            selectedExercises[recentSet.exerciseIndex].setData[recentSet.setIndex].completed = false
            selectedExercises[recentSet.exerciseIndex].setData[recentSet.setIndex].actualWeight = selectedExercises[recentSet.exerciseIndex].setData[recentSet.setIndex].targetWeight
            selectedExercises[recentSet.exerciseIndex].setData[recentSet.setIndex].actualReps = selectedExercises[recentSet.exerciseIndex].setData[recentSet.setIndex].targetReps
            selectedExercises[recentSet.exerciseIndex].setData[recentSet.setIndex].timestamp = nil
            
            // Provide haptic feedback to indicate the action
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // Optional: Provide visual feedback
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.warning)
        }
    }
    
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    WorkoutSessionView()
}