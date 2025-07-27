import SwiftUI

// MARK: - Enhanced Set Tracking Extensions
extension View {
    /// Adds a bounce animation when tapped
    /// - Parameters:
    ///   - scale: The scale factor during the bounce
    ///   - duration: The duration of the animation
    /// - Returns: A view with bounce animation
    func bounceOnTap(scale: CGFloat = 0.95, duration: Double = 0.1) -> some View {
        self.bouncyPress(scale: scale, hapticFeedback: true)
    }
}

// MARK: - Animation Modifiers
// Note: BouncyButtonModifier is now defined in View+BouncyAnimations.swift

// MARK: - Haptic Feedback
enum HapticFeedbackType {
    case setCompletion(isCompleted: Bool)
    case timerAction(TimerAction)
    case buttonPress
    
    enum TimerAction {
        case start
        case pause
        case resume
        case complete
    }
}

// MARK: - Enhanced Bouncy Button for Set Tracking
struct EnhancedBouncyButton<Content: View>: View {
    let action: () -> Void
    let hapticType: HapticFeedbackType
    let content: Content
    
    @State private var isPressed = false
    
    init(action: @escaping () -> Void, hapticType: HapticFeedbackType = .buttonPress, @ViewBuilder content: () -> Content) {
        self.action = action
        self.hapticType = hapticType
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            isPressed = true
            
            // Provide haptic feedback
            switch hapticType {
            case .setCompletion(let isCompleted):
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(isCompleted ? .success : .warning)
                
            case .timerAction(let timerAction):
                switch timerAction {
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
                
            case .buttonPress:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            
            // Perform the action
            action()
            
            // Reset after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            content
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
    }
}