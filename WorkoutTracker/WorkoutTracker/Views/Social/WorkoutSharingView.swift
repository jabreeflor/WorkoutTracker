import SwiftUI

struct WorkoutSharingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Share Workout")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Share your workout with the community!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Coming soon...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Share Workout")
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
    WorkoutSharingView()
}