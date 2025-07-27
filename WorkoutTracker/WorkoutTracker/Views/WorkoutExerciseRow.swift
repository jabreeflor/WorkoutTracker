import SwiftUI

struct WorkoutExerciseRow: View {
    @Binding var exerciseData: WorkoutExerciseData
    let previousWorkoutData: [SetData]?
    let isWorkoutActive: Bool
    let onDelete: () -> Void
    let onRestTimerStart: (Int) -> Void
    
    @State private var showingRestTimer = false
    @State private var showingDeleteConfirmation = false
    
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
        VStack(alignment: .leading, spacing: 16) {
            // Exercise Header - Cleaner Design
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Exercise illustration and details
                    HStack(spacing: 12) {
                        // Exercise icon with category color
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: exerciseIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(categoryColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exerciseData.exercise.name ?? "Unknown Exercise")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 6) {
                                Text(exerciseData.exercise.primaryMuscleGroup ?? "Unknown")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(categoryColor.opacity(0.15))
                                    )
                                    .foregroundColor(categoryColor)
                                
                                if let equipment = exerciseData.exercise.equipment {
                                    Text(equipment)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(Color(.systemGray5))
                                        )
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Options menu
                    Menu {
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Remove Exercise", systemImage: "trash")
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .medium))
                            Text("More")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.secondary)
                        .frame(width: 40, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .confirmationDialog("Remove Exercise", isPresented: $showingDeleteConfirmation) {
                        Button("Remove", role: .destructive) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                onDelete()
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Remove \(exerciseData.exercise.name ?? "this exercise") from your workout?")
                    }
                }
            }
            
            // Enhanced Set Tracking View - Always shown
            EnhancedSetTrackingView(
                exerciseData: $exerciseData,
                previousWorkoutData: previousWorkoutData,
                isWorkoutActive: isWorkoutActive,
                onRestTimerStart: onRestTimerStart
            )
            
            // Progress Summary
            if !exerciseData.setData.isEmpty {
                ProgressSummaryView(setData: exerciseData.setData)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 8,
            x: 0,
            y: 2
        )
        .onAppear {
            // Always ensure enhanced tracking is initialized
            if exerciseData.setData.isEmpty {
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
    
    // MARK: - Helper Properties
    
    private var categoryColor: Color {
        // If all sets are completed, show green regardless of muscle group
        if exerciseData.allSetsCompleted {
            return .green
        }
        
        guard let primary = exerciseData.exercise.primaryMuscleGroup else { return .blue }
        
        switch primary.lowercased() {
        case let muscle where muscle.contains("chest"): return .red
        case let muscle where muscle.contains("back"): return .blue
        case let muscle where muscle.contains("shoulder"): return .orange
        case let muscle where muscle.contains("bicep") || muscle.contains("tricep") || muscle.contains("arm"): return .purple
        case let muscle where muscle.contains("quad") || muscle.contains("glute") || muscle.contains("hamstring") || muscle.contains("calve"): return .green
        case let muscle where muscle.contains("core") || muscle.contains("oblique"): return .yellow
        case let muscle where muscle.contains("cardio"): return .pink
        case let muscle where muscle.contains("full body"): return .indigo
        default: return .blue
        }
    }
    
    private var exerciseIcon: String {
        guard let exerciseName = exerciseData.exercise.name?.lowercased() else { return "figure.strengthtraining.traditional" }
        
        switch exerciseName {
        case let name where name.contains("push-up"): return "figure.core.training"
        case let name where name.contains("pull-up"): return "figure.strengthtraining.functional"
        case let name where name.contains("squat"): return "figure.squat"
        case let name where name.contains("lunge"): return "figure.step.training"
        case let name where name.contains("plank"): return "figure.core.training"
        case let name where name.contains("deadlift"): return "figure.strengthtraining.traditional"
        case let name where name.contains("bench press"): return "figure.strengthtraining.traditional"
        case let name where name.contains("curl"): return "figure.strengthtraining.functional"
        case let name where name.contains("press"): return "figure.arms.open"
        case let name where name.contains("row"): return "figure.rower"
        default: return exerciseIconByMuscleGroup
        }
    }
    
    private var exerciseIconByMuscleGroup: String {
        guard let muscleGroup = exerciseData.exercise.primaryMuscleGroup?.lowercased() else { return "figure.strengthtraining.traditional" }
        
        switch muscleGroup {
        case let muscle where muscle.contains("chest"): return "figure.strengthtraining.traditional"
        case let muscle where muscle.contains("back"): return "figure.rower"
        case let muscle where muscle.contains("shoulder"): return "figure.arms.open"
        case let muscle where muscle.contains("bicep") || muscle.contains("tricep") || muscle.contains("arm"): return "figure.boxing"
        case let muscle where muscle.contains("quad") || muscle.contains("glute") || muscle.contains("hamstring") || muscle.contains("calve"): return "figure.squat"
        case let muscle where muscle.contains("core") || muscle.contains("oblique"): return "figure.core.training"
        case let muscle where muscle.contains("cardio"): return "heart.fill"
        case let muscle where muscle.contains("full body"): return "figure.mixed.cardio"
        default: return "figure.strengthtraining.traditional"
        }
    }
}

struct EnhancedSetTrackingView: View {
    @Binding var exerciseData: WorkoutExerciseData
    let previousWorkoutData: [SetData]?
    let isWorkoutActive: Bool
    let onRestTimerStart: (Int) -> Void
    
    @StateObject private var restTimeResolver = RestTimeResolver.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Sets List
            ForEach(Array(exerciseData.setData.enumerated()), id: \.element.id) { index, setData in
                EnhancedSetRowView(
                    setData: Binding(
                        get: { exerciseData.setData[index] },
                        set: { newValue in
                            if index < exerciseData.setData.count {
                                exerciseData.setData[index] = newValue
                            }
                        }
                    ),
                    previousSetData: getPreviousSetData(at: index),
                    isActive: isWorkoutActive,
                    onSetCompleted: {
                        updateExerciseProgress()
                        // Use RestTimeResolver to determine appropriate rest time
                        let restTime = restTimeResolver.resolveRestTime(
                            for: exerciseData.setData[index], 
                            exercise: exerciseData.exercise
                        )
                        onRestTimerStart(restTime)
                    },
                    onStartRestTimer: { duration in
                        onRestTimerStart(duration)
                    },
                    onValueChange: { updatedSet in
                        if index < exerciseData.setData.count {
                            exerciseData.setData[index] = updatedSet
                            updateLegacyFields()
                        }
                    }
                )
            }
            
            // Add/Remove Set Buttons - cleaner design
            HStack {
                Button(action: addSet) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Set")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                
                Spacer()
                
                if exerciseData.setData.count > 1 {
                    Button(action: removeLastSet) {
                        HStack(spacing: 6) {
                            Image(systemName: "minus.circle.fill")
                            Text("Remove Set")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.top, 8)
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
    
    private func completeSet(at index: Int, weight: Double, reps: Int) {
        guard index < exerciseData.setData.count else { return }
        
        exerciseData.setData[index].actualWeight = weight
        exerciseData.setData[index].actualReps = reps
        exerciseData.setData[index].completed = true
        exerciseData.setData[index].timestamp = Date()
        
        updateExerciseProgress()
        
        // Start rest timer
        onRestTimerStart(60) // Default 60 seconds
    }
    
    private func updateSetTarget(at index: Int, weight: Double, reps: Int) {
        guard index < exerciseData.setData.count else { return }
        
        exerciseData.setData[index].targetWeight = weight
        exerciseData.setData[index].targetReps = reps
        
        updateLegacyFields()
    }
    
    private func uncompleteLastCompletedSet() {
        // Find the most recent completed set and mark it as incomplete
        for index in stride(from: exerciseData.setData.count - 1, through: 0, by: -1) {
            if exerciseData.setData[index].completed {
                exerciseData.setData[index].completed = false
                exerciseData.setData[index].actualWeight = exerciseData.setData[index].targetWeight
                exerciseData.setData[index].actualReps = exerciseData.setData[index].targetReps
                exerciseData.setData[index].timestamp = nil
                
                updateExerciseProgress()
                
                // Provide haptic feedback to indicate the action
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                
                break // Only uncomplete the most recent one
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