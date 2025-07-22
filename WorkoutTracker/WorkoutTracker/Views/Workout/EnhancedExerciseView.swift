import SwiftUI

struct EnhancedExerciseView: View {
    // MARK: - Properties
    let exercise: WorkoutExercise
    
    // MARK: - State
    @StateObject private var setTrackingService = SetTrackingService()
    @State private var showingAddSetAlert = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            // Exercise header
            exerciseHeader
            
            // Progression suggestion
            if let suggestion = setTrackingService.progressionSuggestion {
                progressionSuggestionView(suggestion)
            }
            
            // Sets list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(setTrackingService.activeSets.enumerated()), id: \.element.id) { index, set in
                        SetRowView(
                            set: set,
                            previousSet: setTrackingService.previousWorkoutSets?.first(where: { $0.setNumber == set.setNumber }),
                            isActive: index == setTrackingService.currentSetIndex,
                            onComplete: { weight, reps in
                                setTrackingService.completeSet(at: index, weight: weight, reps: reps)
                            },
                            onUpdate: { weight, reps in
                                setTrackingService.updateTargetValues(at: index, weight: weight, reps: reps)
                            }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                setTrackingService.removeSet(at: index)
                            } label: {
                                Label("Delete Set", systemImage: "trash")
                            }
                            
                            if set.completed {
                                Button {
                                    setTrackingService.uncompleteSet(at: index)
                                } label: {
                                    Label("Mark as Incomplete", systemImage: "xmark.circle")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Add set button
            Button(action: {
                setTrackingService.addSet()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Set")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Rest timer (if active)
            if setTrackingService.restTimerService.isActive {
                RestTimerView(timerService: setTrackingService.restTimerService)
            }
            
            // Exercise summary
            exerciseSummary
        }
        .navigationTitle(exercise.exercise?.name ?? "Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setTrackingService.loadSets(for: exercise)
        }
    }
    
    // MARK: - Subviews
    
    /// Exercise header view
    private var exerciseHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.exercise?.name ?? "Exercise")
                    .font(.headline)
                
                if let muscleGroup = exercise.exercise?.primaryMuscleGroup {
                    Text(muscleGroup)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Progress indicator
            VStack(alignment: .trailing) {
                Text("\(setTrackingService.activeSets.filter(\.completed).count)/\(setTrackingService.activeSets.count) Sets")
                    .font(.subheadline)
                
                ProgressView(value: Double(setTrackingService.activeSets.filter(\.completed).count), 
                             total: Double(setTrackingService.activeSets.count))
                    .frame(width: 100)
            }
        }
        .padding(.horizontal)
    }
    
    /// Progression suggestion view
    private func progressionSuggestionView(_ suggestion: ProgressionSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                
                Text("Progression Suggestion")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                // Confidence indicator
                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.2))
                    )
            }
            
            // Suggestion details
            Text(suggestionText(for: suggestion))
                .font(.subheadline)
            
            Text(suggestion.reasoning)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Apply button
            Button(action: {
                setTrackingService.applyProgressionSuggestion(suggestion)
            }) {
                Text("Apply Suggestion")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    /// Exercise summary view
    private var exerciseSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Exercise Summary")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            // Volume
            HStack {
                Text("Total Volume:")
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(Int(setTrackingService.activeSets.totalVolume)) kg")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // Sets completed
            HStack {
                Text("Sets Completed:")
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(setTrackingService.activeSets.filter(\.completed).count) of \(setTrackingService.activeSets.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // Average weight
            HStack {
                Text("Average Weight:")
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(String(format: "%.1f", setTrackingService.activeSets.averageWeight)) kg")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    /// Generates text for a progression suggestion
    private func suggestionText(for suggestion: ProgressionSuggestion) -> String {
        switch suggestion.type {
        case .increaseWeight:
            if let weight = suggestion.newWeight {
                return "Increase weight to \(String(format: "%.1f", weight)) kg"
            }
            return "Increase weight"
            
        case .increaseReps:
            if let reps = suggestion.newReps {
                return "Increase reps to \(reps)"
            }
            return "Increase reps"
            
        case .deload:
            if let weight = suggestion.newWeight {
                return "Reduce weight to \(String(format: "%.1f", weight)) kg"
            }
            return "Reduce weight"
            
        case .maintain:
            return "Maintain current weight and reps"
        }
    }
}

// MARK: - Preview
struct EnhancedExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EnhancedExerciseView(exercise: mockWorkoutExercise())
        }
    }
    
    static func mockWorkoutExercise() -> WorkoutExercise {
        let context = CoreDataManager.shared.context
        let exercise = Exercise(context: context)
        exercise.id = UUID()
        exercise.name = "Barbell Bench Press"
        exercise.primaryMuscleGroup = "Chest"
        
        let workoutExercise = WorkoutExercise(context: context)
        workoutExercise.id = UUID()
        workoutExercise.exercise = exercise
        
        return workoutExercise
    }
}