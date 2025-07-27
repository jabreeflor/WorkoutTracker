import SwiftUI

extension View {
    /// Adds a bouncy press animation to any view
    func bouncyPress(
        scale: CGFloat = 0.95,
        hapticFeedback: Bool = false,
        onPress: (() -> Void)? = nil,
        onRelease: (() -> Void)? = nil
    ) -> some View {
        self.modifier(BouncyPressModifier(
            scale: scale,
            hapticFeedback: hapticFeedback,
            onPress: onPress,
            onRelease: onRelease
        ))
    }
    
    /// Adds a glow shadow effect
    func glowShadow(
        color: Color,
        radius: CGFloat,
        isActive: Bool = true
    ) -> some View {
        self.shadow(
            color: isActive ? color.opacity(0.3) : Color.clear,
            radius: isActive ? radius : 0,
            x: 0,
            y: 0
        )
    }
    
    /// Adds a card shadow effect
    func cardShadow(isPressed: Bool = false) -> some View {
        self.shadow(
            color: Color.black.opacity(isPressed ? 0.05 : 0.1),
            radius: isPressed ? 4 : 8,
            x: 0,
            y: isPressed ? 2 : 4
        )
    }
    
    /// Accessibility-aware animation
    func accessibleAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            return self.animation(.linear(duration: 0.1), value: value)
        } else {
            return self.animation(animation, value: value)
        }
    }
    
    /// Adds a glow effect to any view
    func glowEffect(isActive: Bool = true, color: Color = .blue, radius: CGFloat = 8) -> some View {
        self.shadow(
            color: isActive ? color.opacity(0.5) : Color.clear,
            radius: isActive ? radius : 0,
            x: 0,
            y: 0
        )
    }
}

// MARK: - Bouncy Press Modifier

struct BouncyPressModifier: ViewModifier {
    let scale: CGFloat
    let hapticFeedback: Bool
    let onPress: (() -> Void)?
    let onRelease: (() -> Void)?
    
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .accessibleAnimation(AnimationService.bouncySpring, value: isPressed)
            .onLongPressGesture(minimumDuration: 0) {
                // Action handled elsewhere
            } onPressingChanged: { pressing in
                isPressed = pressing
                
                if pressing {
                    onPress?()
                    if hapticFeedback {
                        HapticService.shared.bouncyPress()
                    }
                } else {
                    onRelease?()
                    if hapticFeedback {
                        HapticService.shared.bouncyRelease()
                    }
                }
            }
    }
}