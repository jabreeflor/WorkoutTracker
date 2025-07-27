import SwiftUI

/// Modern, bouncy rest timer with card design and smooth animations
struct BouncyRestTimerView: View {
    
    // MARK: - Properties
    @ObservedObject var timerService: RestTimerService
    let onMinusPressed: (() -> Void)?
    let onTimerComplete: (() -> Void)?
    
    // MARK: - State
    @State private var isVisible = false
    @State private var pulseAnimation = false
    @State private var urgencyAnimation = false
    @State private var isPressed = false
    
    // MARK: - Initialization
    init(
        timerService: RestTimerService,
        onMinusPressed: (() -> Void)? = nil,
        onTimerComplete: (() -> Void)? = nil
    ) {
        self.timerService = timerService
        self.onMinusPressed = onMinusPressed
        self.onTimerComplete = onTimerComplete
    }
    
    // MARK: - Body
    var body: some View {
        // Main timer card
        timerCard
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
            startPulseAnimation()
        }
        .onDisappear {
            isVisible = false
        }
        .onChange(of: timerService.timeRemaining) { _, remaining in
            handleTimeChange(remaining)
        }
        .onChange(of: timerService.isActive) { _, active in
            if !active && timerService.timeRemaining <= 0 {
                handleTimerCompletion()
            }
        }
    }
    
    // MARK: - Timer Card
    private var timerCard: some View {
        VStack(spacing: 24) {
            // Header
            timerHeader
            
            // Main timer display
            timerDisplay
            
            // Control buttons
            controlButtons
        }
        .padding(28)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(isPressed ? 0.05 : 0.1), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isPressed)
    }
    
    // MARK: - Timer Header
    private var timerHeader: some View {
        HStack {
            // Timer icon with animation
            ZStack {
                Circle()
                    .fill(Color.primaryBlue.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "timer")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
            }
            
            Text("Rest Timer")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Minimize button
            Button(action: minimizeTimer) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .bouncyPress(hapticFeedback: true)
            .accessibilityLabel("Minimize timer")
        }
    }
    
    // MARK: - Timer Display
    private var timerDisplay: some View {
        VStack(spacing: 20) {
            // Circular progress with time display
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: timerService.progress)
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timerService.progress)
                
                // Urgency pulse effect
                if isUrgent {
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 12)
                        .frame(width: 200, height: 200)
                        .scaleEffect(urgencyAnimation ? 1.1 : 1.0)
                        .opacity(urgencyAnimation ? 0.0 : 0.7)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false), value: urgencyAnimation)
                }
                
                // Time display
                VStack(spacing: 4) {
                    Text(timerService.formattedTimeRemaining)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(timeDisplayColor)
                        .scaleEffect(urgencyAnimation && isUrgent ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: urgencyAnimation)
                    
                    Text(timerStatusText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .shadow(
                color: timerService.isActive ? (isUrgent ? Color.red.opacity(0.3) : Color.blue.opacity(0.3)) : Color.clear,
                radius: timerService.isActive ? (isUrgent ? 20 : 12) : 0,
                x: 0,
                y: 0
            )
        }
        .accessibilityLabel("Timer: \(timerService.formattedTimeRemaining) remaining")
        .accessibilityValue(timerStatusText)
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        VStack(spacing: 16) {
            // Primary controls row
            HStack(spacing: 16) {
                // Reduce time button
                TimerControlButton(
                    icon: "minus.circle.fill",
                    text: "-15s",
                    color: .red,
                    isEnabled: timerService.isActive
                ) {
                    timerService.reduce(by: 15)
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
                
                // Pause/Resume button (larger)
                TimerControlButton(
                    icon: timerService.isPaused ? "play.circle.fill" : "pause.circle.fill",
                    text: timerService.isPaused ? "Resume" : "Pause",
                    color: .blue,
                    isLarger: true,
                    isEnabled: timerService.isActive
                ) {
                    if timerService.isPaused {
                        timerService.resume()
                    } else {
                        timerService.pause()
                    }
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
                
                // Add time button
                TimerControlButton(
                    icon: "plus.circle.fill",
                    text: "+15s",
                    color: .green,
                    isEnabled: timerService.isActive
                ) {
                    timerService.extend(by: 15)
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
            
            // Secondary controls row
            HStack(spacing: 16) {
                // Undo last set button
                TimerControlButton(
                    icon: "arrow.uturn.backward.circle.fill",
                    text: "Undo Set",
                    color: .orange,
                    isEnabled: true
                ) {
                    onMinusPressed?()
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
                
                // Skip button
                TimerControlButton(
                    icon: "forward.end.circle.fill",
                    text: "Skip",
                    color: .gray,
                    isEnabled: timerService.isActive
                ) {
                    timerService.stop()
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
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
        RoundedRectangle(cornerRadius: 24)
            .stroke(
                isUrgent ? 
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red.opacity(0.6), Color.orange.opacity(0.4)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                lineWidth: 2
            )
    }
    
    private var progressGradient: AngularGradient {
        let colors = timerProgressColors(progress: timerService.progress)
        return AngularGradient(
            colors: colors,
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
    
    private func timerProgressColors(progress: Double) -> [Color] {
        if progress > 0.6 {
            return [Color.green, Color.mint]
        } else if progress > 0.3 {
            return [Color.orange, Color.yellow]
        } else {
            return [Color.red, Color.pink]
        }
    }
    
    private var timeDisplayColor: Color {
        if isUrgent {
            return .red
        } else if timerService.isPaused {
            return .gray
        } else {
            return .primary
        }
    }
    
    private var timerStatusText: String {
        if !timerService.isActive {
            return "Timer stopped"
        } else if timerService.isPaused {
            return "Paused"
        } else if isUrgent {
            return "Almost done!"
        } else {
            return "Rest time"
        }
    }
    
    private var isUrgent: Bool {
        return timerService.isActive && timerService.timeRemaining <= 10 && timerService.timeRemaining > 0
    }
    
    // MARK: - Action Handlers
    
    private func minimizeTimer() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isVisible = false
        }
        
        // Stop the timer service to trigger the parent view's animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            timerService.stop()
        }
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func startPulseAnimation() {
        pulseAnimation = true
    }
    
    private func handleTimeChange(_ remaining: TimeInterval) {
        // Start urgency animation when time is low
        if remaining <= 10 && remaining > 0 && !urgencyAnimation {
            urgencyAnimation = true
        } else if remaining > 10 && urgencyAnimation {
            urgencyAnimation = false
        }
        
        // Haptic feedback for final countdown
        if remaining <= 3 && remaining > 0 && Int(remaining) != Int(remaining + 1) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    private func handleTimerCompletion() {
        onTimerComplete?()
        
        // Provide success haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Reset animations
        urgencyAnimation = false
        pulseAnimation = false
    }
}

// MARK: - Timer Control Button

struct TimerControlButton: View {
    let icon: String
    let text: String
    let color: Color
    var isLarger: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(buttonBackground)
                        .frame(width: buttonSize, height: buttonSize)
                        .overlay(
                            Circle()
                                .stroke(buttonBorder, lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(isPressed ? 0.05 : 0.1), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
            }
        }
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) {
            // Action handled by button
        } onPressingChanged: { pressing in
            isPressed = pressing
            
            if pressing {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        }
        .accessibilityLabel(text)
        .accessibilityHint("Timer control button")
    }
    
    private var buttonSize: CGFloat {
        isLarger ? 64 : 48
    }
    
    private var iconSize: CGFloat {
        isLarger ? 28 : 20
    }
    
    private var buttonBackground: LinearGradient {
        if !isEnabled {
            return LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isPressed {
            return LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.8),
                    color.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.15),
                    color.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var buttonBorder: Color {
        if !isEnabled {
            return .gray.opacity(0.3)
        } else if isPressed {
            return color
        } else {
            return color.opacity(0.4)
        }
    }
    
    private var iconColor: Color {
        if !isEnabled {
            return .gray
        } else if isPressed {
            return .white
        } else {
            return color
        }
    }
    
    private var textColor: Color {
        if !isEnabled {
            return .gray
        } else {
            return color
        }
    }
}

// MARK: - Preview

struct BouncyRestTimerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Active timer
            let activeTimer = RestTimerService()
            BouncyRestTimerView(
                timerService: activeTimer,
                onMinusPressed: {
                    print("Minus pressed - would uncomplete most recent set")
                },
                onTimerComplete: {
                    print("Timer completed!")
                }
            )
            .onAppear {
                activeTimer.start(duration: 90)
            }
            .previewDisplayName("Active Timer")
            
            // Paused timer
            let pausedTimer = RestTimerService()
            BouncyRestTimerView(
                timerService: pausedTimer,
                onMinusPressed: {
                    print("Minus pressed - would uncomplete most recent set")
                },
                onTimerComplete: {
                    print("Timer completed!")
                }
            )
            .onAppear {
                pausedTimer.start(duration: 60)
                pausedTimer.pause()
            }
            .previewDisplayName("Paused Timer")
            
            // Urgent timer (final seconds)
            let urgentTimer = RestTimerService()
            BouncyRestTimerView(
                timerService: urgentTimer,
                onMinusPressed: {
                    print("Minus pressed - would uncomplete most recent set")
                },
                onTimerComplete: {
                    print("Timer completed!")
                }
            )
            .onAppear {
                urgentTimer.start(duration: 8)
            }
            .previewDisplayName("Urgent Timer")
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}