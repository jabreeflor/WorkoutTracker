import SwiftUI
import UIKit

struct SetRowView: View {
    // MARK: - Properties
    let set: SetData
    let previousSet: SetData?
    let isActive: Bool
    let onComplete: (Double, Int) -> Void
    let onUpdate: (Double, Int) -> Void
    
    // MARK: - State
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @State private var isEditing: Bool = false
    
    // MARK: - Initialization
    init(
        set: SetData,
        previousSet: SetData? = nil,
        isActive: Bool = false,
        onComplete: @escaping (Double, Int) -> Void,
        onUpdate: @escaping (Double, Int) -> Void
    ) {
        self.set = set
        self.previousSet = previousSet
        self.isActive = isActive
        self.onComplete = onComplete
        self.onUpdate = onUpdate
        
        // Initialize input fields with current values
        _weightInput = State(initialValue: String(format: "%.1f", set.targetWeight))
        _repsInput = State(initialValue: "\(set.targetReps)")
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 16) {
            // Set number with clean circle background
            ZStack {
                Circle()
                    .fill(set.completed ? Color.green.opacity(0.15) : Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text("\(set.setNumber)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(set.completed ? .green : .blue)
            }
            
            // Target values with cleaner layout
            VStack(alignment: .leading, spacing: 4) {
                Text("Target")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.1f", set.targetWeight))kg × \(set.targetReps)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Action area - cleaner design
            if set.completed {
                // Show completed status
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("\(String(format: "%.1f", set.actualWeight))kg × \(set.actualReps)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
            } else {
                // Start Set button with modern design
                Button(action: { isEditing = true }) {
                    Text("Start Set")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
            }
            
            // Completion status indicator
            Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(set.completed ? .green : .secondary)
                .font(.system(size: 24))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(set.completed ? Color.green.opacity(0.3) : Color.blue.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $isEditing) {
            SetEditSheet(
                set: set,
                onComplete: { weight, reps in
                    onComplete(weight, reps)
                    isEditing = false
                }
            )
            .presentationDetents([.height(300)])
        }
    }
    
    // MARK: - Helper Methods
    
    
    /// Completes the set with the entered values
    private func completeSet() {
        guard let weight = Double(weightInput),
              let reps = Int(repsInput),
              weight > 0, reps > 0 else {
            // Handle invalid input - reset to target values
            resetToTargetValues()
            return
        }
        
        // Call the completion handler
        onComplete(weight, reps)
        isEditing = false
    }
    
    /// Resets input fields to target values
    private func resetToTargetValues() {
        weightInput = String(format: "%.1f", set.targetWeight)
        repsInput = "\(set.targetReps)"
    }
    
    /// Updates the target values for the set
    private func updateTargetValues() {
        guard let weight = Double(weightInput),
              let reps = Int(repsInput) else {
            // Handle invalid input
            return
        }
        
        // Call the update handler
        onUpdate(weight, reps)
    }
}

// MARK: - Set Edit Sheet
struct SetEditSheet: View {
    let set: SetData
    let onComplete: (Double, Int) -> Void
    
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @Environment(\.dismiss) private var dismiss
    
    init(set: SetData, onComplete: @escaping (Double, Int) -> Void) {
        self.set = set
        self.onComplete = onComplete
        _weightInput = State(initialValue: String(format: "%.1f", set.targetWeight))
        _repsInput = State(initialValue: "\(set.targetReps)")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Set \(set.setNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Weight (kg)")
                            .font(.headline)
                        Spacer()
                        TextField("0.0", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Reps")
                            .font(.headline)
                        Spacer()
                        TextField("0", text: $repsInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                }
                .padding(.horizontal, 20)
                
                Button(action: completeSet) {
                    Text("Complete Set")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func completeSet() {
        guard let weight = Double(weightInput),
              let reps = Int(repsInput),
              weight > 0, reps > 0 else {
            return
        }
        
        onComplete(weight, reps)
        dismiss()
    }
}

// MARK: - Preview
struct SetRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Incomplete set
            SetRowView(
                set: SetData(setNumber: 1, targetReps: 10, targetWeight: 100.0),
                isActive: true,
                onComplete: { _, _ in },
                onUpdate: { _, _ in }
            )
            
            // Completed set
            SetRowView(
                set: {
                    var set = SetData(setNumber: 2, targetReps: 10, targetWeight: 100.0)
                    set.completed = true
                    set.actualReps = 8
                    set.actualWeight = 100.0
                    return set
                }(),
                onComplete: { _, _ in },
                onUpdate: { _, _ in }
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}