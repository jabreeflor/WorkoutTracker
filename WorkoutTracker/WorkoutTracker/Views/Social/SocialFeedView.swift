import SwiftUI

struct SocialFeedView: View {
    @StateObject private var socialService = SocialFeaturesService.shared
    @StateObject private var authService = UserAuthenticationService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var sharedWorkouts: [SharedWorkout] = []
    @State private var isLoadingFeed = false
    @State private var showingShareWorkout = false
    @State private var selectedWorkout: SharedWorkout?
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoadingFeed {
                        ForEach(0..<3) { _ in
                            SharedWorkoutCardSkeleton()
                        }
                    } else if sharedWorkouts.isEmpty {
                        emptyFeedView
                    } else {
                        ForEach(sharedWorkouts) { workout in
                            SharedWorkoutFeedCard(
                                workout: workout,
                                onLike: { likeWorkout(workout) },
                                onComment: { showWorkoutDetail(workout) },
                                onShare: { shareWorkout(workout) }
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Social Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingShareWorkout = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .refreshable {
                await loadFeed()
            }
            .task {
                await loadFeed()
            }
            .sheet(isPresented: $showingShareWorkout) {
                WorkoutSharingView()
            }
            .sheet(item: $selectedWorkout) { workout in
                SharedWorkoutDetailView(workout: workout)
            }
        }
    }
    
    // MARK: - Empty Feed View
    
    private var emptyFeedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Your Feed is Empty")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Follow other users to see their workout shares in your feed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                NavigationLink(destination: UserDiscoveryView()) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("Discover Users")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button("Share Your First Workout") {
                    showingShareWorkout = true
                }
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func loadFeed() async {
        isLoadingFeed = true
        
        do {
            // Load public shared workouts
            let workouts = try await socialService.getSharedWorkouts(limit: 50)
            
            DispatchQueue.main.async {
                self.sharedWorkouts = workouts
                self.isLoadingFeed = false
                self.refreshID = UUID()
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoadingFeed = false
            }
            print("Error loading feed: \(error)")
        }
    }
    
    private func likeWorkout(_ workout: SharedWorkout) {
        Task {
            do {
                try await socialService.likeSharedWorkout(workout.recordID)
                // Refresh the specific workout or the entire feed
                await loadFeed()
            } catch {
                print("Error liking workout: \(error)")
            }
        }
    }
    
    private func showWorkoutDetail(_ workout: SharedWorkout) {
        selectedWorkout = workout
    }
    
    private func shareWorkout(_ workout: SharedWorkout) {
        // Implement sharing functionality (native iOS share sheet)
        let shareText = "Check out this workout by \(workout.userName): \(workout.workoutName)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Shared Workout Feed Card

struct SharedWorkoutFeedCard: View {
    let workout: SharedWorkout
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User Header
            HStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(workout.userName.prefix(2).uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(workout.shareDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onShare) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // Workout Content
            VStack(alignment: .leading, spacing: 12) {
                // Workout Title and Stats
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.workoutName)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            statItem(icon: "clock.fill", value: formatDuration(workout.duration), color: .blue)
                            statItem(icon: "list.bullet", value: "\(workout.exerciseCount) exercises", color: .green)
                            if workout.totalVolume > 0 {
                                statItem(icon: "scalemass.fill", value: "\(Int(workout.totalVolume))", color: .purple)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Caption
                if !workout.caption.isEmpty {
                    Text(workout.caption)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Exercise Summary
                if !workout.exercisesData.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercises")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(Array(workout.exercisesData.prefix(4)), id: \.name) { exercise in
                                exerciseChip(exercise: exercise)
                            }
                        }
                        
                        if workout.exercisesData.count > 4 {
                            Text("+ \(workout.exercisesData.count - 4) more exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .onTapGesture {
                                    onComment() // Show full workout detail
                                }
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
            
            // Interaction Buttons
            HStack(spacing: 24) {
                interactionButton(
                    icon: isLiked ? "heart.fill" : "heart",
                    text: "\(workout.likesCount)",
                    color: isLiked ? .red : .secondary,
                    action: {
                        isLiked.toggle()
                        onLike()
                    }
                )
                
                interactionButton(
                    icon: "bubble.left",
                    text: "\(workout.commentsCount)",
                    color: .secondary,
                    action: onComment
                )
                
                interactionButton(
                    icon: "square.and.arrow.up",
                    text: "Share",
                    color: .secondary,
                    action: onShare
                )
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func statItem(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private func exerciseChip(exercise: SharedExerciseData) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text("\(exercise.sets) sets • \(exercise.totalReps) reps")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
    
    private func interactionButton(icon: String, text: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ seconds: Int32) -> String {
        let minutes = seconds / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Skeleton Loading View

struct SharedWorkoutCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User Header Skeleton
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 14)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 12)
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            // Content Skeleton
            VStack(alignment: .leading, spacing: 12) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 18)
                    .cornerRadius(4)
                
                HStack(spacing: 16) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 12)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 12)
                        .cornerRadius(4)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 80)
                    .cornerRadius(12)
            }
            
            // Interaction Buttons Skeleton
            HStack(spacing: 24) {
                ForEach(0..<3) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 12)
                        .cornerRadius(4)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SocialFeedView()
}