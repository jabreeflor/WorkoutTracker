import SwiftUI

struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedExercises: [WorkoutExerciseData]
    let exercises: [Exercise]
    @State private var searchText = ""
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { exercise in
                exercise.name?.localizedCaseInsensitiveContains(searchText) == true ||
                exercise.primaryMuscleGroup?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List(filteredExercises, id: \.id) { exercise in
                    Button(action: {
                        addExercise(exercise)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name ?? "Unknown Exercise")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("Primary: \(exercise.primaryMuscleGroup ?? "Unknown")")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Text(exercise.equipment ?? "Unknown")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            if let secondary = exercise.secondaryMuscleGroup, !secondary.isEmpty {
                                Text("Secondary: \(secondary)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addExercise(_ exercise: Exercise) {
        let workoutExercise = WorkoutExerciseData(exercise: exercise)
        selectedExercises.append(workoutExercise)
        dismiss()
    }
}

#Preview {
    ExerciseSelectionView(selectedExercises: Binding.constant([]), exercises: [])
}