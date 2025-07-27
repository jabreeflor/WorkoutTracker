import SwiftUI

/// Enhanced rest timer view with improved controls and feedback
struct EnhancedRestTimerView: View {
    @StateObject private var restTimerService = RestTimerService.shared
    @EnvironmentObject private var hapticService: HapticService
    
    // Animation states
    @State private var isTimerExpanded = false
    @State private var showControls = false
    @State private var animateProgress = false
    
    // User interaction states
    @State private var showingAdjustControls = false
    @State private var adjustmentAmount: TimeInterval = 30
    
    var body: some View {
        ZStack {
            // Timer is inactive - show minimized view
            if !restTimerService.isActive {
                miniRestTimerView
            } else {
                // Timer is active - show full timer UI
                VStack(spacing: 12) {
                    // Timer display
                    ZStack {
                        // Progress circle
                        Circle()
                            .stroke(lineWidth: 8)
                            .opacity(0.3)
                            .foregroundColor(Color.blue)
                        
                        Circle()
                            .trim(from: 0.0, to: animateProgress ? restTimerService.progress : 0)
                            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                            .foregroundColor(getTimerColor())
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear(duration: 0.25), value: restTimerService.progress)
                        
                        VStack(spacing: 4) {
                            Text(restTimerService.formattedTimeRemaining)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .contentTransition(.numericText())
                            
                            if let restTimeSource = restTimerService.restTimeSource {
                                Text(restTimeSource.description)
                                    .font(.caption)
                                    .foregroundColor(restTimeSource.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(restTimeSource.color.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .frame(width: 180, height: 180)
                    .onAppear {
                        // Delayed animation of the progress circle
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            animateProgress = true
                        }
                    }
                    
                    // Timer controls
                    HStack(spacing: 24) {
                        // Skip button
                        Button(action: {
                            restTimerService.stop()
                            hapticService.provideFeedback(for: .success)
                        }) {
                            VStack {
                                Image(systemName: "stop.fill")
                                    .font(.title2)
                                Text("Stop")
                                    .font(.caption)
                            }
                            .frame(width: 60)
                            .foregroundColor(.red)
                        }
                        
                        // Pause/Resume button
                        Button(action: {
                            if restTimerService.isPaused {
                                restTimerService.resume()
                            } else {
                                restTimerService.pause()
                            }
                            hapticService.provideFeedback(for: .selection)
                        }) {
                            VStack {
                                Image(systemName: restTimerService.isPaused ? "play.fill" : "pause.fill")
                                    .font(.title2)
                                Text(restTimerService.isPaused ? "Resume" : "Pause")
                                    .font(.caption)
                            }
                            .frame(width: 60)
                            .foregroundColor(.primary)
                        }
                        
                        // Adjust button
                        Button(action: {
                            showingAdjustControls.toggle()
                            hapticService.provideFeedback(for: .selection)
                        }) {
                            VStack {
                                Image(systemName: "timer")
                                    .font(.title2)
                                Text("Adjust")
                                    .font(.caption)
                            }
                            .frame(width: 60)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Time adjustment controls
                    if showingAdjustControls {
                        VStack(spacing: 12) {
                            Text("Adjust Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    restTimerService.reduce(by: adjustmentAmount)
                                    hapticService.provideFeedback(for: .impact(.light))
                                }) {
                                    Label("-\(Int(adjustmentAmount))s", systemImage: "minus.circle.fill")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.2))
                                        .cornerRadius(8)
                                        .foregroundColor(.red)
                                }
                                
                                Button(action: {
                                    restTimerService.extend(by: adjustmentAmount)
                                    hapticService.provideFeedback(for: .impact(.light))
                                }) {
                                    Label("+\(Int(adjustmentAmount))s", systemImage: "plus.circle.fill")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(8)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            // Adjustment amount picker
                            Picker("Adjust by", selection: $adjustmentAmount) {
                                Text("15s").tag(TimeInterval(15))
                                Text("30s").tag(TimeInterval(30))
                                Text("60s").tag(TimeInterval(60))
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground).opacity(0.95))
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding()
            }
        }
        .animation(.spring(), value: restTimerService.isActive)
        .animation(.spring(), value: showingAdjustControls)
    }
    
    // MARK: - Mini Timer View
    
    private var miniRestTimerView: some View {
        Button(action: {
            // Show timer configuration sheet
            // This would be replaced with actual timer start logic
            startDefaultTimer()
        }) {
            HStack {
                Image(systemName: "timer")
                    .font(.title3)
                Text("Start Rest Timer")
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns a color based on the current timer progress
    private func getTimerColor() -> Color {
        let progress = restTimerService.progress
        
        if restTimerService.isPaused {
            return .gray
        } else if progress < 0.5 {
            return .blue
        } else if progress < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
    
    /// Starts a default timer for testing
    private func startDefaultTimer() {
        restTimerService.start(duration: 90, source: .globalDefault)
        hapticService.provideFeedback(for: .success)
        animateProgress = false
        
        // Restart animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateProgress = true
        }
    }
}

// MARK: - Preview

struct EnhancedRestTimerView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedRestTimerView()
            .environmentObject(HapticService.shared)
    }
}
