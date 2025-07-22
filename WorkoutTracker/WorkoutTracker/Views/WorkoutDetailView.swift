import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let workout: WorkoutSession
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Workout Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(workout.name ?? "Unnamed Workout")
                            .font(.title)
                            .bold()
                        
                        HStack {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text(workout.date ?? Date(), formatter: detailDateFormatter)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                Text(formatDuration(workout.duration))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Exercises
                    if let exercises = workout.exercises?.allObjects as? [WorkoutExercise], !exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exercises")
                                .font(.headline)
                                .bold()
                            
                            ForEach(exercises, id: \.id) { exercise in
                                WorkoutExerciseDetailRow(exercise: exercise)
                            }
                        }
                        .padding()
                    } else {
                        VStack {
                            Image(systemName: "dumbbell")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No exercises recorded")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Save as Template") {
                        saveAsTemplate()
                    }
                    .font(.caption)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Int32) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private func saveAsTemplate() {
        let _ = TemplateService.shared.createTemplateFromWorkout(workout)
        
        // Show success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

struct WorkoutExerciseDetailRow: View {
    let exercise: WorkoutExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exercise?.name ?? "Unknown Exercise")
                .font(.headline)
            
            if let primaryMuscle = exercise.exercise?.primaryMuscleGroup {
                Text("Primary: \(primaryMuscle)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(exercise.sets)")
                        .font(.title3)
                        .bold()
                }
                
                VStack(alignment: .leading) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(exercise.reps)")
                        .font(.title3)
                        .bold()
                }
                
                VStack(alignment: .leading) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f lbs", exercise.weight))
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}


private let detailDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    let context = CoreDataManager.shared.context
    let workout = WorkoutSession(context: context)
    workout.name = "Test Workout"
    workout.date = Date()
    workout.duration = 3600
    
    return WorkoutDetailView(workout: workout)
}