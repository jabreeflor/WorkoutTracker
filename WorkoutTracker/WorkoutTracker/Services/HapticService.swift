import Foundation
import UIKit

/// Haptic feedback context for different UI interactions
enum HapticContext {
    case button
    case success
    case error
    case warning
    case selection
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case setCompletion(isCompleted: Bool)
    case timerAction(TimerAction)
    
    enum TimerAction {
        case start
        case pause
        case resume
        case complete
    }
}

/// Service for providing haptic feedback throughout the app
class HapticService {
    static let shared = HapticService()
    
    private init() {}
    
    /// Provides appropriate haptic feedback based on the context
    func provideFeedback(for context: HapticContext) {
        switch context {
        case .button:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            
        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
            
        case .setCompletion(let isCompleted):
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(isCompleted ? .success : .warning)
            
        case .timerAction(let action):
            switch action {
            case .start, .resume:
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            case .pause:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            case .complete:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Provides button tap haptic feedback
    func buttonTapped() {
        provideFeedback(for: .button)
    }
    
    /// Provides success haptic feedback
    func success() {
        provideFeedback(for: .success)
    }
    
    /// Provides value changed haptic feedback
    func valueChanged() {
        provideFeedback(for: .selection)
    }
    
    /// Provides template created haptic feedback
    func templateCreated() {
        provideFeedback(for: .success)
    }
    
    /// Provides error haptic feedback
    func error() {
        provideFeedback(for: .error)
    }
}