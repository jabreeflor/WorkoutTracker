import SwiftUI

struct WorkoutExerciseRow: View {
    @Binding var exerciseData: WorkoutExerciseData
    let previousWorkoutData: [SetData]?
    let isWorkoutActive: Bool
    let onDelete: () -> Void
    let onRestTimerStart: (Int) -> Void
    
    @State private var showingEnhancedView = false
    @State private var showingRestTimer = false
    
    init(
        exerciseData: Binding<WorkoutExerciseData>,
        previousWorkoutData: [SetData]? = nil,
        isWorkoutActive: Bool = true,
        onDelete: @escaping () -> Void,
        onRestTimerStart: @escaping (Int) -> Void = { _ in }
    ) {
        self._exerciseData = exerciseData
        self.previousWorkoutData = previousWorkoutData
        self.isWorkoutActive = isWorkoutActive
        self.onDelete = onDelete
        self.onRestTimerStart = onRestTimerStart
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseData.exercise.name ?? "Unknown Exercise")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Primary: \(exerciseData.exercise.primaryMuscleGroup ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Enhanced tracking toggle
                    Button(action: {
                        showingEnhancedView.toggle()
                        if showingEnhancedView && exerciseData.setData.isEmpty {
                            initializeSetData()
                        }
                    }) {
                        Image(systemName: showingEnhancedView ? "list.bullet.circle.fill" : "list.bullet.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Enhanced Set Tracking View
            if showingEnhancedView {
                EnhancedSetTrackingView(
                    exerciseData: $exerciseData,
                    previousWorkoutData: previousWorkoutData,
                    isWorkoutActive: isWorkoutActive,
                    onRestTimerStart: onRestTimerStart
                )
            } else {
                // Legacy Simple View
                LegacySetTrackingView(exerciseData: $exerciseData)
            }
            
            // Progress Summary
            if showingEnhancedView && !exerciseData.setData.isEmpty {
                ProgressSummaryView(setData: exerciseData.setData)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            // Auto-enable enhanced tracking for new exercises during active workouts
            if isWorkoutActive && exerciseData.setData.isEmpty {
                showingEnhancedView = true
                initializeSetData()
            }
        }
    }
    
    private func initializeSetData() {
        if exerciseData.setData.isEmpty {
            let safeReps = max(1, exerciseData.reps)
            let safeWeight = max(0, exerciseData.weight)
            
            exerciseData.setData = [
                SetData(
                    setNumber: 1,
                    targetReps: safeReps,
                    targetWeight: safeWeight
                ),
                SetData(
                    setNumber: 2,
                    targetReps: safeReps,
                    targetWeight: safeWeight
                ),
                SetData(
                    setNumber: 3,
                    targetReps: safeReps,
                    targetWeight: safeWeight
                )
            ]
            exerciseData.isUsingEnhancedTracking = true
        }
    }
}

struct EnhancedSetTrackingView: View {
    @Binding var exerciseData: WorkoutExerciseData
    let previousWorkoutData: [SetData]?
    let isWorkoutActive: Bool
    let onRestTimerStart: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Sets List
            ForEach(Array(exerciseData.setData.enumerated()), id: \.element.id) { index, setData in
                SetRow(
                    setData: Binding(
                        get: { 
                            guard index < exerciseData.setData.count else { 
                                return SetData(setNumber: index + 1)
                            }
                            return exerciseData.setData[index] 
                        },
                        set: { newValue in
                            guard index < exerciseData.setData.count else { return }
                            exerciseData.setData[index] = newValue
                        }
                    ),
                    setNumber: index + 1,
                    previousSetData: getPreviousSetData(at: index),
                    isWorkoutActive: isWorkoutActive,
                    onSetCompleted: {
                        updateExerciseProgress()
                    },
                    onStartRestTimer: onRestTimerStart
                )
            }
            
            // Add/Remove Set Buttons
            HStack {
                Button(action: addSet) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Add Set")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                if exerciseData.setData.count > 1 {
                    Button(action: removeLastSet) {
                        HStack(spacing: 4) {
                            Image(systemName: "minus.circle")
                            Text("Remove Set")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func addSet() {
        let newSetNumber = exerciseData.setData.count + 1
        let lastSet = exerciseData.setData.last
        
        let newSet = SetData(
            setNumber: newSetNumber,
            targetReps: lastSet?.targetReps ?? exerciseData.reps,
            targetWeight: lastSet?.targetWeight ?? exerciseData.weight
        )
        
        exerciseData.setData.append(newSet)
        updateLegacyFields()
    }
    
    private func removeLastSet() {
        guard exerciseData.setData.count > 1 else { return }
        exerciseData.setData.removeLast()
        updateLegacyFields()
    }
    
    private func updateExerciseProgress() {
        updateLegacyFields()
    }
    
    private func updateLegacyFields() {
        exerciseData.sets = exerciseData.setData.count
        if let lastSet = exerciseData.setData.last {
            exerciseData.reps = lastSet.targetReps
            exerciseData.weight = lastSet.targetWeight
        }
    }
    
    private func getPreviousSetData(at index: Int) -> SetData? {
        guard let previousData = previousWorkoutData,
              index < previousData.count else {
            return nil
        }
        return previousData[index]
    }
}

struct LegacySetTrackingView: View {
    @Binding var exerciseData: WorkoutExerciseData
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Sets")
                    .font(.caption)
                    .foregroundColor(.gray)
                Stepper(value: $exerciseData.sets, in: 1...20) {
                    Text("\(exerciseData.sets)")
                        .font(.headline)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Reps")
                    .font(.caption)
                    .foregroundColor(.gray)
                Stepper(value: $exerciseData.reps, in: 1...100) {
                    Text("\(exerciseData.reps)")
                        .font(.headline)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Weight (lbs)")
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack {
                    TextField("0", value: $exerciseData.weight, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                    Text("lbs")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct ProgressSummaryView: View {
    let setData: [SetData]
    
    private var completedSets: Int {
        setData.filter { $0.completed }.count
    }
    
    private var totalVolume: Double {
        setData.totalVolume
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("\(completedSets)/\(setData.count) sets")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            if totalVolume > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass")
                        .foregroundColor(.purple)
                        .font(.caption)
                    Text(String(format: "Total: %.1f lbs", totalVolume))
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(6)
    }
}

#Preview {
    WorkoutExerciseRow(
        exerciseData: Binding.constant(WorkoutExerciseData(exercise: Exercise())),
        onDelete: {}
    )
}