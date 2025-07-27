import SwiftUI
import UIKit

// MARK: - Animated Progress Ring

struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 120, color: Color = .blue) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.7)]),
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newProgress in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Bouncy Button

struct BouncyButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    let hapticType: HapticService.FeedbackType?
    
    @State private var isPressed = false
    
    init(action: @escaping () -> Void, hapticType: HapticService.FeedbackType? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
        self.hapticType = hapticType
    }
    
    var body: some View {
        Button(action: {
            if let haptic = hapticType {
                HapticService.shared.provideFeedback(for: haptic)
            }
            action()
        }) {
            content
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Sliding Sheet

struct SlidingSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                
                VStack {
                    Spacer()
                    
                    content
                        .background(Color(.systemBackground))
                        .cornerRadius(20, corners: [.topLeft, .topRight])
                        .shadow(radius: 20)
                        .transition(.move(edge: .bottom))
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

// MARK: - Pulse Animation

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    let duration: Double
    let scale: CGFloat
    
    init(duration: Double = 1.0, scale: CGFloat = 1.1) {
        self.duration = duration
        self.scale = scale
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulseAnimation(duration: Double = 1.0, scale: CGFloat = 1.1) -> some View {
        modifier(PulseAnimation(duration: duration, scale: scale))
    }
}

// MARK: - Shake Animation

struct ShakeAnimation: ViewModifier {
    @State private var shakeOffset: CGFloat = 0
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _ in
                withAnimation(.easeInOut(duration: 0.1).repeatCount(4, autoreverses: true)) {
                    shakeOffset = 10
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    shakeOffset = 0
                }
            }
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeAnimation(trigger: trigger))
    }
}

// MARK: - Success Checkmark Animation

struct SuccessCheckmark: View {
    @State private var checkmarkScale: CGFloat = 0
    @State private var circleScale: CGFloat = 0
    @State private var showCheckmark = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 50, height: 50)
                .scaleEffect(circleScale)
            
            Image(systemName: "checkmark")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .scaleEffect(checkmarkScale)
                .opacity(showCheckmark ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                circleScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                    showCheckmark = true
                }
            }
        }
    }
}

// MARK: - Number Counter Animation

struct AnimatedCounter: View {
    let value: Double
    let formatter: NumberFormatter
    
    @State private var displayValue: Double = 0
    
    init(value: Double, formatter: NumberFormatter = NumberFormatter()) {
        self.value = value
        self.formatter = formatter
    }
    
    var body: some View {
        Text(formatter.string(from: NSNumber(value: displayValue)) ?? "0")
            .onAppear {
                animateToValue()
            }
            .onChange(of: value) { _ in
                animateToValue()
            }
    }
    
    private func animateToValue() {
        let steps = 30
        let stepValue = (value - displayValue) / Double(steps)
        
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            displayValue += stepValue
            
            if abs(displayValue - value) < abs(stepValue) {
                displayValue = value
                timer.invalidate()
            }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Loading Indicators

struct BarLoadingIndicator: View {
    @State private var isAnimating = false
    let barCount = 3
    let animationDuration = 0.6
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4, height: 20)
                    .scaleEffect(y: isAnimating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: animationDuration)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct PulseLoadingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 20, height: 20)
            .scaleEffect(isAnimating ? 1.3 : 0.7)
            .opacity(isAnimating ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Card Transition

struct CardTransition: ViewModifier {
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
    }
}

extension View {
    func cardTransition(isVisible: Bool) -> some View {
        modifier(CardTransition(isVisible: isVisible))
    }
}