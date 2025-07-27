import SwiftUI

/// Enhanced feedback animations for error and success states
struct FeedbackAnimationsView: View {
    
    // MARK: - Properties
    let type: FeedbackType
    let message: String
    let isVisible: Bool
    let onDismiss: (() -> Void)?
    
    // MARK: - State
    @State private var animationPhase: AnimationPhase = .hidden
    @State private var bounceScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0.0
    @State private var particles: [FeedbackParticle] = []
    
    // MARK: - Initialization
    init(
        type: FeedbackType,
        message: String,
        isVisible: Bool,
        onDismiss: (() -> Void)? = nil
    ) {
        self.type = type
        self.message = message
        self.isVisible = isVisible
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if animationPhase != .hidden {
                feedbackContainer
                    .transition(feedbackTransition)
            }
        }
        .onChange(of: isVisible) { _, visible in
            if visible {
                showFeedback()
            } else {
                hideFeedback()
            }
        }
    }
    
    // MARK: - Feedback Container
    private var feedbackContainer: some View {
        ZStack {
            // Background overlay
            backgroundOverlay
            
            // Main feedback card
            feedbackCard
            
            // Particle effects
            particleEffects
        }
    }
    
    // MARK: - Background Overlay
    private var backgroundOverlay: some View {
        Rectangle()
            .fill(Color.black.opacity(0.3))
            .ignoresSafeArea()
            .opacity(animationPhase == .visible ? 1.0 : 0.0)
            .accessibleAnimation(AnimationService.quickFeedback, value: animationPhase)
            .onTapGesture {
                hideFeedback()
            }
    }
    
    // MARK: - Feedback Card
    private var feedbackCard: some View {
        VStack(spacing: 16) {
            // Icon with animation
            feedbackIcon
            
            // Message
            Text(message)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            // Action button (if needed)
            if type == .error {
                Button("Dismiss") {
                    hideFeedback()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red)
                )
                .bouncyPress(hapticFeedback: true)
            }
        }
        .padding(24)
        .background(cardBackground)
        .overlay(cardBorder)
        .cardShadow()
        .scaleEffect(bounceScale)
        .glowShadow(
            color: glowColor,
            radius: 16,
            isActive: glowIntensity > 0
        )
        .opacity(glowIntensity)
        .accessibleAnimation(AnimationService.celebration, value: bounceScale)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.accessibilityLabel): \(message)")
    }
    
    // MARK: - Feedback Icon
    private var feedbackIcon: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(iconBackgroundGradient)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(iconBorderGradient, lineWidth: 3)
                )
                .glowShadow(
                    color: glowColor,
                    radius: 20,
                    isActive: glowIntensity > 0.5
                )
            
            // Icon
            Image(systemName: type.iconName)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(bounceScale)
            
            // Pulse effect for success
            if type == .success && animationPhase == .visible {
                Circle()
                    .stroke(Color.successGreen.opacity(0.4), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(bounceScale * 1.2)
                    .opacity(1.0 - glowIntensity)
                    .accessibleAnimation(
                        .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                        value: animationPhase
                    )
            }
        }
    }
    
    // MARK: - Particle Effects
    private var particleEffects: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                FeedbackParticleView(particle: particle, isActive: animationPhase == .visible)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var feedbackTransition: AnyTransition {
        switch type {
        case .success:
            return .asymmetric(
                insertion: .scale(scale: 0.3).combined(with: .opacity),
                removal: .scale(scale: 1.2).combined(with: .opacity)
            )
        case .error:
            return .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        case .warning:
            return .asymmetric(
                insertion: .slide.combined(with: .opacity),
                removal: .slide.combined(with: .opacity)
            )
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        type.primaryColor.opacity(0.6),
                        type.primaryColor.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
    }
    
    private var iconBackgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                type.primaryColor,
                type.secondaryColor
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var iconBorderGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                type.accentColor,
                type.primaryColor
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var textColor: Color {
        type.primaryColor
    }
    
    private var glowColor: Color {
        type.primaryColor
    }
    
    // MARK: - Animation Control
    
    private func showFeedback() {
        animationPhase = .appearing
        generateParticles()
        
        // Initial bounce animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            bounceScale = 1.1
            glowIntensity = 1.0
        }
        
        // Settle animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
            bounceScale = 1.0
            animationPhase = .visible
        }
        
        // Trigger haptic feedback
        switch type {
        case .success:
            HapticService.shared.celebration()
        case .error:
            HapticService.shared.provideFeedback(for: .error)
        case .warning:
            HapticService.shared.provideFeedback(for: .warning)
        }
        
        // Auto-dismiss for success
        if type == .success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                hideFeedback()
            }
        }
    }
    
    private func hideFeedback() {
        animationPhase = .disappearing
        
        withAnimation(.easeOut(duration: 0.3)) {
            bounceScale = 0.8
            glowIntensity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animationPhase = .hidden
            onDismiss?()
        }
    }
    
    private func generateParticles() {
        guard type == .success else { return }
        
        particles = (0..<12).map { index in
            FeedbackParticle(
                id: UUID(),
                color: [Color.successGreen, Color.mint, Color.celebrationGold].randomElement() ?? .successGreen,
                startPosition: CGPoint.zero,
                endPosition: CGPoint(
                    x: CGFloat.random(in: -100...100),
                    y: CGFloat.random(in: -100...100)
                ),
                size: CGFloat.random(in: 4...8),
                animationDelay: Double(index) * 0.05
            )
        }
    }
}

