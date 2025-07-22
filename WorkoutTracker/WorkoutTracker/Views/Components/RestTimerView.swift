import SwiftUI

struct RestTimerView: View {
    @ObservedObject var timerService: RestTimerService
    
    var body: some View {
        VStack(spacing: 12) {
            // Timer header
            HStack {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Rest Timer")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                // Minimize button (placeholder for future implementation)
                Button(action: {
                    // Minimize timer view (to be implemented)
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.gray)
                }
            }
            
            // Timer display
            Text(timerService.formattedTimeRemaining)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
                .frame(height: 60)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width, height: 8)
                        .cornerRadius(4)
                    
                    // Progress
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * timerService.progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Control buttons
            HStack(spacing: 20) {
                // Reduce time button
                Button(action: {
                    timerService.reduce(by: 15)
                }) {
                    VStack {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                        Text("-15s")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
                
                // Pause/Resume button
                Button(action: {
                    if timerService.isPaused {
                        timerService.resume()
                    } else {
                        timerService.pause()
                    }
                }) {
                    VStack {
                        Image(systemName: timerService.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.title)
                        Text(timerService.isPaused ? "Resume" : "Pause")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                
                // Skip button
                Button(action: {
                    timerService.stop()
                }) {
                    VStack {
                        Image(systemName: "forward.end.circle.fill")
                            .font(.title2)
                        Text("Skip")
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
                
                // Add time button
                Button(action: {
                    timerService.extend(by: 15)
                }) {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("+15s")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding()
    }
}

struct RestTimerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Active timer
            let activeTimer = RestTimerService()
            RestTimerView(timerService: activeTimer)
                .onAppear {
                    activeTimer.start(duration: 90)
                }
                .previewDisplayName("Active Timer")
            
            // Paused timer
            let pausedTimer = RestTimerService()
            RestTimerView(timerService: pausedTimer)
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