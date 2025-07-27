import SwiftUI
import Combine

/// Service for managing immediate visual feedback across all interactive elements
@MainActor
class VisualFeedbackService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var feedbackStates: [UUID: VisualFeedbackState] = [:]
    
    // MARK: - Singleton
    static let shared = VisualFeedbackService()
    
    private init() {}
    
    // MARK: - Feedback State Management
    
    /// Get feedback state for a given element
    func getFeedbackState(for id: UUID) -> VisualFeedbackState {
        return feedbackStates[id] ?? VisualFeedbackState()
    }
    
    /// Update feedback state for a given element
    func updateFeedbackState(for id: UUID, _ update: (inout VisualFeedbackState) -> Void) {
        var state = getFeedbackState(for: id)
        update(&state)
        feedbackStates[id] = state
    }
    
    /// Remove feedback state for cleanup
    func removeFeedbackState(for id: UUID) {
        feedbackStates.removeValue(forKey: id)
    }
    
    // MARK: - Immediate Response Triggers
    
    /// Trigger immediate press response (< 16ms)
    func triggerPressResponse(for id: UUID, intensity: FeedbackIntensity = .medium) {
        updateFeedbackState(for: id) { state in
            state.isPressed = true
            state.pressIntensity = intensity
            state.lastInteractionTime = Date()
        }
        
        // Immediate haptic feedback
        switch intensity {
        case .light:
            HapticService.shared.provideFeedback(for: .impact(.light))
        case .medium:
            HapticService.shared.bouncyPress()
        case .heavy:
            HapticService.shared.provideFeedback(for: .impact(.heavy))
        }
    }
    
    /// Trigger immediate release response
    func triggerReleaseResponse(for id: UUID) {
        updateFeedbackState(for: id) { state in
            state.isPressed = false
            state.lastInteractionTime = Date()
        }
        
        HapticService.shared.bouncyRelease()
    }
    
    /// Trigger hover/focus response
    func triggerHoverResponse(for id: UUID, isHovering: Bool) {
        updateFeedbackState(for: id) { state in
            state.isHovering = isHovering
            state.lastInteractionTime = Date()
        }
        
        if isHovering {
            HapticService.shared.focusChanged()
        }
    }
    
    /// Trigger loading state
    func triggerLoadingState(for id: UUID, isLoading: Bool, message: String? = nil) {
        updateFeedbackState(for: id) { state in
            state.isLoading = isLoading
            state.loadingMessage = message
            state.lastInteractionTime = Date()
        }
    }
    
    /// Trigger success feedback
    func triggerSuccessFeedback(for id: UUID, message: String? = nil, duration: TimeInterval = 2.0) {
        updateFeedbackState(for: id) { state in
            state.showSuccess = true
            state.successMessage = message
            state.lastInteractionTime = Date()
        }
        
        HapticService.shared.provideFeedback(for: .success)
        
        // Auto-hide success feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.updateFeedbackState(for: id) { state in
                state.showSuccess = false
                state.successMessage = nil
            }
        }
    }
    
    /// Trigger error feedback
    func triggerErrorFeedback(for id: UUID, message: String, duration: TimeInterval = 3.0) {
        updateFeedbackState(for: id) { state in
            state.showError = true
            state.errorMessage = message
            state.errorAnimationTrigger.toggle()
            state.lastInteractionTime = Date()
        }
        
        HapticService.shared.provideFeedback(for: .error)
        
        // Auto-hide error feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.updateFeedbackState(for: id) { state in
                state.showError = false
                state.errorMessage = nil
            }
        }
    }
    
    /// Trigger progress update
    func triggerProgressUpdate(for id: UUID, progress: Double, message: String? = nil) {
        updateFeedbackState(for: id) { state in
            state.progress = progress
            state.progressMessage = message
            state.lastInteractionTime = Date()
        }
    }
    
    // MARK: - State Queries
    
    /// Check if element is currently pressed
    func isPressed(_ id: UUID) -> Bool {
        return getFeedbackState(for: id).isPressed
    }
    
    /// Check if element is currently hovering
    func isHovering(_ id: UUID) -> Bool {
        return getFeedbackState(for: id).isHovering
    }
    
    /// Check if element is currently loading
    func isLoading(_ id: UUID) -> Bool {
        return getFeedbackState(for: id).isLoading
    }
    
    /// Get current progress for element
    func getProgress(for id: UUID) -> Double {
        return getFeedbackState(for: id).progress
    }
    
    // MARK: - Batch Operations
    
    /// Trigger press response for multiple elements
    func triggerBatchPressResponse(for ids: [UUID], intensity: FeedbackIntensity = .medium) {
        for id in ids {
            triggerPressResponse(for: id, intensity: intensity)
        }
    }
    
    /// Clear all feedback states for multiple elements
    func clearBatchFeedback(for ids: [UUID]) {
        for id in ids {
            updateFeedbackState(for: id) { state in
                state.reset()
            }
        }
    }
    
    // MARK: - Performance Management
    
    /// Clean up old feedback states to prevent memory leaks
    func cleanupOldStates() {
        let cutoffTime = Date().addingTimeInterval(-300) // 5 minutes ago
        
        feedbackStates = feedbackStates.filter { _, state in
            state.lastInteractionTime > cutoffTime
        }
    }
    
    /// Reduce feedback complexity for performance
    func reduceComplexity() {
        for (id, _) in feedbackStates {
            updateFeedbackState(for: id) { state in
                state.reducedMotion = true
            }
        }
    }
    
    /// Restore full feedback complexity
    func restoreComplexity() {
        for (id, _) in feedbackStates {
            updateFeedbackState(for: id) { state in
                state.reducedMotion = false
            }
        }
    }
}

