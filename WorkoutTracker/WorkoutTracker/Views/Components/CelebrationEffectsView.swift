import SwiftUI

/// View for displaying celebration effects like confetti and sparkles
struct CelebrationEffectsView: View {
    let effect: CelebrationEffect
    let duration: TimeInterval
    let onComplete: () -> Void
    
    @State private var isAnimating = false
    @State private var particles: [Particle] = []
    
    init(effect: CelebrationEffect, duration: TimeInterval, onComplete: @escaping () -> Void = {}) {
        self.effect = effect
        self.duration = duration
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            switch effect {
            case .confetti(let colors, let count):
                confettiEffect(colors: colors, count: count)
            case .sparkles(let color, let intensity):
                sparklesEffect(color: color, intensity: intensity)
            case .glow(let color, let radius):
                glowEffect(color: color, radius: radius)
            case .bounce(let scale, let duration):
                bounceEffect(scale: scale, duration: duration)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Confetti Effect
    private func confettiEffect(colors: [Color], count: Int) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                ConfettiParticle(
                    color: colors.randomElement() ?? .blue,
                    isAnimating: isAnimating
                )
                .offset(
                    x: CGFloat.random(in: -200...200),
                    y: CGFloat.random(in: -300...100)
                )
            }
        }
    }
    
    // MARK: - Sparkles Effect
    private func sparklesEffect(color: Color, intensity: Float) -> some View {
        ZStack {
            ForEach(0..<Int(intensity * 20), id: \.self) { index in
                SparkleParticle(
                    color: color,
                    isAnimating: isAnimating
                )
                .offset(
                    x: CGFloat.random(in: -150...150),
                    y: CGFloat.random(in: -150...150)
                )
            }
        }
    }
    
    // MARK: - Glow Effect
    private func glowEffect(color: Color, radius: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.3))
            .frame(width: radius * 2, height: radius * 2)
            .blur(radius: radius / 2)
            .scaleEffect(isAnimating ? 1.5 : 0.5)
            .opacity(isAnimating ? 0.0 : 1.0)
            .accessibleAnimation(.easeOut(duration: duration), value: isAnimating)
    }
    
    // MARK: - Bounce Effect
    private func bounceEffect(scale: CGFloat, duration: TimeInterval) -> some View {
        Rectangle()
            .fill(Color.clear)
            .scaleEffect(isAnimating ? scale : 1.0)
            .accessibleAnimation(
                .spring(response: duration * 0.6, dampingFraction: 0.6),
                value: isAnimating
            )
    }
    
    // MARK: - Animation Control
    private func startAnimation() {
        withAnimation {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            onComplete()
        }
    }
}

// MARK: - Celebration Effect Types
enum CelebrationEffect {
    case confetti(colors: [Color], count: Int)
    case sparkles(color: Color, intensity: Float)
    case glow(color: Color, radius: CGFloat)
    case bounce(scale: CGFloat, duration: TimeInterval)
}

// MARK: - Confetti Particle
struct ConfettiParticle: View {
    let color: Color
    let isAnimating: Bool
    
    @State private var rotation: Double = 0
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .offset(y: yOffset)
            .accessibleAnimation(
                .linear(duration: 2.0).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                if isAnimating {
                    rotation = Double.random(in: 0...360)
                    yOffset = 400
                }
            }
    }
}

// MARK: - Sparkle Particle
struct SparkleParticle: View {
    let color: Color
    let isAnimating: Bool
    
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Image(systemName: "sparkle")
            .foregroundColor(color)
            .scaleEffect(scale)
            .opacity(opacity)
            .accessibleAnimation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                if isAnimating {
                    scale = CGFloat.random(in: 0.5...1.5)
                    opacity = Double.random(in: 0.3...1.0)
                }
            }
    }
}

// MARK: - Particle Data Model
struct Particle {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let position: CGPoint
    let velocity: CGPoint
    let rotation: Double
    let lifespan: TimeInterval
}

// MARK: - Preview
struct CelebrationEffectsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CelebrationEffectsView(
                effect: .confetti(colors: [.red, .blue, .green, .yellow], count: 50),
                duration: 2.0
            )
            .previewDisplayName("Confetti")
            
            CelebrationEffectsView(
                effect: .sparkles(color: .celebrationGold, intensity: 0.8),
                duration: 1.5
            )
            .previewDisplayName("Sparkles")
            
            CelebrationEffectsView(
                effect: .glow(color: .blue, radius: 50),
                duration: 1.0
            )
            .previewDisplayName("Glow")
        }
        .frame(width: 300, height: 300)
        .background(Color.black.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}