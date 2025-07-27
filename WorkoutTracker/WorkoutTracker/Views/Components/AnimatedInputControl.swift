import SwiftUI

/// A bouncy, animated input control for weight and rep values with large touch targets
struct AnimatedInputControl: View {
    
    // MARK: - Properties
    let label: String
    let unit: String
    @Binding var value: String
    let incrementAmount: Double
    let decrementAmount: Double
    let minValue: Double
    let maxValue: Double
    let keyboardType: UIKeyboardType
    let onValueChange: (String) -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    // MARK: - State
    @State private var isPressed = false
    @State private var isEditing = false
    @State private var isIncrementPressed = false
    @State private var isDecrementPressed = false
    @State private var longPressTimer: Timer?
    @State private var accelerationCounter = 0
    @FocusState private var isFocused: Bool
    
    // MARK: - Animation Service
    @StateObject private var animationService = AnimationService.shared
    private let controlId = UUID()
    
    // MARK: - Initialization
    init(
        label: String,
        unit: String = "",
        value: Binding<String>,
        incrementAmount: Double = 1.0,
        decrementAmount: Double = 1.0,
        minValue: Double = 0.0,
        maxValue: Double = 999.0,
        keyboardType: UIKeyboardType = .decimalPad,
        onValueChange: @escaping (String) -> Void = { _ in },
        onIncrement: @escaping () -> Void = {},
        onDecrement: @escaping () -> Void = {}
    ) {
        self.label = label
        self.unit = unit
        self._value = value
        self.incrementAmount = incrementAmount
        self.decrementAmount = decrementAmount
        self.minValue = minValue
        self.maxValue = maxValue
        self.keyboardType = keyboardType
        self.onValueChange = onValueChange
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 6) {
            // Label
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(labelColor)
                .accessibleAnimation(AnimationService.bouncySpring, value: isEditing)
            
            // Input control container
            HStack(spacing: 4) {
                // Decrement button
                decrementButton
                
                // Value input field
                valueInputField
                
                // Increment button
                incrementButton
            }
            .padding(.horizontal, 2)
        }
        .onAppear {
            animationService.updateState(for: controlId) {
                // Track interaction time - placeholder
                print("Updating interaction time for control")
            }
        }
        .onDisappear {
            stopLongPressTimer()
            animationService.removeState(for: controlId)
        }
    }
    
    // MARK: - Decrement Button
    private var decrementButton: some View {
        Button(action: handleDecrement) {
            ZStack {
                // Background circle
                Circle()
                    .fill(decrementButtonBackground)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(decrementButtonBorder, lineWidth: 2)
                    )
                    .cardShadow(isPressed: isDecrementPressed)
                
                // Minus icon
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(decrementButtonForeground)
            }
        }
        .scaleEffect(isDecrementPressed ? 0.92 : 1.0)
        .accessibleAnimation(AnimationService.bouncySpring, value: isDecrementPressed)
        .disabled(!canDecrement)
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press action handled by timer
        } onPressingChanged: { pressing in
            handleDecrementPressing(pressing)
        }
        .accessibilityLabel("Decrease \(label)")
        .accessibilityHint("Tap to decrease by \(decrementAmount), hold to repeat")
    }
    
    // MARK: - Increment Button
    private var incrementButton: some View {
        Button(action: handleIncrement) {
            ZStack {
                // Background circle
                Circle()
                    .fill(incrementButtonBackground)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(incrementButtonBorder, lineWidth: 2)
                    )
                    .cardShadow(isPressed: isIncrementPressed)
                
                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(incrementButtonForeground)
            }
        }
        .scaleEffect(isIncrementPressed ? 0.92 : 1.0)
        .accessibleAnimation(AnimationService.bouncySpring, value: isIncrementPressed)
        .disabled(!canIncrement)
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press action handled by timer
        } onPressingChanged: { pressing in
            handleIncrementPressing(pressing)
        }
        .accessibilityLabel("Increase \(label)")
        .accessibilityHint("Tap to increase by \(incrementAmount), hold to repeat")
    }
    
    // MARK: - Value Input Field
    private var valueInputField: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(inputFieldBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(inputFieldBorder, lineWidth: 2)
                )
                .frame(minWidth: 45, maxWidth: 55, minHeight: 36, maxHeight: 36)
                .glowEffect(isActive: isEditing, color: .primaryBlue, radius: 8)
            
            // Text field
            TextField("0", text: $value)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.center)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(inputFieldTextColor)
                .focused($isFocused)
                .onSubmit {
                    handleValueSubmit()
                }
                .onChange(of: value) { _, newValue in
                    handleValueChange(newValue)
                }
                .onChange(of: isFocused) { _, focused in
                    handleFocusChange(focused)
                }
        }
        .bouncyPress(
            scale: 0.98,
            hapticFeedback: true,
            onPress: {
                isFocused = true
            }
        )
        .accessibilityLabel("\(label) value")
        .accessibilityValue(value + (unit.isEmpty ? "" : " \(unit)"))
    }
    
    // MARK: - Computed Properties
    
    private var labelColor: Color {
        if isEditing {
            return .primaryBlue
        } else {
            return .secondary
        }
    }
    
    private var canIncrement: Bool {
        guard let numericValue = Double(value) else { return true }
        return numericValue < maxValue
    }
    
    private var canDecrement: Bool {
        guard let numericValue = Double(value) else { return true }
        return numericValue > minValue
    }
    
    // MARK: - Button Backgrounds
    
    private var incrementButtonBackground: LinearGradient {
        if !canIncrement {
            return Color.neutralGradient
        } else if isIncrementPressed {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.primaryBlue.opacity(0.8),
                    Color.primaryBlue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.primaryBlue.opacity(0.1),
                    Color.primaryBlue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var decrementButtonBackground: LinearGradient {
        if !canDecrement {
            return Color.neutralGradient
        } else if isDecrementPressed {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.primaryBlue.opacity(0.8),
                    Color.primaryBlue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.primaryBlue.opacity(0.1),
                    Color.primaryBlue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var incrementButtonBorder: Color {
        if !canIncrement {
            return Color.gray.opacity(0.3)
        } else if isIncrementPressed {
            return Color.primaryBlue
        } else {
            return Color.primaryBlue.opacity(0.3)
        }
    }
    
    private var decrementButtonBorder: Color {
        if !canDecrement {
            return Color.gray.opacity(0.3)
        } else if isDecrementPressed {
            return Color.primaryBlue
        } else {
            return Color.primaryBlue.opacity(0.3)
        }
    }
    
    private var incrementButtonForeground: Color {
        if !canIncrement {
            return .gray
        } else if isIncrementPressed {
            return .white
        } else {
            return .primaryBlue
        }
    }
    
    private var decrementButtonForeground: Color {
        if !canDecrement {
            return .gray
        } else if isDecrementPressed {
            return .white
        } else {
            return .primaryBlue
        }
    }
    
    private var inputFieldBackground: Color {
        if isEditing {
            return Color(.systemBackground)
        } else {
            return Color.neutralGray.opacity(0.5)
        }
    }
    
    private var inputFieldBorder: Color {
        if isEditing {
            return .primaryBlue
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var inputFieldTextColor: Color {
        if isEditing {
            return .primary
        } else {
            return .secondary
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleIncrement() {
        guard canIncrement else { return }
        
        HapticService.shared.incrementValue()
        onIncrement()
        
        animationService.updateState(for: controlId) {
            // Track interaction time - placeholder
            print("Updating interaction time for increment")
        }
    }
    
    private func handleDecrement() {
        guard canDecrement else { return }
        
        HapticService.shared.decrementValue()
        onDecrement()
        
        animationService.updateState(for: controlId) {
            // Track interaction time - placeholder
            print("Updating interaction time for decrement")
        }
    }
    
    private func handleIncrementPressing(_ pressing: Bool) {
        isIncrementPressed = pressing
        
        if pressing {
            HapticService.shared.bouncyPress()
            startLongPressTimer(isIncrement: true)
        } else {
            stopLongPressTimer()
            HapticService.shared.bouncyRelease()
        }
    }
    
    private func handleDecrementPressing(_ pressing: Bool) {
        isDecrementPressed = pressing
        
        if pressing {
            HapticService.shared.bouncyPress()
            startLongPressTimer(isIncrement: false)
        } else {
            stopLongPressTimer()
            HapticService.shared.bouncyRelease()
        }
    }
    
    private func handleValueChange(_ newValue: String) {
        // Validate input
        let filteredValue = filterInput(newValue)
        if filteredValue != newValue {
            value = filteredValue
        }
        
        onValueChange(filteredValue)
        
        animationService.updateState(for: controlId) {
            // Track interaction time - placeholder
            print("Updating interaction time for value change")
        }
    }
    
    private func handleValueSubmit() {
        isFocused = false
        validateAndCorrectValue()
    }
    
    private func handleFocusChange(_ focused: Bool) {
        isEditing = focused
        
        if focused {
            HapticService.shared.focusChanged()
        } else {
            validateAndCorrectValue()
        }
        
        animationService.triggerEditing(for: controlId, editing: focused)
    }
    
    // MARK: - Long Press Timer
    
    private func startLongPressTimer(isIncrement: Bool) {
        accelerationCounter = 0
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            accelerationCounter += 1
            
            // Accelerate after initial delay
            let shouldExecute = accelerationCounter < 10 || accelerationCounter % max(1, 10 - accelerationCounter / 10) == 0
            
            if shouldExecute {
                if isIncrement {
                    handleIncrement()
                } else {
                    handleDecrement()
                }
            }
        }
    }
    
    private func stopLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
        accelerationCounter = 0
    }
    
    // MARK: - Input Validation
    
    private func filterInput(_ input: String) -> String {
        // Allow digits, decimal point, and handle different keyboard types
        switch keyboardType {
        case .decimalPad, .numberPad:
            let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
            let filtered = input.components(separatedBy: allowedCharacters.inverted).joined()
            
            // Ensure only one decimal point
            let components = filtered.components(separatedBy: ".")
            if components.count > 2 {
                return components[0] + "." + components[1]
            }
            
            return filtered
            
        default:
            return input
        }
    }
    
    private func validateAndCorrectValue() {
        guard let numericValue = Double(value) else {
            value = String(minValue)
            return
        }
        
        let clampedValue = max(minValue, min(maxValue, numericValue))
        
        if keyboardType == .decimalPad {
            value = String(format: "%.1f", clampedValue)
        } else {
            value = String(Int(clampedValue))
        }
    }
}

// MARK: - Preview

struct AnimatedInputControl_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Weight control
            AnimatedInputControl(
                label: "kg",
                unit: "kg",
                value: .constant("100.0"),
                incrementAmount: 2.5,
                decrementAmount: 2.5,
                keyboardType: .decimalPad
            )
            
            // Reps control
            AnimatedInputControl(
                label: "reps",
                unit: "reps",
                value: .constant("10"),
                incrementAmount: 1,
                decrementAmount: 1,
                keyboardType: .numberPad
            )
            
            // Disabled state
            AnimatedInputControl(
                label: "disabled",
                value: .constant("0"),
                minValue: 0,
                maxValue: 0
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}