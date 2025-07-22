import SwiftUI
import CoreData

struct TemplateBuilderView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)],
        animation: .default
    ) private var exercises: FetchedResults<Exercise>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Folder.name, ascending: true)],
        animation: .default
    ) private var folders: FetchedResults<Folder>
    
    @State private var templateName = ""
    @State private var selectedFolder: Folder?
    @State private var templateExercises: [TemplateExerciseData] = []
    @State private var showingExerciseSelection = false
    @State private var defaultRestTime: Int = 60
    @State private var templateNotes = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Template Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Template Details")
                            .font(.headline)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Template Name")
                                .font(.subheadline)
                                .bold()
                            TextField("Enter template name", text: $templateName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Folder")
                                .font(.subheadline)
                                .bold()
                            
                            Picker("Select Folder", selection: $selectedFolder) {
                                Text("No Folder").tag(nil as Folder?)
                                ForEach(folders, id: \.id) { folder in
                                    Text(folder.name ?? "Unnamed Folder").tag(folder as Folder?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Default Rest Time")
                                .font(.subheadline)
                                .bold()
                            
                            HStack {
                                Stepper(value: $defaultRestTime, in: 30...300, step: 15) {
                                    Text("\(defaultRestTime) seconds")
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.subheadline)
                                .bold()
                            TextField("Template notes...", text: $templateNotes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(2...4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Exercises Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Exercises")
                                .font(.headline)
                                .bold()
                            
                            Spacer()
                            
                            Button(action: {
                                showingExerciseSelection = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        if templateExercises.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "dumbbell")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No exercises added yet")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Tap 'Add Exercise' to build your template")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 20)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(templateExercises.indices, id: \.self) { index in
                                    TemplateExerciseRow(
                                        exerciseData: $templateExercises[index],
                                        onDelete: {
                                            templateExercises.remove(at: index)
                                            updateExerciseOrder()
                                        },
                                        onMoveUp: index > 0 ? {
                                            templateExercises.swapAt(index, index - 1)
                                            updateExerciseOrder()
                                        } : nil,
                                        onMoveDown: index < templateExercises.count - 1 ? {
                                            templateExercises.swapAt(index, index + 1)
                                            updateExerciseOrder()
                                        } : nil
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    
                    // Save Button
                    Button(action: saveTemplate) {
                        Text("Create Template")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(canSaveTemplate ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!canSaveTemplate)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExerciseSelection) {
                TemplateExerciseSelectionView(
                    selectedExercises: $templateExercises,
                    exercises: Array(exercises)
                )
            }
        }
    }
    
    private var canSaveTemplate: Bool {
        !templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !templateExercises.isEmpty
    }
    
    private func updateExerciseOrder() {
        for (index, _) in templateExercises.enumerated() {
            templateExercises[index].orderIndex = index
        }
    }
    
    private func saveTemplate() {
        let template = WorkoutTemplate(context: viewContext)
        template.id = UUID()
        template.name = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        template.createdDate = Date()
        template.lastModifiedDate = Date()
        template.folder = selectedFolder
        template.defaultRestTime = Int32(defaultRestTime)
        template.notes = templateNotes.isEmpty ? nil : templateNotes
        
        for exerciseData in templateExercises {
            let templateExercise = TemplateExercise(context: viewContext)
            templateExercise.id = UUID()
            templateExercise.exercise = exerciseData.exercise
            templateExercise.template = template
            templateExercise.orderIndex = Int32(exerciseData.orderIndex)
            templateExercise.defaultSets = Int32(exerciseData.sets)
            templateExercise.defaultReps = Int32(exerciseData.reps)
            templateExercise.defaultWeight = exerciseData.weight
            templateExercise.restTime = Int32(exerciseData.restTime)
            templateExercise.notes = exerciseData.notes
        }
        
        do {
            try viewContext.save()
            HapticService.shared.templateCreated()
            dismiss()
        } catch {
            print("Error saving template: \(error)")
            HapticService.shared.error()
        }
    }
}

struct TemplateExerciseData {
    let exercise: Exercise
    var sets: Int = 3
    var reps: Int = 10
    var weight: Double = 0.0
    var restTime: Int = 60
    var notes: String = ""
    var orderIndex: Int = 0
    
    init(exercise: Exercise, orderIndex: Int = 0) {
        self.exercise = exercise
        self.orderIndex = orderIndex
    }
}

struct TemplateExerciseRow: View {
    @Binding var exerciseData: TemplateExerciseData
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    @State private var showingNotes = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseData.exercise.name ?? "Unknown Exercise")
                        .font(.subheadline)
                        .bold()
                    
                    Text("Primary: \(exerciseData.exercise.primaryMuscleGroup ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Move buttons
                    VStack(spacing: 4) {
                        if let moveUp = onMoveUp {
                            Button(action: moveUp) {
                                Image(systemName: "chevron.up")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let moveDown = onMoveDown {
                            Button(action: moveDown) {
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Exercise Parameters
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Stepper(value: $exerciseData.sets, in: 1...20) {
                        Text("\(exerciseData.sets)")
                            .font(.subheadline)
                            .bold()
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Stepper(value: $exerciseData.reps, in: 1...100) {
                        Text("\(exerciseData.reps)")
                            .font(.subheadline)
                            .bold()
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Weight", value: $exerciseData.weight, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
            }
            
            // Rest Time and Notes
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest Time")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Stepper(value: $exerciseData.restTime, in: 30...300, step: 15) {
                        Text("\(exerciseData.restTime)s")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingNotes = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: exerciseData.notes.isEmpty ? "note" : "note.text")
                            .font(.caption)
                        Text("Notes")
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .sheet(isPresented: $showingNotes) {
            TemplateExerciseNotesView(notes: $exerciseData.notes)
        }
    }
}

struct TemplateExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedExercises: [TemplateExerciseData]
    let exercises: [Exercise]
    @State private var searchText = ""
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { exercise in
                exercise.name?.localizedCaseInsensitiveContains(searchText) == true ||
                exercise.primaryMuscleGroup?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List(filteredExercises, id: \.id) { exercise in
                    Button(action: {
                        addExercise(exercise)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name ?? "Unknown Exercise")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Text("Primary: \(exercise.primaryMuscleGroup ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addExercise(_ exercise: Exercise) {
        let templateExercise = TemplateExerciseData(
            exercise: exercise,
            orderIndex: selectedExercises.count
        )
        selectedExercises.append(templateExercise)
        dismiss()
    }
}

struct TemplateExerciseNotesView: View {
    @Binding var notes: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Exercise Notes")
                    .font(.headline)
                
                TextField("Add notes for this exercise...", text: $notes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .lineLimit(3...6)
                
                Text("Examples: \"Warm up with light weight\", \"Focus on form\", \"Increase weight next week\"")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Exercise Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

#Preview {
    TemplateBuilderView()
}