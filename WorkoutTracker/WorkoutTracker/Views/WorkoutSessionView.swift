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
                    RestTimerView(timerService: restTimerService)
                        .padding(.horizontal)
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
                    List {
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
                        }
                        .onDelete(perform: deleteExercises)
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
                ExerciseSelectionView(selectedExercises: $selectedExercises, exercises: Array(exercises))
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
            
            // Use enhanced tracking if set data exists
            if !exerciseData.setData.isEmpty {
                workoutExercise.isEnhancedTracking = true
                workoutExercise.setData = exerciseData.setData
                workoutExercise.totalVolume = exerciseData.setData.totalVolume
            } else {
                // Fallback to legacy tracking
                workoutExercise.sets = Int32(exerciseData.sets)
                workoutExercise.reps = Int32(exerciseData.reps)
                workoutExercise.weight = exerciseData.weight
                workoutExercise.isEnhancedTracking = false
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
    
    private func deleteExercises(offsets: IndexSet) {
        selectedExercises.remove(atOffsets: offsets)
    }
}

struct WorkoutExerciseData {
    let exercise: Exercise
    var sets: Int = 1
    var reps: Int = 10
    var weight: Double = 0.0
    var setData: [SetData] = []
    var isUsingEnhancedTracking: Bool = false
    
    init(exercise: Exercise) {
        self.exercise = exercise
        self.sets = 3
        self.reps = 10
        self.weight = 0.0
        self.setData = []
        self.isUsingEnhancedTracking = false
    }
    
    mutating func enableEnhancedTracking() {
        guard !isUsingEnhancedTracking else { return }
        guard sets > 0 else { 
            sets = 3 // Default to 3 sets if somehow 0
            return 
        }
        
        // Initialize set data based on current legacy values
        setData = (1...sets).map { setNumber in
            SetData(
                setNumber: setNumber,
                targetReps: max(1, reps), // Ensure at least 1 rep
                targetWeight: max(0, weight) // Ensure non-negative weight
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