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
        VStack(spacing: 8) {
            // Main row content
            HStack(spacing: 12) {
                // Set number
                Text("Set \(set.setNumber)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)
                
                // Target values
                VStack(alignment: .leading, spacing: 2) {
                    Text("Target")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", set.targetWeight))kg × \(set.targetReps)")
                        .font(.subheadline)
                }
                .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                // Actual values (if completed)
                if set.completed {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Actual")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f", set.actualWeight))kg × \(set.actualReps)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .frame(width: 100, alignment: .trailing)
                } else if isEditing {
                    // Edit mode
                    HStack(spacing: 8) {
                        TextField("kg", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                        
                        TextField("reps", text: $repsInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50)
                        
                        Button(action: completeSet) {
                            Text("✓")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    // Start set button
                    Button(action: { isEditing = true }) {
                        Text(isActive ? "Start Set" : "Edit")
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                }
                
                // Completion status
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.completed ? .green : .gray)
                    .font(.title2)
            }
            
            // Previous workout data (if available)
            if let previous = previousSet {
                HStack {
                    Text("Previous:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", previous.actualWeight))kg × \(previous.actualReps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.leading, 60)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    /// Background color based on set status
    private var backgroundColor: Color {
        if set.completed {
            return Color.green.opacity(0.1)
        } else if isActive {
            return Color.blue.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
    
    /// Completes the set with the entered values
    private func completeSet() {
        guard let weight = Double(weightInput),
              let reps = Int(repsInput) else {
            // Handle invalid input
            return
        }
        
        // Call the completion handler
        onComplete(weight, reps)
        isEditing = false
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
                previousSet: SetData(setNumber: 2, targetReps: 8, targetWeight: 95.0),
                onComplete: { _, _ in },
                onUpdate: { _, _ in }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}