import SwiftUI

/// Service for managing consistent animations throughout the app
class AnimationService: ObservableObject {
    static let shared = AnimationService()
    
    private init() {}
    
    // MARK: - Standard Animation Curves
    
    /// Bouncy spring animation for interactive elements
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    
    /// Quick feedback animation for immediate responses
    static let quickFeedback = Animation.easeInOut(duration: 0.2)
    
    /// Smooth transition animation for state changes
    static let smoothTransition = Animation.easeInOut(duration: 0.3)
    
    /// Celebration animation for achievements
    static let celebration = Animation.spring(response: 0.8, dampingFraction: 0.6)
    
    /// Gentle animation for subtle effects
    static let gentle = Animation.easeInOut(duration: 0.4)
    
    // MARK: - Animation State Management
    
    @Published var activeAnimations: Set<UUID> = []
    
    func startAnimation(id: UUID) {
        activeAnimations.insert(id)
    }
    
    func endAnimation(id: UUID) {
        activeAnimations.remove(id)
    }
    
    func isAnimating(id: UUID) -> Bool {
        return activeAnimations.contains(id)
    }
    
    // MARK: - Performance Monitoring
    
    private var performanceMode: PerformanceMode = .normal
    
    enum PerformanceMode {
        case normal
        case reduced
        case minimal
    }
    
    func setPerformanceMode(_ mode: PerformanceMode) {
        performanceMode = mode
    }
    
    func animationForPerformance<V>(_ animation: Animation, value: V) -> Animation where V: Equatable {
        switch performanceMode {
        case .normal:
            return animation
        case .reduced:
            return animation.speed(1.5) // Faster animations
        case .minimal:
            return .linear(duration: 0.1) // Minimal animations
        }
    }
    
    // MARK: - Performance Optimization Methods
    
    func reduceAnimationComplexity() {
        setPerformanceMode(.reduced)
    }
    
    func restoreAnimationComplexity() {
        setPerformanceMode(.normal)
    }
    
    func cleanupUnusedStates() {
        // Remove completed animations that are no longer needed
        activeAnimations.removeAll()
    }
    
    // MARK: - Missing Methods for AnimatedInputControl
    
    /// Updates animation state for a specific control
    func updateState(for controlId: UUID, update: @escaping () -> Void) {
        // For now, just execute the update block
        // In a real implementation, this would manage per-control state
        print("Updating state for control: \(controlId.uuidString)")
        update()
    }
    
    /// Removes animation state for a specific control
    func removeState(for controlId: UUID) {
        // Clean up any stored state for this control
        // This is a placeholder implementation
        print("Removing state for control: \(controlId.uuidString)")
    }
    
    /// Triggers editing animation for a control
    func triggerEditing(for controlId: UUID, editing: Bool) {
        // Trigger visual feedback for editing state changes
        // This is a placeholder implementation
        print("Trigger editing for control \(controlId.uuidString): \(editing)")
    }
}