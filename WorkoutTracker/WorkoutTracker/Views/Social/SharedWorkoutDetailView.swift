import SwiftUI

struct SharedWorkoutDetailView: View {
    let workout: SharedWorkout
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(workout.workoutName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("by \(workout.userName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !workout.caption.isEmpty {
                        Text(workout.caption)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Text("Workout details coming soon...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SharedWorkoutDetailView(workout: SharedWorkout(
        recordID: "test",
        userID: "test",
        userName: "Test User",
        workoutName: "Test Workout",
        workoutDate: Date(),
        duration: 3600,
        caption: "Great workout!",
        shareDate: Date(),
        likesCount: 5,
        commentsCount: 2,
        totalVolume: 1000,
        exerciseCount: 5,
        exercisesData: []
    ))
}