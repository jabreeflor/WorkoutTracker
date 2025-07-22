import SwiftUI

public struct ModernExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedExercises: [WorkoutExerciseData]
    let exercises: [Exercise]
    
    @State private var selectedCategory: MuscleCategory = .chest
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var recentlyUsed: [Exercise] = []
    
    private var muscleCategories: [MuscleCategory] = MuscleCategory.allCases
    
    public init(selectedExercises: Binding<[WorkoutExerciseData]>, exercises: [Exercise]) {
        self._selectedExercises = selectedExercises
        self.exercises = exercises
    }
    
    private var filteredExercises: [Exercise] {
        let categoryExercises = exercises.filter { exercise in
            selectedCategory.muscleGroups.contains { muscleGroup in
                exercise.primaryMuscleGroup?.localizedCaseInsensitiveContains(muscleGroup) == true
            }
        }
        
        if searchText.isEmpty {
            return categoryExercises
        } else {
            return categoryExercises.filter { exercise in
                exercise.name?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search toggle
                headerView
                
                // Category selector - horizontal scroll
                categoryScrollView
                
                // Exercise grid for selected category
                exerciseGridView
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSearch.toggle() }) {
                        Image(systemName: showingSearch ? "magnifyingglass.circle.fill" : "magnifyingglass")
                            .foregroundColor(.blue)
                    }
                }
            }
            .searchable(text: $searchText, isPresented: $showingSearch, prompt: "Search exercises...")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            // Recently used exercises (if any)
            if !recentlyUsed.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.orange)
                        Text("Recently Used")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recentlyUsed.prefix(5), id: \.id) { exercise in
                                RecentExerciseCard(exercise: exercise) {
                                    addExercise(exercise)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Divider()
                    .padding(.horizontal, 20)
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Category Scroll View
    private var categoryScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(muscleCategories, id: \.self) { category in
                        CategoryCard(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground))
            .onChange(of: selectedCategory) { newCategory in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newCategory, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Exercise Grid View
    private var exerciseGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredExercises, id: \.id) { exercise in
                    ExerciseCard(exercise: exercise) {
                        addExercise(exercise)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100) // Extra space at bottom
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedCategory)
    }
    
    // MARK: - Helper Methods
    private func addExercise(_ exercise: Exercise) {
        let workoutExercise = WorkoutExerciseData(exercise: exercise)
        selectedExercises.append(workoutExercise)
        
        // Add to recently used (avoid duplicates)
        recentlyUsed.removeAll { $0.id == exercise.id }
        recentlyUsed.insert(exercise, at: 0)
        recentlyUsed = Array(recentlyUsed.prefix(10)) // Keep max 10
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Dismiss after short delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

// MARK: - Muscle Category Definition
enum MuscleCategory: String, CaseIterable {
    case chest = "Chest"
    case back = "Back" 
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case core = "Core"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.climbing"
        case .shoulders: return "figure.arms.open"
        case .arms: return "figure.boxing"
        case .legs: return "figure.run"
        case .core: return "figure.yoga"
        case .fullBody: return "figure.mixed.cardio"
        case .cardio: return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .shoulders: return .orange
        case .arms: return .purple
        case .legs: return .green
        case .core: return .yellow
        case .fullBody: return .indigo
        case .cardio: return .pink
        }
    }
    
    var muscleGroups: [String] {
        switch self {
        case .chest: return ["Chest", "Upper Chest", "Lower Chest"]
        case .back: return ["Back", "Lower Back", "Upper Back", "Rear Delts"]
        case .shoulders: return ["Shoulders", "Rear Delts"]
        case .arms: return ["Biceps", "Triceps", "Forearms", "Arms"]
        case .legs: return ["Quadriceps", "Hamstrings", "Glutes", "Calves", "Hip Flexors"]
        case .core: return ["Core", "Obliques", "Spine"]
        case .fullBody: return ["Full Body"]
        case .cardio: return ["Cardiovascular"]
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: MuscleCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color : category.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(category.color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? category.color.opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    let exercise: Exercise
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                isPressed = false
            }
        }) {
            VStack(spacing: 0) {
                // Exercise illustration/image area
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            categoryColor.opacity(0.2),
                            categoryColor.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Exercise illustration
                    VStack {
                        Image(systemName: exerciseIllustration)
                            .font(.system(size: 40, weight: .regular))
                            .foregroundColor(categoryColor)
                        
                        // Equipment badge
                        if let equipment = exercise.equipment, !equipment.isEmpty {
                            Text(equipment)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.8))
                                )
                                .foregroundColor(categoryColor)
                        }
                    }
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                
                // Exercise details
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name ?? "Unknown Exercise")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(categoryColor)
                                .frame(width: 6, height: 6)
                            Text(exercise.primaryMuscleGroup ?? "")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(categoryColor)
                        }
                        
                        if let secondary = exercise.secondaryMuscleGroup, !secondary.isEmpty {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.secondary)
                                    .frame(width: 4, height: 4)
                                Text(secondary)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(categoryColor.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: categoryColor.opacity(isPressed ? 0.15 : 0.08),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var exerciseIllustration: String {
        guard let exerciseName = exercise.name?.lowercased() else { return "figure.strengthtraining.traditional" }
        
        // Specific exercise illustrations
        switch exerciseName {
        case let name where name.contains("push-up"): return "figure.core.training"
        case let name where name.contains("pull-up"): return "figure.strengthtraining.functional"
        case let name where name.contains("squat"): return "figure.squat"
        case let name where name.contains("lunge"): return "figure.step.training"
        case let name where name.contains("plank"): return "figure.core.training"
        case let name where name.contains("deadlift"): return "figure.strengthtraining.traditional"
        case let name where name.contains("bench press"): return "figure.strengthtraining.traditional"
        case let name where name.contains("curl"): return "figure.strengthtraining.functional"
        case let name where name.contains("press") && name.contains("shoulder"): return "figure.arms.open"
        case let name where name.contains("row"): return "figure.rower"
        case let name where name.contains("burpee"): return "figure.jump"
        case let name where name.contains("mountain climber"): return "figure.climbing"
        case let name where name.contains("jumping"): return "figure.jump"
        case let name where name.contains("run") || name.contains("cardio"): return "figure.run"
        case let name where name.contains("stretch"): return "figure.flexibility"
        case let name where name.contains("yoga") || name.contains("child"): return "figure.yoga"
        default: return exerciseIconByMuscleGroup
        }
    }
    
    private var exerciseIconByMuscleGroup: String {
        guard let muscleGroup = exercise.primaryMuscleGroup?.lowercased() else { return "figure.strengthtraining.traditional" }
        
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
    
    private var exerciseIcon: String {
        guard let equipment = exercise.equipment else { return "dumbbell" }
        
        switch equipment.lowercased() {
        case "barbell": return "dumbbell.fill"
        case "dumbbell": return "dumbbell"
        case "cable": return "cable.connector"
        case "machine": return "gearshape.fill"
        case "bodyweight": return "figure.walk"
        default: return "dumbbell"
        }
    }
    
    private var categoryColor: Color {
        guard let primary = exercise.primaryMuscleGroup else { return .blue }
        
        for category in MuscleCategory.allCases {
            if category.muscleGroups.contains(where: { primary.contains($0) }) {
                return category.color
            }
        }
        return .blue
    }
}

// MARK: - Recent Exercise Card
struct RecentExerciseCard: View {
    let exercise: Exercise
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: exerciseIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                
                Text(exercise.name ?? "")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var exerciseIcon: String {
        guard let equipment = exercise.equipment else { return "dumbbell" }
        
        switch equipment.lowercased() {
        case "barbell": return "dumbbell.fill"
        case "dumbbell": return "dumbbell"
        case "cable": return "cable.connector"
        case "machine": return "gearshape.fill"
        case "bodyweight": return "figure.walk"
        default: return "dumbbell"
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedExercises: [WorkoutExerciseData] = []
        
        var body: some View {
            ModernExerciseSelectionView(
                selectedExercises: $selectedExercises,
                exercises: []
            )
        }
    }
    
    return PreviewWrapper()
}