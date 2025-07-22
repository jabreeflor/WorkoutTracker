import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: false)],
        animation: .default
    ) private var workoutSessions: FetchedResults<WorkoutSession>
    
    @State private var selectedWorkout: WorkoutSession?
    
    var body: some View {
        NavigationView {
            VStack {
                if workoutSessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No workouts yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Complete your first workout to see it here!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    Spacer()
                } else {
                    List(workoutSessions, id: \.id) { workout in
                        WorkoutHistoryRow(workout: workout)
                            .onTapGesture {
                                selectedWorkout = workout
                            }
                    }
                }
            }
            .navigationTitle("History")
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailView(workout: workout)
            }
        }
    }
}

struct WorkoutHistoryRow: View {
    let workout: WorkoutSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.name ?? "Unnamed Workout")
                    .font(.headline)
                
                Spacer()
                
                Text(workout.date ?? Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(formatDuration(workout.duration))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("\(workout.exercises?.count ?? 0) exercises")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if let exercises = workout.exercises?.allObjects as? [WorkoutExercise], !exercises.isEmpty {
                HStack {
                    Text("Exercises:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(exercises.compactMap { $0.exercise?.name }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ seconds: Int32) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    HistoryView()
}

#Preview {
    HistoryView()
}