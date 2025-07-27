import SwiftUI
import Combine

/// Service for handling input validation with smooth visual feedback
@MainActor
class InputValidationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var validationStates: [UUID: ValidationState] = [:]
    
    // MARK: - Singleton
    static let shared = InputValidationService()
    
    private init() {}
    
    // MARK: - Validation State Management
    
    /// Get validation state for a given input field
    func getValidationState(for id: UUID) -> ValidationState {
        return validationStates[id] ?? ValidationState()
    }
    
    /// Update validation state for a given input field
    func updateValidationState(for id: UUID, _ update: (inout ValidationState) -> Void) {
        var state = getValidationState(for: id)
        update(&state)
        validationStates[id] = state
    }
    
    /// Remove validation state for cleanup
    func removeValidationState(for id: UUID) {
        validationStates.removeValue(forKey: id)
    }
    
    // MARK: - Validation Methods
    
    /// Validate numeric input with range checking
    func validateNumericInput(
        _ input: String,
        for id: UUID,
        minValue: Double = 0.0,
        maxValue: Double = 999.0,
        allowDecimals: Bool = true
    ) -> ValidationResult {
        
        let result = performNumericValidation(
            input,
            minValue: minValue,
            maxValue: maxValue,
            allowDecimals: allowDecimals
        )
        
        updateValidationState(for: id) { state in
            state.isValid = result.isValid
            state.errorMessage = result.errorMessage
            state.suggestedValue = result.suggestedValue
            state.lastValidationTime = Date()
            
            // Trigger error animation if invalid
            if !result.isValid {
                state.shouldShowError = true
                state.errorAnimationTrigger.toggle()
            } else {
                state.shouldShowError = false
            }
        }
        
        return result
    }
    
    /// Validate weight input specifically
    func validateWeightInput(
        _ input: String,
        for id: UUID,
        minWeight: Double = 0.0,
        maxWeight: Double = 500.0
    ) -> ValidationResult {
        return validateNumericInput(
            input,
            for: id,
            minValue: minWeight,
            maxValue: maxWeight,
            allowDecimals: true
        )
    }
    
    /// Validate reps input specifically
    func validateRepsInput(
        _ input: String,
        for id: UUID,
        minReps: Int = 0,
        maxReps: Int = 100
    ) -> ValidationResult {
        return validateNumericInput(
            input,
            for: id,
            minValue: Double(minReps),
            maxValue: Double(maxReps),
            allowDecimals: false
        )
    }
    
    /// Validate timer input specifically
    func validateTimerInput(
        _ input: String,
        for id: UUID,
        minSeconds: Int = 0,
        maxSeconds: Int = 3600
    ) -> ValidationResult {
        return validateNumericInput(
            input,
            for: id,
            minValue: Double(minSeconds),
            maxValue: Double(maxSeconds),
            allowDecimals: false
        )
    }
    
    // MARK: - Real-time Validation
    
    /// Start real-time validation for an input field
    func startRealTimeValidation(
        for id: UUID,
        inputValue: String,
        validationType: ValidationType
    ) {
        performRealTimeValidation(inputValue, for: id, type: validationType)
    }
    
    private func performRealTimeValidation(
        _ input: String,
        for id: UUID,
        type: ValidationType
    ) {
        let result: ValidationResult
        
        switch type {
        case .weight(let min, let max):
            result = validateWeightInput(input, for: id, minWeight: min, maxWeight: max)
        case .reps(let min, let max):
            result = validateRepsInput(input, for: id, minReps: min, maxReps: max)
        case .timer(let min, let max):
            result = validateTimerInput(input, for: id, minSeconds: min, maxSeconds: max)
        case .custom(let min, let max, let allowDecimals):
            result = validateNumericInput(input, for: id, minValue: min, maxValue: max, allowDecimals: allowDecimals)
        }
        
        // Trigger haptic feedback for errors
        if !result.isValid {
            HapticService.shared.provideFeedback(for: .error)
        }
    }
    
    // MARK: - Core Validation Logic
    
    private func performNumericValidation(
        _ input: String,
        minValue: Double,
        maxValue: Double,
        allowDecimals: Bool
    ) -> ValidationResult {
        
        // Check if input is empty
        if input.isEmpty {
            return ValidationResult(
                isValid: false,
                errorMessage: "Value cannot be empty",
                suggestedValue: String(minValue)
            )
        }
        
        // Check if input contains valid characters
        let validCharacters = allowDecimals ? "0123456789." : "0123456789"
        let characterSet = CharacterSet(charactersIn: validCharacters)
        
        if input.rangeOfCharacter(from: characterSet.inverted) != nil {
            return ValidationResult(
                isValid: false,
                errorMessage: "Invalid characters",
                suggestedValue: filterInvalidCharacters(input, allowDecimals: allowDecimals)
            )
        }
        
        // Check for multiple decimal points
        if allowDecimals && input.components(separatedBy: ".").count > 2 {
            return ValidationResult(
                isValid: false,
                errorMessage: "Multiple decimal points",
                suggestedValue: fixMultipleDecimals(input)
            )
        }
        
        // Convert to numeric value
        guard let numericValue = Double(input) else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Invalid number format",
                suggestedValue: String(minValue)
            )
        }
        
        // Check range
        if numericValue < minValue {
            return ValidationResult(
                isValid: false,
                errorMessage: "Value too low (minimum: \(formatValue(minValue, allowDecimals: allowDecimals)))",
                suggestedValue: formatValue(minValue, allowDecimals: allowDecimals)
            )
        }
        
        if numericValue > maxValue {
            return ValidationResult(
                isValid: false,
                errorMessage: "Value too high (maximum: \(formatValue(maxValue, allowDecimals: allowDecimals)))",
                suggestedValue: formatValue(maxValue, allowDecimals: allowDecimals)
            )
        }
        
        // Valid input
        return ValidationResult(
            isValid: true,
            errorMessage: nil,
            suggestedValue: input
        )
    }
    
    // MARK: - Helper Methods
    
    private func filterInvalidCharacters(_ input: String, allowDecimals: Bool) -> String {
        let validCharacters = allowDecimals ? "0123456789." : "0123456789"
        let characterSet = CharacterSet(charactersIn: validCharacters)
        return input.components(separatedBy: characterSet.inverted).joined()
    }
    
    private func fixMultipleDecimals(_ input: String) -> String {
        let components = input.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1]
        }
        return input
    }
    
    private func formatValue(_ value: Double, allowDecimals: Bool) -> String {
        if allowDecimals {
            return String(format: "%.1f", value)
        } else {
            return String(Int(value))
        }
    }
    

    
    // MARK: - Error Animation Triggers
    
    /// Trigger error animation for a specific input field
    func triggerErrorAnimation(for id: UUID) {
        updateValidationState(for: id) { state in
            state.errorAnimationTrigger.toggle()
            state.shouldShowError = true
        }
        
        // Auto-hide error after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.updateValidationState(for: id) { state in
                state.shouldShowError = false
            }
        }
    }
    
    /// Clear error state for a specific input field
    func clearError(for id: UUID) {
        updateValidationState(for: id) { state in
            state.shouldShowError = false
            state.errorMessage = nil
        }
    }
    
    // MARK: - Cleanup
    
    /// Clean up old validation states
    func cleanupOldStates() {
        let cutoffTime = Date().addingTimeInterval(-300) // 5 minutes ago
        
        validationStates = validationStates.filter { _, state in
            state.lastValidationTime > cutoffTime
        }
    }
}