// MARK: - Visual Feedback State

struct VisualFeedbackState {
    var isPressed: Bool = false
    var isHovering: Bool = false
    var isLoading: Bool = false
    var showSuccess: Bool = false
    var showError: Bool = false
    var progress: Double = 0.0
    var pressIntensity: FeedbackIntensity = .medium
    var errorAnimationTrigger: Bool = false
    var lastInteractionTime: Date = Date()
    var reducedMotion: Bool = false
    
    // Messages
    var loadingMessage: String?
    var successMessage: String?
    var errorMessage: String?
    var progressMessage: String?
    
    mutating func reset() {
        isPressed = false
        isHovering = false
        isLoading = false
        showSuccess = false
        showError = false
        progress = 0.0
        loadingMessage = nil
        successMessage = nil
        errorMessage = nil
        progressMessage = nil
        lastInteractionTime = Date()
    }
}

// MARK: - Feedback Intensity

enum FeedbackIntensity {
    case light, medium, heavy
    
    var scale: CGFloat {
        switch self {
        case .light: return 0.98
        case .medium: return 0.95
        case .heavy: return 0.92
        }
    }
    
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        }
    }
}

// MARK: - Visual Feedback View Modifiers

extension View {
    
    /// Add immediate visual feedback to any interactive element
    func immediateVisualFeedback(
        for id: UUID,
        feedbackService: VisualFeedbackService? = nil
    ) -> some View {
        modifier(ImmediateVisualFeedbackModifier(id: id, feedbackService: feedbackService ?? VisualFeedbackService.shared))
    }
    
    /// Add press feedback with customizable intensity
    func pressFeedback(
        for id: UUID,
        intensity: FeedbackIntensity = .medium,
        feedbackService: VisualFeedbackService? = nil
    ) -> some View {
        modifier(PressFeedbackModifier(id: id, intensity: intensity, feedbackService: feedbackService ?? VisualFeedbackService.shared))
    }
    
    /// Add loading state feedback
    func loadingFeedback(
        for id: UUID,
        feedbackService: VisualFeedbackService? = nil
    ) -> some View {
        modifier(LoadingFeedbackModifier(id: id, feedbackService: feedbackService ?? VisualFeedbackService.shared))
    }
    
    /// Add success/error feedback overlay
    func statusFeedback(
        for id: UUID,
        feedbackService: VisualFeedbackService? = nil
    ) -> some View {
        modifier(StatusFeedbackModifier(id: id, feedbackService: feedbackService ?? VisualFeedbackService.shared))
    }
    
