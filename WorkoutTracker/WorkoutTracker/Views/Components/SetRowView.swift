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
    @State private var isEditingWeight: Bool = false
    @State private var isEditingReps: Bool = false
    @State private var shouldShowConfetti: Bool = false
    @State private var completionScale: CGFloat = 1.0
    @State private var completionGlow: Bool = false
    @FocusState private var weightFieldFocused: Bool
    @FocusState private var repsFieldFocused: Bool
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    
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
        ZStack {
            HStack(spacing: 12) {
                // Set number indicator
                setNumberIndicator
                
                // Previous set comparison (if available)
                if let previousSet = previousSet {
                    previousSetIndicator(previousSet)
                }
                
                Spacer()
                
                // Weight input section
                weightInputSection
                
                // Reps input section  
                repsInputSection
                
                // Completion button
                completionButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(setBackgroundGradient)
            .overlay(setOverlay)
            .scaleEffect(completionScale)
            .shadow(
                color: set.completed ? Color.green.opacity(0.7) : Color.clear,
                radius: set.completed ? 12 : 0,
                x: 0,
                y: set.completed ? 4 : 0
            )
            .overlay(
                // Additional pulsing glow effect for completed sets
                set.completed ?
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.mint.opacity(0.6), lineWidth: 6)
                        .scaleEffect(completionGlow ? 1.1 : 1.0)
                        .opacity(completionGlow ? 0.3 : 0.8)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: completionGlow)
                : nil
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: completionScale)
            .animation(.easeInOut(duration: 0.5), value: set.completed)
            .animation(.easeInOut(duration: 0.4), value: setBackgroundColor)
            .onAppear {
                initializeInputs()
            }
            .onChange(of: set) { _, newSet in
                // Update inputs when set data changes externally
                if newSet.completed {
                    weightInput = String(format: "%.1f", newSet.actualWeight)
                    repsInput = "\(newSet.actualReps)"
                } else {
                    weightInput = String(format: "%.1f", newSet.targetWeight)
                    repsInput = "\(newSet.targetReps)"
                }
            }
            
            // Confetti effect for completion
            if shouldShowConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .onAppear {
                        // Hide confetti after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            shouldShowConfetti = false
                        }
                    }
            }
        }
        .id("set-\(set.id)-\(set.completed ? "completed" : "incomplete")")
        .onChange(of: set.completed) { _, completed in
            if completed {
                // Trigger completion animation with enhanced effects
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    completionScale = 1.15
                }
                
                // Add multiple haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
                
                // Trigger glow effect
                completionGlow = true
                
                // Success sound feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)
                }
                
                // Reset scale after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        completionScale = 1.0
                    }
                }
            } else {
                // Reset effects when uncompleted
                completionGlow = false
                completionScale = 1.0
            }
        }
    }
    
    // MARK: - UI Components
    
    private var setNumberIndicator: some View {
        ZStack {
            if set.completed {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green,
                                Color.mint.opacity(0.9),
                                Color.green.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.yellow.opacity(0.8), Color.green]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3.0
                            )
                    )
                    .shadow(color: Color.green.opacity(0.6), radius: 6, x: 0, y: 3)
                    .overlay(
                        // Subtle rotating highlight
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            .scaleEffect(0.7)
                            .rotationEffect(.degrees(completionGlow ? 360 : 0))
                            .animation(.linear(duration: 3.0).repeatForever(autoreverses: false), value: completionGlow)
                    )
            } else {
                Circle()
                    .fill(setIndicatorColor)
                    .frame(width: 32, height: 32)
            }
            
            if set.completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(completionScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: completionScale)
                    .overlay(
                        // Sparkling effect
                        ForEach(0..<8, id: \.self) { index in
                            Circle()
                                .fill(Color.yellow.opacity(0.9))
                                .frame(width: 2, height: 2)
                                .offset(
                                    x: CGFloat(cos(Double(index) * .pi / 4) * 20),
                                    y: CGFloat(sin(Double(index) * .pi / 4) * 20)
                                )
                                .scaleEffect(set.completed ? (0.5 + Double(index) * 0.1) : 0.0)
                                .opacity(set.completed ? 0.0 : 1.0)
                                .animation(
                                    .easeOut(duration: 1.2)
                                    .delay(Double(index) * 0.1),
                                    value: set.completed
                                )
                        }
                    )
            } else {
                Text("\(set.setNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(setIndicatorTextColor)
            }
        }
    }
    
    private func previousSetIndicator(_ previousSet: SetData) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Prev")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(String(format: "%.0f", previousSet.actualWeight))×\(previousSet.actualReps)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(width: 40)
    }
    
    private var weightInputSection: some View {
        VStack(spacing: 4) {
            Text(weightUnit)
                .font(.caption2)
                .foregroundColor(set.completed ? .green : .secondary)
            
            if set.completed && !isEditingWeight {
                // Show completed weight
                Button(action: { startEditingWeight() }) {
                    Text(String(format: "%.1f", set.actualWeight))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green.opacity(0.8),
                                            Color.mint.opacity(0.6),
                                            Color.green.opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.yellow.opacity(0.6), Color.green]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2.5
                                        )
                                )
                                .shadow(color: Color.green.opacity(0.5), radius: 4, x: 0, y: 2)
                                .overlay(
                                    // Subtle shimmer effect
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.3), Color.clear]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .offset(x: completionGlow ? 80 : -80)
                                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: completionGlow)
                                )
                        )
                }
            } else {
                // Editable weight input - Clean text input without +/- buttons
                TextField("0.0", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 70, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .focused($weightFieldFocused)
                    .onSubmit {
                        updateWeightFromInput()
                        isEditingWeight = false
                    }
                    .onChange(of: weightFieldFocused) { _, focused in
                        if !focused {
                            updateWeightFromInput()
                            isEditingWeight = false
                        }
                    }
                    .disabled(!isActive)
            }
        }
    }
    
    private var repsInputSection: some View {
        VStack(spacing: 4) {
            Text("reps")
                .font(.caption2)
                .foregroundColor(set.completed ? .green : .secondary)
            
            if set.completed && !isEditingReps {
                // Show completed reps
                Button(action: { startEditingReps() }) {
                    Text("\(set.actualReps)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green.opacity(0.8),
                                            Color.mint.opacity(0.6),
                                            Color.green.opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.yellow.opacity(0.6), Color.green]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2.5
                                        )
                                )
                                .shadow(color: Color.green.opacity(0.5), radius: 4, x: 0, y: 2)
                                .overlay(
                                    // Subtle shimmer effect
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.3), Color.clear]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .offset(x: completionGlow ? 80 : -80)
                                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: completionGlow)
                                )
                        )
                }
            } else {
                // Editable reps input - Clean text input without +/- buttons
                TextField("0", text: $repsInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 70, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .focused($repsFieldFocused)
                    .onSubmit {
                        updateRepsFromInput()
                        isEditingReps = false
                    }
                    .onChange(of: repsFieldFocused) { _, focused in
                        if !focused {
                            updateRepsFromInput()
                            isEditingReps = false
                        }
                    }
                    .disabled(!isActive)
            }
        }
    }
    
    private var completionButton: some View {
        Button(action: {
            // Trigger haptic feedback first
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                toggleCompletion()
            }
        }) {
            ZStack {
                if set.completed {
                    // Completed state with celebration animation
                    ZStack {
                        // Outer glow effect
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .scaleEffect(set.completed ? 1.2 : 0.8)
                            .opacity(set.completed ? 1 : 0)
                            .animation(.easeOut(duration: 0.6), value: set.completed)
                        
                        // Main checkmark
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                            .scaleEffect(set.completed ? 1.0 : 0.3)
                            .rotationEffect(.degrees(set.completed ? 0 : -180))
                            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: set.completed)
                        
                        // Sparkle effect
                        if set.completed {
                            ForEach(0..<6, id: \.self) { index in
                                Circle()
                                    .fill(Color.green.opacity(0.8))
                                    .frame(width: 3, height: 3)
                                    .offset(
                                        x: CGFloat(cos(Double(index) * .pi / 3) * 25),
                                        y: CGFloat(sin(Double(index) * .pi / 3) * 25)
                                    )
                                    .scaleEffect(set.completed ? 1.0 : 0.0)
                                    .opacity(set.completed ? 0.0 : 1.0)
                                    .animation(
                                        .easeOut(duration: 0.8)
                                        .delay(Double(index) * 0.1),
                                        value: set.completed
                                    )
                            }
                        }
                    }
                } else {
                    // Incomplete state with enhanced progress indicator
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                            .frame(width: 32, height: 32)
                        
                        // Progress ring
                        Circle()
                            .trim(from: 0, to: allFieldsValid ? 1.0 : 0.3)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 32, height: 32)
                            .rotationEffect(Angle.degrees(-90))
                            .animation(.easeInOut(duration: 0.4), value: allFieldsValid)
                        
                        // Center indicator
                        if allFieldsValid {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 8, height: 8)
                                .scaleEffect(allFieldsValid ? 1.0 : 0.1)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: allFieldsValid)
                        } else {
                            // Pulsing dot when not ready
                            Circle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 6, height: 6)
                                .scaleEffect(isActive ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isActive)
                        }
                    }
                }
            }
            .frame(width: 44, height: 44)
        }
        .disabled(!isActive || (!allFieldsValid && !set.completed))
        .sensoryFeedback(.success, trigger: set.completed)
    }
    
    // MARK: - Computed Properties
    
    private var setIndicatorColor: Color {
        if set.completed {
            return Color.green.opacity(0.25)
        } else if isCurrentSet {
            return Color.blue.opacity(0.25)
        } else {
            return Color(.systemGray5)
        }
    }
    
    private var setIndicatorTextColor: Color {
        if set.completed {
            return Color.green.opacity(0.9)
        } else if isCurrentSet {
            return Color.blue
        } else {
            return .secondary
        }
    }
    
    private var setBackgroundColor: Color {
        if set.completed {
            // More vibrant, celebratory background for completed sets
            return Color.green.opacity(0.4)
        } else if isCurrentSet {
            return Color.blue.opacity(0.08)
        } else {
            return Color(.systemGray6).opacity(0.5)
        }
    }
    
    private var setBackgroundGradient: some View {
        if set.completed {
            // Enhanced gradient background for completed sets
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.4),
                    Color.mint.opacity(0.3),
                    Color.green.opacity(0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isCurrentSet {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.08)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6).opacity(0.5)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var setOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                set.completed ? 
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green,
                            Color.mint.opacity(0.8),
                            Color.green.opacity(0.9),
                            Color.mint
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                isCurrentSet ? 
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.4)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : 
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                lineWidth: set.completed ? 4.0 : 1.5
            )
            .overlay(
                // Additional celebratory border effect for completed sets
                set.completed ? 
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow.opacity(0.6), Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.0
                        )
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: set.completed)
                : nil
            )
    }
    
    private var isCurrentSet: Bool {
        isActive && !set.completed
    }
    
    private var allFieldsValid: Bool {
        guard let weight = Double(weightInput),
              let reps = Int(repsInput) else {
            return false
        }
        return weight > 0 && reps > 0
    }
    
    // MARK: - Helper Methods
    
    private func initializeInputs() {
        if set.completed {
            weightInput = String(format: "%.1f", set.actualWeight)
            repsInput = "\(set.actualReps)"
        } else {
            weightInput = String(format: "%.1f", set.targetWeight)
            repsInput = "\(set.targetReps)"
        }
    }
    
    private func startEditingWeight() {
        isEditingWeight = true
        weightFieldFocused = true
    }
    
    private func startEditingReps() {
        isEditingReps = true
        repsFieldFocused = true
    }
    
    private func adjustWeight(_ delta: Double) {
        guard let currentWeight = Double(weightInput) else { return }
        let newWeight = max(0, currentWeight + delta)
        weightInput = String(format: "%.1f", newWeight)
        updateWeightFromInput()
    }
    
    private func adjustReps(_ delta: Int) {
        guard let currentReps = Int(repsInput) else { return }
        let newReps = max(0, currentReps + delta)
        repsInput = "\(newReps)"
        updateRepsFromInput()
    }
    
    private func updateWeightFromInput() {
        guard let weight = Double(weightInput), weight >= 0 else {
            // Reset to previous valid value
            weightInput = String(format: "%.1f", set.completed ? set.actualWeight : set.targetWeight)
            return
        }
        
        if set.completed {
            // Update completed set
            let reps = Int(repsInput) ?? set.actualReps
            onUpdate(weight, reps)
        }
    }
    
    private func updateRepsFromInput() {
        guard let reps = Int(repsInput), reps >= 0 else {
            // Reset to previous valid value
            repsInput = "\(set.completed ? set.actualReps : set.targetReps)"
            return
        }
        
        if set.completed {
            // Update completed set
            let weight = Double(weightInput) ?? set.actualWeight
            onUpdate(weight, reps)
        }
    }
    
    private func toggleCompletion() {
        if set.completed {
            // Uncomplete the set - reset to target values
            weightInput = String(format: "%.1f", set.targetWeight)
            repsInput = "\(set.targetReps)"
            onUpdate(set.targetWeight, set.targetReps)
            shouldShowConfetti = false
        } else {
            // Complete the set with current values
            guard let weight = Double(weightInput),
                  let reps = Int(repsInput),
                  weight > 0, reps > 0 else {
                return
            }
            onComplete(weight, reps)
            
            // Trigger confetti animation
            shouldShowConfetti = true
        }
    }
}

