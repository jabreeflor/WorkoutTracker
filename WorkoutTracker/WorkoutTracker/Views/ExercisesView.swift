import SwiftUI
import CoreData

struct ExercisesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)],
        animation: .default
    ) private var exercises: FetchedResults<Exercise>
    
    @State private var searchText = ""
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return Array(exercises)
        } else {
            return exercises.filter { exercise in
                exercise.name?.localizedCaseInsensitiveContains(searchText) == true ||
                exercise.primaryMuscleGroup?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Modern search bar
                VStack {
                    ModernSearchBar(text: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                }
                .background(Color(.systemGroupedBackground))
                
                // Exercise list with modern cards
                if filteredExercises.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredExercises, id: \.id) { exercise in
                                ModernExerciseCard(exercise: exercise)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No exercises found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No exercises available" : "Try adjusting your search")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct ModernSearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isEditing ? .primaryBlue : .secondary)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isEditing)
            
            // Text field
            TextField("Search exercises...", text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .onTapGesture {
                    isEditing = true
                }
                .onSubmit {
                    isEditing = false
                }
                .onChange(of: text) { _, _ in
                    if !text.isEmpty {
                        isEditing = true
                    }
                }
            
            // Clear button
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    isEditing = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: !text.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEditing ? Color.primaryBlue : Color.gray.opacity(0.2), lineWidth: 2)
                )
        )
        .glowEffect(isActive: isEditing, color: .primaryBlue, radius: 8)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isEditing)
    }
}

struct ModernExerciseCard: View {
    let exercise: Exercise
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
            HStack(spacing: 16) {
                // Exercise icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.primaryBlue.opacity(0.1),
                                    Color.primaryBlue.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.primaryBlue.opacity(0.2), lineWidth: 2)
                        )
                    
                    Image(systemName: exerciseIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.primaryBlue)
                }
                
                // Exercise details
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name ?? "Unknown Exercise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let muscleGroup = exercise.primaryMuscleGroup {
                        Text(muscleGroup)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Exercise type indicator
                    HStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.caption)
                            .foregroundColor(.primaryBlue)
                        
                        Text(exerciseType)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.primaryBlue.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .cardShadow(isPressed: isPressed)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isPressed)
        .bouncyPress(
            scale: 0.98,
            hapticFeedback: true,
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .accessibilityLabel("\(exercise.name ?? "Exercise"), \(exercise.primaryMuscleGroup ?? "Unknown muscle group")")
    }
    
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
            return "figure.strengthtraining.functional"
        default:
            return "figure.strengthtraining.traditional"
        }
    }
    
    private var exerciseType: String {
        // This could be enhanced based on exercise data
        return "Strength"
    }
}

#Preview {
    ExercisesView()
}