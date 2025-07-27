import SwiftUI

/// View for configuring exercise-specific rest time settings
struct ExerciseRestTimeSettingView: View {
    // MARK: - Properties
    let exercise: Exercise
    @State private var showingRestTimePicker = false
    @StateObject private var restTimeResolver = RestTimeResolver.shared
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text(exercise.name ?? "Exercise")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let muscleGroup = exercise.primaryMuscleGroup {
                    Text(muscleGroup)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Rest Time Info
            VStack(spacing: 12) {
                Text("Default Rest Time")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    if let exerciseRestTime = restTimeResolver.getExerciseRestTime(for: exercise) {
                        Text(RestTimeResolver.formatRestTime(exerciseRestTime))
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    } else {
                        Text("Global Default")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Explanation text
                Text("This rest time will be used for all sets of this exercise unless a set has its own specific rest time configured.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    showingRestTimePicker = true
                }) {
                    Text("Change Rest Time")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                if restTimeResolver.getExerciseRestTime(for: exercise) != nil {
                    Button(action: {
                        restTimeResolver.setExerciseRestTime(for: exercise, seconds: nil)
                    }) {
                        Text("Reset to Global Default")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.red)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .sheet(isPresented: $showingRestTimePicker) {
            ExerciseRestTimePickerView(
                exercise: exercise,
                currentRestTime: restTimeResolver.getExerciseRestTime(for: exercise)
            )
        }
    }
}

/// View for picking a new rest time for an exercise
struct ExerciseRestTimePickerView: View {
    // MARK: - Properties
    let exercise: Exercise
    let currentRestTime: Int?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var restTimeResolver = RestTimeResolver.shared
    
    @State private var selectedRestTime: Int?
    @State private var customTime: Int = 60
    @State private var showingCustomPicker = false
    
    // MARK: - Initialization
    init(exercise: Exercise, currentRestTime: Int?) {
        self.exercise = exercise
        self.currentRestTime = currentRestTime
        self._selectedRestTime = State(initialValue: currentRestTime)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Set Rest Time for")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(exercise.name ?? "Exercise")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Preset options
                List {
                    Section("Quick Options") {
                        ForEach(RestTimeResolver.commonRestTimes, id: \.id) { option in
                            ExerciseRestTimeOptionRow(
                                label: "\(option.label) - \(option.description)",
                                seconds: option.seconds,
                                isSelected: selectedRestTime == option.seconds
                            ) {
                                selectedRestTime = option.seconds
                                HapticService.shared.provideFeedback(for: .selection)
                            }
                        }
                    }
                    
                    Section("Custom Time") {
                        Button(action: {
                            showingCustomPicker = true
                        }) {
                            HStack {
                                Image(systemName: "clock.badge.plus")
                                    .foregroundColor(.blue)
                                
                                Text("Custom Time")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if let customSeconds = selectedRestTime,
                                   !RestTimeResolver.commonRestTimes.contains(where: { $0.seconds == customSeconds }) {
                                    Text(RestTimeResolver.formatRestTime(customSeconds))
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        restTimeResolver.setExerciseRestTime(for: exercise, seconds: selectedRestTime)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCustomPicker) {
                CustomRestTimePickerView(
                    customTime: Binding(
                        get: { selectedRestTime ?? customTime },
                        set: { 
                            customTime = $0
                            selectedRestTime = $0
                        }
                    ),
                    onSave: { newTime in
                        customTime = newTime
                        selectedRestTime = newTime
                        showingCustomPicker = false
                    }
                )
            }
        }
    }
}

/// A row representing a rest time option
struct ExerciseRestTimeOptionRow: View {
    let label: String
    let seconds: Int?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(label)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .listRowBackground(isSelected ? Color.blue.opacity(0.05) : Color.clear)
    }
}

#Preview {
    let context = CoreDataManager.shared.context
    let exercise = Exercise(context: context)
    exercise.name = "Barbell Bench Press"
    exercise.primaryMuscleGroup = "Chest"
    
    return ExerciseRestTimeSettingView(exercise: exercise)
}
