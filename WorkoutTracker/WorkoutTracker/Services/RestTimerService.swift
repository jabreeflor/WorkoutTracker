import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
class RestTimerService: ObservableObject {
    // MARK: - Published Properties
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var backgroundDate: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// Starts the rest timer with the specified duration
    /// - Parameter duration: The duration in seconds
    func start(duration: TimeInterval) {
        stop()
        
        totalTime = duration
        timeRemaining = duration
        isActive = true
        isPaused = false
        
        startTimer()
    }
    
    /// Pauses the rest timer
    func pause() {
        guard isActive, !isPaused else { return }
        
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    /// Resumes the rest timer
    func resume() {
        guard isActive, isPaused else { return }
        
        isPaused = false
        startTimer()
    }
    
    /// Stops the rest timer
    func stop() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isPaused = false
        timeRemaining = 0
        totalTime = 0
    }
    
    /// Extends the rest timer by the specified duration
    /// - Parameter seconds: The number of seconds to add
    func extend(by seconds: TimeInterval) {
        timeRemaining += seconds
        totalTime += seconds
    }
    
    /// Reduces the rest timer by the specified duration
    /// - Parameter seconds: The number of seconds to subtract
    func reduce(by seconds: TimeInterval) {
        timeRemaining = max(1, timeRemaining - seconds)
        totalTime = max(timeRemaining, totalTime)
    }
    
    // MARK: - Private Methods
    
    /// Sets up notifications for app state changes
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleAppBackground()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleAppForeground()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Handles the app going to the background
    private func handleAppBackground() {
        guard isActive, !isPaused else { return }
        
        backgroundDate = Date()
        timer?.invalidate()
        timer = nil
    }
    
    /// Handles the app coming to the foreground
    private func handleAppForeground() {
        guard isActive, !isPaused, let backgroundDate = backgroundDate else { return }
        
        let elapsedTime = Date().timeIntervalSince(backgroundDate)
        timeRemaining = max(0, timeRemaining - elapsedTime)
        
        if timeRemaining <= 0 {
            complete()
        } else {
            startTimer()
        }
        
        self.backgroundDate = nil
    }
    
    /// Starts the timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    /// Updates the timer every second
    private func tick() {
        guard timeRemaining > 0 else {
            complete()
            return
        }
        
        timeRemaining -= 1
    }
    
    /// Completes the timer
    private func complete() {
        isActive = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        
        // Play haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Schedule local notification if app is in background
        if UIApplication.shared.applicationState != .active {
            scheduleLocalNotification()
        }
    }
    
    /// Schedules a local notification for timer completion
    private func scheduleLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Rest Timer Complete"
        content.body = "Time to start your next set!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Computed Properties
    
    /// Returns the progress percentage (0.0 - 1.0)
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalTime)
    }
    
    /// Returns the formatted time remaining string (MM:SS)
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}