    /// Add progress feedback
    func progressFeedback(
        for id: UUID,
        feedbackService: VisualFeedbackService? = nil
    ) -> some View {
        modifier(ProgressFeedbackModifier(id: id, feedbackService: feedbackService ?? VisualFeedbackService.shared))
    }
}

// MARK: - View Modifiers

struct ImmediateVisualFeedbackModifier: ViewModifier {
    let id: UUID
    @ObservedObject var feedbackService: VisualFeedbackService
    
    func body(content: Content) -> some View {
        let state = feedbackService.getFeedbackState(for: id)
        
        content
            .scaleEffect(state.isPressed ? state.pressIntensity.scale : 1.0)
            .opacity(state.isHovering ? 0.8 : 1.0)
            .accessibleAnimation(AnimationService.quickFeedback, value: state.isPressed)
            .accessibleAnimation(AnimationService.quickFeedback, value: state.isHovering)
    }
}

struct PressFeedbackModifier: ViewModifier {
    let id: UUID
    let intensity: FeedbackIntensity
    @ObservedObject var feedbackService: VisualFeedbackService
    
    func body(content: Content) -> some View {
        let state = feedbackService.getFeedbackState(for: id)
        
        content
            .scaleEffect(state.isPressed ? intensity.scale : 1.0)
            .brightness(state.isPressed ? -0.1 : 0.0)
            .accessibleAnimation(AnimationService.quickFeedback, value: state.isPressed)
            .onLongPressGesture(minimumDuration: 0) {
                // Action handled elsewhere
            } onPressingChanged: { pressing in
                if pressing {
                    feedbackService.triggerPressResponse(for: id, intensity: intensity)
                } else {
                    feedbackService.triggerReleaseResponse(for: id)
                }
            }
    }
}

struct LoadingFeedbackModifier: ViewModifier {
    let id: UUID
    @ObservedObject var feedbackService: VisualFeedbackService
    
    @State private var rotationAngle: Double = 0
    
    func body(content: Content) -> some View {
        let state = feedbackService.getFeedbackState(for: id)
        
        ZStack {
            content
                .opacity(state.isLoading ? 0.6 : 1.0)
                .disabled(state.isLoading)
            
            if state.isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryBlue))
                        .scaleEffect(0.8)
                    
                    if let message = state.loadingMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .accessibleAnimation(AnimationService.quickFeedback, value: state.isLoading)
    }
}

struct StatusFeedbackModifier: ViewModifier {
    let id: UUID
    @ObservedObject var feedbackService: VisualFeedbackService
    
    func body(content: Content) -> some View {
        let state = feedbackService.getFeedbackState(for: id)
        
        ZStack {
            content
            
            // Success overlay
            if state.showSuccess {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.successGreen)
                        
                        Text(state.successMessage ?? "Success")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.successGreen)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.successGreen.opacity(0.1))
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Error overlay
            if state.showError {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        Text(state.errorMessage ?? "Error")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                    .errorShake(trigger: state.errorAnimationTrigger)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .accessibleAnimation(AnimationService.bouncySpring, value: state.showSuccess)
        .accessibleAnimation(AnimationService.bouncySpring, value: state.showError)
    }
}

struct ProgressFeedbackModifier: ViewModifier {
    let id: UUID
    @ObservedObject var feedbackService: VisualFeedbackService
    
    func body(content: Content) -> some View {
        let state = feedbackService.getFeedbackState(for: id)
        
        VStack(spacing: 0) {
            content
            
            if state.progress > 0 && state.progress < 1.0 {
                VStack(spacing: 4) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 3)
                            
                            Rectangle()
                                .fill(Color.primaryBlue)
                                .frame(width: geometry.size.width * state.progress, height: 3)
                                .accessibleAnimation(AnimationService.bouncySpring, value: state.progress)
                        }
                    }
                    .frame(height: 3)
                    
                    // Progress message
                    if let message = state.progressMessage {
                        HStack {
                            Text(message)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(state.progress * 100))%")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryBlue)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibleAnimation(AnimationService.bouncySpring, value: state.progress)
    }
}