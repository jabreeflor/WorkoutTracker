import SwiftUI

struct RestTimerView: View {
    @ObservedObject var timerService: RestTimerService
    @State private var animateTimer: Bool = false
    @State private var progressGlow: Bool = false
    @State private var isVisible: Bool = false
    
    // Callback for when minus button is pressed
    var onMinusPressed: (() -> Void)?
    
    init(timerService: RestTimerService, onMinusPressed: (() -> Void)? = nil) {
        self.timerService = timerService
        self.onMinusPressed = onMinusPressed
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Timer header with enhanced styling
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .scaleEffect(animateTimer ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateTimer)
                }
                
                Text("Rest Timer")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                // Minimize button
                Button(action: {
                    // This would minimize/collapse the timer
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            
            // Enhanced timer display matching the design from image
            VStack(spacing: 16) {
                // Large timer display
                Text(timerService.formattedTimeRemaining)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                    .scaleEffect(animateTimer ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.5), value: animateTimer)
                
                // Enhanced progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: geometry.size.width, height: 8)
                        
                        // Progress with gradient and glow
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: progressGradientColors),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * timerService.progress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: timerService.progress)
                    }
                }
                .frame(height: 8)
            }
            
            // Enhanced control buttons matching the image design
            HStack(spacing: 20) {
                // Reduce time button
                TimerControlButton(
                    icon: "minus.circle.fill",
                    text: "-15s",
                    color: .red,
                    action: { 
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        timerService.reduce(by: 15)
                        
                        // Trigger the callback to uncomplete the most recent set
                        onMinusPressed?()
                    }
                )
                
                // Pause/Resume button (larger)
                TimerControlButton(
                    icon: timerService.isPaused ? "play.circle.fill" : "pause.circle.fill",
                    text: timerService.isPaused ? "Resume" : "Pause",
                    color: .blue,
                    isLarger: true,
                    action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        if timerService.isPaused {
                            timerService.resume()
                        } else {
                            timerService.pause()
                        }
                    }
                )
                
                // Skip button
                TimerControlButton(
                    icon: "forward.end.circle.fill",
                    text: "Skip",
                    color: .gray,
                    action: { 
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        timerService.stop() 
                    }
                )
                
                // Add time button
                TimerControlButton(
                    icon: "plus.circle.fill",
                    text: "+15s",
                    color: .green,
                    action: { 
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        timerService.extend(by: 15) 
                    }
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
            progressGlow = true
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if timerService.timeRemaining <= 10 && timerService.timeRemaining > 0 {
                animateTimer.toggle()
            }
        }
    }
    
    // MARK: - Computed Properties
    private var progressGradientColors: [Color] {
        let progress = timerService.progress
        if progress > 0.6 {
            return [Color.green, Color.mint]
        } else if progress > 0.3 {
            return [Color.orange, Color.yellow]
        } else {
            return [Color.red, Color.pink]
        }
    }
}

// MARK: - Timer Control Button Component
struct TimerControlButton: View {
    let icon: String
    let text: String
    let color: Color
    var isLarger: Bool = false
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: isLarger ? 60 : 44, height: isLarger ? 60 : 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: isLarger ? 28 : 20, weight: .medium))
                        .foregroundColor(color)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) {
            // Action handled in button action
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

struct RestTimerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Active timer
            let activeTimer = RestTimerService()
            RestTimerView(timerService: activeTimer, onMinusPressed: {
                print("Minus pressed - would uncomplete most recent set")
            })
                .onAppear {
                    activeTimer.start(duration: 90)
                }
                .previewDisplayName("Active Timer")
            
            // Paused timer
            let pausedTimer = RestTimerService()
            RestTimerView(timerService: pausedTimer, onMinusPressed: {
                print("Minus pressed - would uncomplete most recent set")
            })
                .onAppear {
                    pausedTimer.start(duration: 60)
                    pausedTimer.pause()
                }
                .previewDisplayName("Paused Timer")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}