import SwiftUI
import Combine

/// A smooth, animated value editor with seamless transitions between display and edit modes
struct SmoothValueEditor: View {
    
    // MARK: - Properties
    let label: String
    @Binding var value: String
    @Binding var isEditing: Bool
    let displayFormatter: (String) -> String
    let editFormatter: (String) -> String
    let validator: (String) -> ValidationResult
    let onValueCommit: (String) -> Void
    
    // MARK: - State
    @State private var editingValue: String = ""
    @State private var validationCancellable: AnyCancellable?
    @FocusState private var isFocused: Bool
    
    // MARK: - Services
    @StateObject private var validationService = InputValidationService.shared
    private let editorId = UUID()
    
    // MARK: - Initialization
    init(
        label: String,
        value: Binding<String>,
        isEditing: Binding<Bool>,
        displayFormatter: @escaping (String) -> String = { $0 },
        editFormatter: @escaping (String) -> String = { $0 },
        validator: @escaping (String) -> ValidationResult = { _ in ValidationResult(isValid: true, errorMessage: nil, suggestedValue: nil) },
        onValueCommit: @escaping (String) -> Void = { _ in }
    ) {
        self.label = label
        self._value = value
        self._isEditing = isEditing
        self.displayFormatter = displayFormatter
        self.editFormatter = editFormatter
        self.validator = validator
        self.onValueCommit = onValueCommit
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Display mode
            if !isEditing {
                displayModeView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
            }
            
            // Edit mode
            if isEditing {
                editModeView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
            }
        }
        .animation(AnimationService.bouncySpring, value: isEditing)
        .onAppear {
            setupValidation()
        }
        .onChange(of: editingValue) { _, _ in
            setupValidation()
        }
        .onDisappear {
            cleanupValidation()
        }
    }
    
    // MARK: - Display Mode View
    private var displayModeView: some View {
        Button(action: enterEditMode) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(displayFormatter(value))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .bouncyPress(
            scale: 0.98,
            hapticFeedback: true,
            onPress: {
                HapticService.shared.focusChanged()
            }
        )
        .accessibilityLabel("Edit \(label)")
        .accessibilityValue(displayFormatter(value))
        .accessibilityHint("Tap to edit value")
    }
    
    // MARK: - Edit Mode View
    private var editModeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(.primaryBlue)
                .accessibleAnimation(AnimationService.bouncySpring, value: isEditing)
            
            // Input field with validation
            HStack {
                TextField("Enter value", text: $editingValue)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .onSubmit {
                        commitValue()
                    }
                    .onChange(of: editingValue) { _, newValue in
                        handleValueChange(newValue)
                    }
                
                // Action buttons
                HStack(spacing: 8) {
                    // Cancel button
                    Button(action: cancelEdit) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                    .bouncyPress(hapticFeedback: true)
                    
                    // Confirm button
                    Button(action: commitValue) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(isValidInput ? .green : .gray)
                    }
                    .disabled(!isValidInput)
                    .bouncyPress(hapticFeedback: true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
            .glowEffect(isActive: isFocused, color: .primaryBlue, radius: 8)
            .validationFeedback(for: editorId, validationService: validationService)
        }
        .onAppear {
            // Set initial editing value and focus
            editingValue = editFormatter(value)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidInput: Bool {
        let validationState = validationService.getValidationState(for: editorId)
        return validationState.isValid && !editingValue.isEmpty
    }
    
    private var borderColor: Color {
        let validationState = validationService.getValidationState(for: editorId)
        
        if validationState.shouldShowError {
            return .red
        } else if isFocused {
            return .primaryBlue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    // MARK: - Action Handlers
    
    private func enterEditMode() {
        withAnimation(AnimationService.bouncySpring) {
            isEditing = true
        }
        
        HapticService.shared.focusChanged()
    }
    
    private func cancelEdit() {
        withAnimation(AnimationService.bouncySpring) {
            isEditing = false
            isFocused = false
        }
        
        // Reset to original value
        editingValue = value
        validationService.clearError(for: editorId)
        
        HapticService.shared.provideFeedback(for: .button)
    }
    
    private func commitValue() {
        let validationResult = validator(editingValue)
        
        if validationResult.isValid {
            // Success - commit the value
            withAnimation(AnimationService.bouncySpring) {
                value = editingValue
                isEditing = false
                isFocused = false
            }
            
            onValueCommit(editingValue)
            validationService.clearError(for: editorId)
            
            HapticService.shared.provideFeedback(for: .success)
        } else {
            // Error - show validation feedback
            validationService.triggerErrorAnimation(for: editorId)
            
            // Optionally use suggested value
            if let suggestedValue = validationResult.suggestedValue {
                editingValue = suggestedValue
            }
            
            HapticService.shared.provideFeedback(for: .error)
        }
    }
    
    private func handleValueChange(_ newValue: String) {
        // Real-time validation
        let validationResult = validator(newValue)
        
        validationService.updateValidationState(for: editorId) { state in
            state.isValid = validationResult.isValid
            state.errorMessage = validationResult.errorMessage
            state.suggestedValue = validationResult.suggestedValue
            state.lastValidationTime = Date()
            
            // Only show error after user stops typing
            state.shouldShowError = false
        }
    }
    
    // MARK: - Validation Setup
    
    private func setupValidation() {
        // Setup simple validation without debouncing for now
        let validationResult = validator(editingValue)
        
        validationService.updateValidationState(for: editorId) { state in
            state.isValid = validationResult.isValid
            state.errorMessage = validationResult.errorMessage
            state.suggestedValue = validationResult.suggestedValue
            state.shouldShowError = !validationResult.isValid && !editingValue.isEmpty
        }
    }
    
    private func cleanupValidation() {
        validationCancellable?.cancel()
        validationService.removeValidationState(for: editorId)
    }
}

// MARK: - Convenience Initializers

extension SmoothValueEditor {
    
    /// Create a weight value editor
    static func weight(
        value: Binding<String>,
        isEditing: Binding<Bool>,
        minWeight: Double = 0.0,
        maxWeight: Double = 500.0,
        onValueCommit: @escaping (String) -> Void = { _ in }
    ) -> SmoothValueEditor {
        SmoothValueEditor(
            label: "Weight (kg)",
            value: value,
            isEditing: isEditing,
            displayFormatter: { "\($0) kg" },
            editFormatter: { $0 },
            validator: { input in
                InputValidationService.shared.validateWeightInput(
                    input,
                    for: UUID(), // Temporary ID for validation
                    minWeight: minWeight,
                    maxWeight: maxWeight
                )
            },
            onValueCommit: onValueCommit
        )
    }
    
    /// Create a reps value editor
    static func reps(
        value: Binding<String>,
        isEditing: Binding<Bool>,
        minReps: Int = 0,
        maxReps: Int = 100,
        onValueCommit: @escaping (String) -> Void = { _ in }
    ) -> SmoothValueEditor {
        SmoothValueEditor(
            label: "Reps",
            value: value,
            isEditing: isEditing,
            displayFormatter: { "\($0) reps" },
            editFormatter: { $0 },
            validator: { input in
                InputValidationService.shared.validateRepsInput(
                    input,
                    for: UUID(), // Temporary ID for validation
                    minReps: minReps,
                    maxReps: maxReps
                )
            },
            onValueCommit: onValueCommit
        )
    }
    
    /// Create a timer value editor
    static func timer(
        value: Binding<String>,
        isEditing: Binding<Bool>,
        minSeconds: Int = 0,
        maxSeconds: Int = 3600,
        onValueCommit: @escaping (String) -> Void = { _ in }
    ) -> SmoothValueEditor {
        SmoothValueEditor(
            label: "Time (seconds)",
            value: value,
            isEditing: isEditing,
            displayFormatter: { "\($0)s" },
            editFormatter: { $0 },
            validator: { input in
                InputValidationService.shared.validateTimerInput(
                    input,
                    for: UUID(), // Temporary ID for validation
                    minSeconds: minSeconds,
                    maxSeconds: maxSeconds
                )
            },
            onValueCommit: onValueCommit
        )
    }
}

// MARK: - Preview

struct SmoothValueEditor_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Weight editor
            SmoothValueEditor.weight(
                value: .constant("100.0"),
                isEditing: .constant(false)
            )
            
            // Reps editor
            SmoothValueEditor.reps(
                value: .constant("10"),
                isEditing: .constant(false)
            )
            
            // Timer editor
            SmoothValueEditor.timer(
                value: .constant("90"),
                isEditing: .constant(true)
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}