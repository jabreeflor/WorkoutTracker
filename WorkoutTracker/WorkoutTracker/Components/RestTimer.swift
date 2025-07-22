import SwiftUI
import Combine
import UserNotifications

class RestTimer: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var totalTime: Int = 0
    
    private var timer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    init() {
        requestNotificationPermission()
    }
    
    deinit {
        stop()
    }
    
    func start(duration: Int) {
        stop() // Stop any existing timer
        
        totalTime = duration
        timeRemaining = duration
        isActive = true
        isPaused = false
        
        startBackgroundTask()
        startTimer()
        scheduleNotification()
    }
    
    func pause() {
        guard isActive && !isPaused else { return }
        
        isPaused = true
        timer?.invalidate()
        timer = nil
        cancelNotification()
        endBackgroundTask()
    }
    
    func resume() {
        guard isActive && isPaused else { return }
        
        isPaused = false
        startBackgroundTask()
        startTimer()
        scheduleNotification()
    }
    
    func stop() {
        isActive = false
        isPaused = false
        timeRemaining = 0
        totalTime = 0
        
        timer?.invalidate()
        timer = nil
        cancelNotification()
        endBackgroundTask()
    }
    
    func skip() {
        stop()
        triggerCompletionFeedback()
    }
    
    func addTime(_ seconds: Int) {
        timeRemaining += seconds
        totalTime += seconds
        
        if isActive && !isPaused {
            // Reschedule notification with new time
            cancelNotification()
            scheduleNotification()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.complete()
            }
        }
    }
    
    private func complete() {
        stop()
        triggerCompletionFeedback()
    }
    
    private func triggerCompletionFeedback() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Play system sound (optional)
        AudioServicesPlaySystemSound(1007) // System sound for completion
    }
    
    // MARK: - Background Support
    
    private func startBackgroundTask() {
        endBackgroundTask() // End any existing task
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleNotification() {
        guard timeRemaining > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Rest Timer Complete"
        content.body = "Time to start your next set!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(timeRemaining),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "restTimer",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            }
        }
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    }
}

// MARK: - Helper for AudioServices
import AudioToolbox

// MARK: - Progress calculation
extension RestTimer {
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }
    
    var progressRemaining: Double {
        guard totalTime > 0 else { return 0 }
        return Double(timeRemaining) / Double(totalTime)
    }
}

// MARK: - Time formatting
extension RestTimer {
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var shortFormattedTime: String {
        if timeRemaining >= 60 {
            let minutes = timeRemaining / 60
            let seconds = timeRemaining % 60
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        } else {
            return "\(timeRemaining)s"
        }
    }
}