// MARK: - Preview
struct SetRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            // Active incomplete set
            SetRowView(
                set: SetData(setNumber: 1, targetReps: 10, targetWeight: 100.0),
                previousSet: SetData(setNumber: 1, targetReps: 8, targetWeight: 95.0).applying {
                    $0.completed = true
                    $0.actualReps = 8
                    $0.actualWeight = 95.0
                },
                isActive: true,
                onComplete: { weight, reps in
                    print("Completed: \(weight)kg x \(reps)")
                },
                onUpdate: { weight, reps in
                    print("Updated: \(weight)kg x \(reps)")
                }
            )
            
            // Completed set
            SetRowView(
                set: SetData(setNumber: 2, targetReps: 10, targetWeight: 100.0).applying {
                    $0.completed = true
                    $0.actualReps = 8
                    $0.actualWeight = 100.0
                },
                isActive: true,
                onComplete: { _, _ in },
                onUpdate: { _, _ in }
            )
            
            // Inactive set
            SetRowView(
                set: SetData(setNumber: 3, targetReps: 10, targetWeight: 100.0),
                isActive: false,
                onComplete: { _, _ in },
                onUpdate: { _, _ in }
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}

// Helper extension for preview
extension SetData {
    func applying(_ closure: (inout SetData) -> Void) -> SetData {
        var copy = self
        closure(&copy)
        return copy
    }
}