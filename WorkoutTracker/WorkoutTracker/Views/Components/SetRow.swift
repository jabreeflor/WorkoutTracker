import SwiftUI

struct SetRow: View {
    @Binding var setData: SetData
    let setNumber: Int
    let previousSetData: SetData?
    let isWorkoutActive: Bool
    let onSetCompleted: () -> Void
    let onStartRestTimer: (Int) -> Void
    
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @State private var isEditing: Bool = false
    @State private var showingRPEPicker: Bool = false
    @State private var selectedRPE: Int = 7
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Set number
                Text("\(setNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                // Target values
                VStack(alignment: .leading, spacing: 2) {
                    Text("Target")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", setData.targetWeight))\(weightUnit) × \(setData.targetReps)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(width: 90, alignment: .leading)
                
                Spacer()
                
                // Input/Display area
                if setData.completed {
                    // Completed set display
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Actual")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", setData.actualWeight))\(weightUnit) × \(setData.actualReps)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .frame(width: 90, alignment: .trailing)
                } else if isEditing {
                    // Input mode
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            TextField("kg", text: $weightInput)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 50)
                            
                            TextField("reps", text: $repsInput)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 40)
                        }
                        
                        HStack(spacing: 8) {
                            Button("Cancel") {
                                cancelEdit()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            
                            Button("Done") {
                                completeSet()
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(6)
                        }
                    }
                } else {
                    // Start set button
                    Button(action: startSet) {
                        Text("Start")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(!isWorkoutActive)
                }
                
                // Completion indicator
                Image(systemName: setData.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(setData.completed ? .green : .gray)
                    .font(.title3)
            }
            
            // Previous workout comparison (if available)
            if let previous = previousSetData {
                HStack {
                    Text("Previous:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", previous.actualWeight))kg × \(previous.actualReps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Performance comparison
                    if setData.completed {
                        let volumeChange = setData.volume - previous.volume
                        if volumeChange > 0 {
                            Text("(+\(String(format: "%.1f", volumeChange)))")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if volumeChange < 0 {
                            Text("(\(String(format: "%.1f", volumeChange)))")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.leading, 42)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 1)
        )
        .onAppear {
            initializeInputs()
        }
    }
    
    // MARK: - Helper Methods
    
    private var backgroundColor: Color {
        if setData.completed {
            return Color.green.opacity(0.1)
        } else if isEditing {
            return Color.blue.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if setData.completed {
            return Color.green.opacity(0.3)
        } else if isEditing {
            return Color.blue
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private func initializeInputs() {
        weightInput = String(format: "%.1f", setData.targetWeight)
        repsInput = "\(setData.targetReps)"
    }
    
    private func startSet() {
        isEditing = true
        initializeInputs()
    }
    
    private func cancelEdit() {
        isEditing = false
        initializeInputs()
    }
    
    private func completeSet() {
        guard let weight = Double(weightInput),
              let reps = Int(repsInput),
              weight > 0, reps > 0 else {
            // Show error or validation feedback
            return
        }
        
        // Update the set data
        setData.actualWeight = weight
        setData.actualReps = reps
        setData.completed = true
        setData.timestamp = Date()
        
        isEditing = false
        onSetCompleted()
        
        // Start rest timer (default 60 seconds, can be customized)
        onStartRestTimer(60)
    }
}

// MARK: - Preview
struct SetRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Incomplete set
            SetRow(
                setData: .constant(SetData(setNumber: 1, targetReps: 10, targetWeight: 100.0)),
                setNumber: 1,
                previousSetData: nil,
                isWorkoutActive: true,
                onSetCompleted: {},
                onStartRestTimer: { _ in }
            )
            
            // Completed set with previous data
            SetRow(
                setData: .constant({
                    var set = SetData(setNumber: 2, targetReps: 10, targetWeight: 100.0)
                    set.actualWeight = 102.5
                    set.actualReps = 8
                    set.completed = true
                    return set
                }()),
                setNumber: 2,
                previousSetData: {
                    var prev = SetData(setNumber: 2, targetReps: 10, targetWeight: 95.0)
                    prev.actualWeight = 95.0
                    prev.actualReps = 10
                    prev.completed = true
                    return prev
                }(),
                isWorkoutActive: true,
                onSetCompleted: {},
                onStartRestTimer: { _ in }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}