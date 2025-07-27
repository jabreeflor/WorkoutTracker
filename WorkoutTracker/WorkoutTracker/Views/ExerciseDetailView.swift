import SwiftUI

/// Detailed view for a single exercise with options to configure settings
struct ExerciseDetailView: View {
    // MARK: - Properties
    let exercise: Exercise
    @StateObject private var restTimeResolver = RestTimeResolver.shared
    @State private var showingRestTimeSettings = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Exercise header
                exerciseHeader
                
                // Exercise information
                exerciseInfo
                
                // Settings cards
                settingsCards
                
                // Usage statistics
                if let statistics = getExerciseStatistics() {
                    usageStatistics(statistics)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle(exercise.name ?? "Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRestTimeSettings) {
            ExerciseRestTimeSettingView(exercise: exercise)
        }
    }
    
    // MARK: - Components
    
    /// Exercise header with icon and name
    private var exerciseHeader: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.primaryBlue.opacity(0.15),
                                Color.primaryBlue.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.primaryBlue.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: exerciseIcon)
                    .font(.system(size: 42, weight: .medium))
                    .foregroundColor(.primaryBlue)
            }
            
            // Name and muscle group
            VStack(spacing: 8) {
                Text(exercise.name ?? "Unknown Exercise")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let muscleGroup = exercise.primaryMuscleGroup {
                    Text(muscleGroup)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 16)
    }
    
    /// Exercise information (instructions, equipment, etc.)
    private var exerciseInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Display equipment info if available
            if let equipment = exercise.equipment, !equipment.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Equipment")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(equipment)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            if let equipment = exercise.equipment, !equipment.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Equipment")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(equipment)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    /// Settings cards for exercise configurations
    private var settingsCards: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Rest timer settings card
            Button(action: {
                showingRestTimeSettings = true
            }) {
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    // Text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rest Timer")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            if let exerciseRestTime = restTimeResolver.getExerciseRestTime(for: exercise) {
                                Text("Default: \(RestTimeResolver.formatRestTime(exerciseRestTime))")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            } else {
                                Text("Using global default")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Add more settings cards here in the future
            // Examples: Progression tracking, Notes, etc.
        }
    }
    
    /// Exercise usage statistics
    private func usageStatistics(_ stats: ExerciseStatistics) -> some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // Workouts count
                statCard(
                    title: "Workouts",
                    value: "\(stats.workoutCount)",
                    icon: "calendar",
                    color: .blue
                )
                
                // Last used
                statCard(
                    title: "Last Used",
                    value: stats.lastUsed.map { dateFormatter.string(from: $0) } ?? "Never",
                    icon: "clock",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                // Volume
                statCard(
                    title: "Total Volume",
                    value: String(format: "%.0f kg", stats.totalVolume),
                    icon: "chart.bar.fill",
                    color: .orange
                )
                
                // Best set
                statCard(
                    title: "Best Set",
                    value: String(format: "%.0f kg × %d", stats.bestSet.weight, stats.bestSet.reps),
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
        }
    }
    
    /// Individual stat card
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helpers
    
    /// Get exercise icon based on muscle group
    private var exerciseIcon: String {
        guard let muscleGroup = exercise.primaryMuscleGroup?.lowercased() else {
            return "figure.strengthtraining.traditional"
        }
        
        switch muscleGroup {
        case "chest":
            return "figure.strengthtraining.traditional"
        case "back":
            return "figure.walk"
        case "shoulders":
            return "figure.arms.open"
        case "arms", "biceps", "triceps":
            return "figure.strengthtraining.functional"
        case "legs", "quadriceps", "hamstrings", "calves":
            return "figure.walk"
        case "core", "abs":
            return "figure.core.training"
        case "glutes":
            return "figure.strengthtraining.traditional"
        default:
            return "figure.strengthtraining.traditional"
        }
    }
    
    /// Date formatter for displaying dates
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    /// Get exercise statistics from workout history
    private func getExerciseStatistics() -> ExerciseStatistics? {
        // This would normally query Core Data for actual statistics
        // For now, returning placeholder data
        return ExerciseStatistics(
            workoutCount: 12,
            lastUsed: Date().addingTimeInterval(-7 * 24 * 3600), // 1 week ago
            totalVolume: 3450,
            bestSet: (weight: 80, reps: 8)
        )
    }
}

/// Structure to hold exercise statistics
struct ExerciseStatistics {
    let workoutCount: Int
    let lastUsed: Date?
    let totalVolume: Double
    let bestSet: (weight: Double, reps: Int)
}

#Preview {
    let context = CoreDataManager.shared.context
    let exercise = Exercise(context: context)
    exercise.name = "Barbell Bench Press"
    exercise.primaryMuscleGroup = "Chest"
    // Example instructions (replace with actual data model property)
    // exercise.instructions = "Lie on a flat bench with your feet firmly on the ground. Grip the barbell slightly wider than shoulder-width apart. Lower the barbell to your mid-chest, then press upward until your arms are fully extended."
    exercise.equipment = "Barbell, Bench"
    
    return NavigationView {
        ExerciseDetailView(exercise: exercise)
    }
}