// MARK: - Validation Models

struct ValidationState {
    var isValid: Bool = true
    var errorMessage: String?
    var suggestedValue: String?
    var shouldShowError: Bool = false
    var errorAnimationTrigger: Bool = false
    var lastValidationTime: Date = Date()
}

struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    let suggestedValue: String?
}

enum ValidationType {
    case weight(min: Double, max: Double)
    case reps(min: Int, max: Int)
    case timer(min: Int, max: Int)
    case custom(min: Double, max: Double, allowDecimals: Bool)
}

// MARK: - Validation View Modifiers

extension View {
    
    /// Add validation feedback to any view
    func validationFeedback(
        for id: UUID,
        validationService: InputValidationService? = nil
    ) -> some View {
        modifier(ValidationFeedbackModifier(id: id, validationService: validationService ?? InputValidationService.shared))
    }
    
    /// Add error shake animation
    func errorShake(trigger: Bool) -> some View {
        modifier(ErrorShakeModifier(trigger: trigger))
    }
    
    /// Add success pulse animation
    func successPulse(trigger: Bool) -> some View {
        modifier(SuccessPulseModifier(trigger: trigger))
    }
}

// MARK: - View Modifiers

struct ValidationFeedbackModifier: ViewModifier {
    let id: UUID
    @ObservedObject var validationService: InputValidationService
    
    func body(content: Content) -> some View {
        let state = validationService.getValidationState(for: id)
        
        content
            .overlay(
                // Error indicator
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red, lineWidth: state.shouldShowError ? 2 : 0)
                    .animation(.easeInOut(duration: 0.2), value: state.shouldShowError)
            )
            .errorShake(trigger: state.errorAnimationTrigger)
            .overlay(
                // Error message
                Group {
                    if state.shouldShowError, let errorMessage = state.errorMessage {
                        VStack {
                            Spacer()
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.red.opacity(0.1))
                                )
                                .offset(y: 35)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            )
    }
}

struct ErrorShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _, _ in
                withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                    shakeOffset = 5
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shakeOffset = 0
                }
            }
    }
}

struct SuccessPulseModifier: ViewModifier {
    let trigger: Bool
    @State private var pulseScale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(pulseScale)
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    pulseScale = 1.05
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                    pulseScale = 1.0
                }
            }
    }
}