// MARK: - Feedback Type

enum FeedbackType {
    case success, error, warning
    
    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .success: return .successGreen
        case .error: return .red
        case .warning: return .orange
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .success: return .mint
        case .error: return .pink
        case .warning: return .yellow
        }
    }
    
    var accentColor: Color {
        switch self {
        case .success: return .celebrationGold
        case .error: return .red
        case .warning: return .orange
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .success: return "Success"
        case .error: return "Error"
        case .warning: return "Warning"
        }
    }
}

// MARK: - Animation Phase

enum AnimationPhase {
    case hidden, appearing, visible, disappearing
}

// MARK: - Feedback Particle

struct FeedbackParticle {
    let id: UUID
    let color: Color
    let startPosition: CGPoint
    let endPosition: CGPoint
    let size: CGFloat
    let animationDelay: TimeInterval
}

// MARK: - Feedback Particle View

struct FeedbackParticleView: View {
    let particle: FeedbackParticle
    let isActive: Bool
    
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(position)
            .onAppear {
                position = particle.startPosition
            }
            .onChange(of: isActive) { _, active in
                if active {
                    animateParticle()
                }
            }
    }
    
    private func animateParticle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + particle.animationDelay) {
            withAnimation(.easeOut(duration: 1.0)) {
                position = particle.endPosition
                opacity = 0.0
                scale = 0.5
            }
        }
    }
}

// MARK: - Convenience Extensions

extension View {
    
    /// Add success feedback overlay
    func successFeedback(
        message: String,
        isVisible: Binding<Bool>
    ) -> some View {
        overlay(
            FeedbackAnimationsView(
                type: .success,
                message: message,
                isVisible: isVisible.wrappedValue
            ) {
                isVisible.wrappedValue = false
            }
        )
    }
    
    /// Add error feedback overlay
    func errorFeedback(
        message: String,
        isVisible: Binding<Bool>
    ) -> some View {
        overlay(
            FeedbackAnimationsView(
                type: .error,
                message: message,
                isVisible: isVisible.wrappedValue
            ) {
                isVisible.wrappedValue = false
            }
        )
    }
    
    /// Add warning feedback overlay
    func warningFeedback(
        message: String,
        isVisible: Binding<Bool>
    ) -> some View {
        overlay(
            FeedbackAnimationsView(
                type: .warning,
                message: message,
                isVisible: isVisible.wrappedValue
            ) {
                isVisible.wrappedValue = false
            }
        )
    }
}

// MARK: - Preview

struct FeedbackAnimationsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Success feedback
            FeedbackAnimationsView(
                type: .success,
                message: "Set completed successfully!",
                isVisible: true
            )
            .previewDisplayName("Success Feedback")
            
            // Error feedback
            FeedbackAnimationsView(
                type: .error,
                message: "Invalid weight value entered",
                isVisible: true
            )
            .previewDisplayName("Error Feedback")
            
            // Warning feedback
            FeedbackAnimationsView(
                type: .warning,
                message: "Rest timer will expire soon",
                isVisible: true
            )
            .previewDisplayName("Warning Feedback")
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}