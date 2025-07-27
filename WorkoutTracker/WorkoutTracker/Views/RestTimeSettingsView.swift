import SwiftUI
import CoreData

/// A centralized view for managing all rest time settings across the app
struct RestTimeSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var restTimeResolver = RestTimeResolver.shared
    @EnvironmentObject private var hapticService: HapticService
    
    // State for global rest time
    @State private var globalRestTime: Int
    
    // State for bulk editing
    @State private var isSelectingExercises = false
    @State private var selectedExercises = Set<Exercise>()
    @State private var showingBulkEditSheet = false
    @State private var bulkEditRestTime: Int = 90
    
    // State for search and filtering
    @State private var searchText = ""
    @State private var sortOption: SortOption = .name
    @State private var filterOption: FilterOption = .all
    
    // State for import/export
    @State private var showingImportExportView = false
    
    // Fetched exercises
    @FetchRequest(
        entity: Exercise.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
    ) var exercises: FetchedResults<Exercise>
    
    // Filtered exercises based on search text and filter options
    private var filteredExercises: [Exercise] {
        let filtered = exercises.filter { exercise in
            if searchText.isEmpty {
                return true
            }
            return exercise.name?.localizedCaseInsensitiveContains(searchText) == true
        }
        
        // Apply filter
        let filtered2 = filtered.filter { exercise in
            switch filterOption {
            case .all:
                return true
            case .withCustomRestTime:
                return restTimeResolver.getExerciseRestTime(for: exercise) != nil
            case .withoutCustomRestTime:
                return restTimeResolver.getExerciseRestTime(for: exercise) == nil
            }
        }
        
        // Apply sort
        return filtered2.sorted { a, b in
            switch sortOption {
            case .name:
                return (a.name ?? "") < (b.name ?? "")
            case .muscleGroup:
                return (a.primaryMuscleGroup ?? "") < (b.primaryMuscleGroup ?? "")
            case .restTime:
                let aTime = restTimeResolver.getExerciseRestTime(for: a) ?? restTimeResolver.getGlobalDefaultRestTime()
                let bTime = restTimeResolver.getExerciseRestTime(for: b) ?? restTimeResolver.getGlobalDefaultRestTime()
                return aTime < bTime
            }
        }
    }
    
    init() {
        // Initialize with the current global rest time
        _globalRestTime = State(initialValue: RestTimeResolver.shared.getGlobalDefaultRestTime())
    }
    
    var body: some View {
        NavigationView {
            List {
                // Global rest time section
                Section(header: Text("Global Default Rest Time")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This is the default rest time used when no exercise or set-specific rest time is set.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Global Default:")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(RestTimeResolver.formatRestTime(globalRestTime))
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Slider(value: Binding<Double>(
                            get: { Double(globalRestTime) },
                            set: { 
                                let newValue = Int($0)
                                if newValue != globalRestTime {
                                    globalRestTime = newValue
                                    restTimeResolver.setGlobalDefaultRestTime(newValue)
                                    hapticService.provideFeedback(for: .impact(.light))
                                }
                            }
                        ), in: 30...300, step: 15)
                        
                        HStack {
                            Text("30s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("5m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Rest time hierarchy explanation
                Section(header: Text("Rest Time Hierarchy")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HierarchyExplanationRow(
                            level: "1. Set-Specific",
                            description: "Highest priority. Set on individual sets.",
                            color: RestTimeSource.setSpecific.color
                        )
                        
                        HierarchyExplanationRow(
                            level: "2. Exercise Default",
                            description: "Used when a set has no specific rest time.",
                            color: RestTimeSource.exerciseSpecific.color
                        )
                        
                        HierarchyExplanationRow(
                            level: "3. Global Default",
                            description: "Used when no other rest times are set.",
                            color: RestTimeSource.globalDefault.color
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                // Exercise-specific rest times
                Section(header: exerciseListHeader) {
                    if filteredExercises.isEmpty {
                        Text("No exercises match the current filters")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(filteredExercises, id: \.objectID) { exercise in
                            ExerciseRestTimeRow(
                                exercise: exercise,
                                isSelected: selectedExercises.contains(exercise),
                                isSelectionMode: isSelectingExercises
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelectingExercises {
                                    toggleExerciseSelection(exercise)
                                } else {
                                    navigateToExerciseSettings(exercise)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Rest Time Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSelectingExercises {
                        Button(action: {
                            isSelectingExercises = false
                            selectedExercises.removeAll()
                        }) {
                            Text("Cancel")
                        }
                    } else {
                        Menu {
                            Button(action: {
                                isSelectingExercises = true
                            }) {
                                Label("Select Exercises", systemImage: "checkmark.circle")
                            }
                            
                            Menu {
                                Picker("Sort by", selection: $sortOption) {
                                    ForEach(SortOption.allCases, id: \.self) { option in
                                        Text(option.label).tag(option)
                                    }
                                }
                            } label: {
                                Label("Sort", systemImage: "arrow.up.arrow.down")
                            }
                            
                            Menu {
                                Picker("Filter", selection: $filterOption) {
                                    ForEach(FilterOption.allCases, id: \.self) { option in
                                        Text(option.label).tag(option)
                                    }
                                }
                            } label: {
                                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            }
                            
                            Button(action: {
                                showingImportExportView = true
                            }) {
                                Label("Import/Export", systemImage: "square.and.arrow.up.on.square")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectingExercises && !selectedExercises.isEmpty {
                        Button(action: {
                            showingBulkEditSheet = true
                        }) {
                            Text("Edit \(selectedExercises.count)")
                                .bold()
                        }
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if isSelectingExercises {
                        HStack {
                            Button(action: {
                                selectAllExercises()
                            }) {
                                Text("Select All")
                            }
                            
                            Spacer()
                            
                            if !selectedExercises.isEmpty {
                                Button(action: {
                                    clearSelectedExercisesRestTimes()
                                }) {
                                    Text("Clear Rest Times")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingBulkEditSheet) {
                BulkRestTimeEditView(
                    exercises: Array(selectedExercises),
                    onApply: { newRestTime in
                        applyBulkRestTime(newRestTime)
                        showingBulkEditSheet = false
                    }
                )
            }
            .sheet(isPresented: $showingImportExportView) {
                RestTimeImportExportView()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var exerciseListHeader: some View {
        HStack {
            Text("Exercise Default Rest Times")
            
            Spacer()
            
            if !isSelectingExercises {
                Text("\(filteredExercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Actions
    
    private func navigateToExerciseSettings(_ exercise: Exercise) {
        hapticService.provideFeedback(for: .selection)
        // Navigate to exercise settings
        // In a real implementation, this would use NavigationLink
    }
    
    private func toggleExerciseSelection(_ exercise: Exercise) {
        if selectedExercises.contains(exercise) {
            selectedExercises.remove(exercise)
        } else {
            selectedExercises.insert(exercise)
        }
        hapticService.provideFeedback(for: .selection)
    }
    
    private func selectAllExercises() {
        if selectedExercises.count == filteredExercises.count {
            // If all are selected, deselect all
            selectedExercises.removeAll()
        } else {
            // Otherwise select all
            selectedExercises = Set(filteredExercises)
        }
        hapticService.provideFeedback(for: .impact(.medium))
    }
    
    private func clearSelectedExercisesRestTimes() {
        for exercise in selectedExercises {
            restTimeResolver.setExerciseRestTime(for: exercise, seconds: nil)
        }
        hapticService.provideFeedback(for: .success)
        selectedExercises.removeAll()
        isSelectingExercises = false
    }
    
    private func applyBulkRestTime(_ restTime: Int) {
        for exercise in selectedExercises {
            restTimeResolver.setExerciseRestTime(for: exercise, seconds: restTime)
        }
        hapticService.provideFeedback(for: .success)
        selectedExercises.removeAll()
        isSelectingExercises = false
    }
}

// MARK: - Supporting Views

/// A row that explains a level in the rest time hierarchy
struct HierarchyExplanationRow: View {
    let level: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(level)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// A row showing an exercise and its rest time setting
struct ExerciseRestTimeRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let isSelectionMode: Bool
    @StateObject private var restTimeResolver = RestTimeResolver.shared
    
    var body: some View {
        HStack {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
                    .animation(.spring(), value: isSelected)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name ?? "Unknown Exercise")
                    .font(.body)
                    .fontWeight(.medium)
                
                if let muscleGroup = exercise.primaryMuscleGroup {
                    Text(muscleGroup)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let exerciseRestTime = restTimeResolver.getExerciseRestTime(for: exercise) {
                Text(RestTimeResolver.formatRestTime(exerciseRestTime))
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(6)
            } else {
                Text("Global")
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.gray)
                    .cornerRadius(6)
            }
            
            if !isSelectionMode {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Bulk Edit View

/// View for editing rest time for multiple exercises at once
struct BulkRestTimeEditView: View {
    let exercises: [Exercise]
    let onApply: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedOption: RestTimePreset?
    @State private var customTime: Int = 90
    @State private var showingCustomPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Bulk Edit Rest Times")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Set rest time for \(exercises.count) selected exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Preset options
                List {
                    Section("Quick Options") {
                        ForEach(RestTimeResolver.commonRestTimes, id: \.id) { option in
                            RestTimeOptionRow(
                                label: "\(option.label) - \(option.description)",
                                seconds: option.seconds,
                                isSelected: selectedOption?.seconds == option.seconds
                            ) {
                                selectedOption = option
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
                                
                                if let selectedOption = selectedOption,
                                   !RestTimeResolver.commonRestTimes.contains(where: { $0.seconds == selectedOption.seconds }) {
                                    Text(RestTimeResolver.formatRestTime(selectedOption.seconds))
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
                
                // Apply button
                if let selectedOption = selectedOption {
                    Button(action: {
                        onApply(selectedOption.seconds)
                    }) {
                        Text("Apply to \(exercises.count) Exercises")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustomPicker) {
                CustomRestTimePickerView(
                    customTime: $customTime,
                    onSave: { time in
                        // Create a custom preset
                        selectedOption = RestTimePreset(
                            seconds: time,
                            label: RestTimeResolver.formatRestTime(time),
                            description: "Custom"
                        )
                        showingCustomPicker = false
                    }
                )
            }
        }
    }
}

// MARK: - Enums

enum SortOption: String, CaseIterable {
    case name
    case muscleGroup
    case restTime
    
    var label: String {
        switch self {
        case .name:
            return "Name"
        case .muscleGroup:
            return "Muscle Group"
        case .restTime:
            return "Rest Time"
        }
    }
}

enum FilterOption: String, CaseIterable {
    case all
    case withCustomRestTime
    case withoutCustomRestTime
    
    var label: String {
        switch self {
        case .all:
            return "All Exercises"
        case .withCustomRestTime:
            return "Custom Rest Time"
        case .withoutCustomRestTime:
            return "Global Rest Time"
        }
    }
}

// MARK: - Preview

struct RestTimeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        RestTimeSettingsView()
            .environmentObject(HapticService.shared)
    }
}
