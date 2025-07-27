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
    @Published var restTimeSource: RestTimeSource? = nil
    
    // Additional properties for improved functionality
    @Published var completionPercent: Double = 0
    @Published var adjustmentHistory: [TimerAdjustment] = []
    @Published var lastTimerSource: RestTimeSource? = nil
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var backgroundDate: Date?
    private var cancellables = Set<AnyCancellable>()
    private var wasManuallyAdjusted = false
    
    // State tracking
    private var wasSkipped = false
    private var timerStartDate: Date? = nil
    private var timerCompletionDate: Date? = nil
    
    // MARK: - Initialization
    init() {
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// Starts the rest timer with the specified duration and remembers previous source
    /// - Parameters:
    ///   - duration: The duration in seconds
    ///   - source: The source of the rest time (optional)
    ///   - forceRestart: Whether to force restart even if a timer is already active
    func start(duration: TimeInterval, source: RestTimeSource? = nil, forceRestart: Bool = false) {
        // If a timer is already active and we're not forcing a restart, just return
        if isActive && !forceRestart {
            return
        }
        
        stop()
        
        totalTime = duration
        timeRemaining = duration
        isActive = true
        isPaused = false
        wasManuallyAdjusted = false
        wasSkipped = false
        restTimeSource = source
        completionPercent = 0
        adjustmentHistory.removeAll()
        
        // Remember the source for next time
        if source != nil {
            lastTimerSource = source
        }
        
        timerStartDate = Date()
        if duration > 0 {
            timerCompletionDate = Date().addingTimeInterval(duration)
        } else {
            timerCompletionDate = nil
        }
        
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
    
    /// Restarts the timer with the same settings
    func restart() {
        guard isActive else { return }
        
        let currentSource = restTimeSource
        start(duration: totalTime, source: currentSource, forceRestart: true)
        
        // Play haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Extends the rest timer by the specified duration
    /// - Parameter seconds: The number of seconds to add
    func extend(by seconds: TimeInterval) {
        timeRemaining += seconds
        totalTime += seconds
        
        // If we're extending from zero, reset the manual adjustment flag
        if timeRemaining > 0 {
            wasManuallyAdjusted = false
        }
        
        // Update completion date
        if let completionDate = timerCompletionDate {
            timerCompletionDate = completionDate.addingTimeInterval(seconds)
        } else {
            timerCompletionDate = Date().addingTimeInterval(timeRemaining)
        }
        
        // Add to adjustment history
        let adjustment = TimerAdjustment(
            type: .extended,
            originalTime: timeRemaining - seconds,
            adjustedTime: timeRemaining,
            timestamp: Date()
        )
        adjustmentHistory.append(adjustment)
    }
    
    /// Reduces the rest timer by the specified duration
    /// - Parameter seconds: The number of seconds to subtract
    func reduce(by seconds: TimeInterval) {
        let previousTime = timeRemaining
        timeRemaining = max(0, timeRemaining - seconds)
        
        // Update completion date
        if timeRemaining > 0 {
            timerCompletionDate = Date().addingTimeInterval(timeRemaining)
        } else {
            timerCompletionDate = nil
        }
        
        // If timer reaches 0 or below, mark as manually adjusted and keep active
        if timeRemaining <= 0 {
            timeRemaining = 0
            wasManuallyAdjusted = true
            // Play haptic feedback to indicate timer reached zero
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
        
        // Add to adjustment history
        let adjustment = TimerAdjustment(
            type: .reduced,
            originalTime: previousTime,
            adjustedTime: timeRemaining,
            timestamp: Date()
        )
        adjustmentHistory.append(adjustment)
    }
    
    /// Undoes the last timer adjustment if possible
    func undoLastAdjustment() {
        guard let lastAdjustment = adjustmentHistory.last else { return }
        
        switch lastAdjustment.type {
        case .extended:
            // Undo an extension by reducing
            let adjustmentAmount = lastAdjustment.adjustedTime - lastAdjustment.originalTime
            timeRemaining = max(0, timeRemaining - adjustmentAmount)
            totalTime = max(totalTime - adjustmentAmount, timeRemaining)
            
        case .reduced:
            // Undo a reduction by extending
            let adjustmentAmount = lastAdjustment.originalTime - lastAdjustment.adjustedTime
            timeRemaining += adjustmentAmount
            
        case .skipped:
            // Can't undo a skip
            return
        }
        
        // Update completion date
        timerCompletionDate = Date().addingTimeInterval(timeRemaining)
        
        // Remove the last adjustment
        adjustmentHistory.removeLast()
        
        // Play haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Skips the current rest timer (different from stop - marks as skipped)
    func skip() {
        guard isActive else { return }
        
        wasSkipped = true
        stop()
        
        // Add to adjustment history
        if let startDate = timerStartDate {
            let actualDuration = Date().timeIntervalSince(startDate)
            let adjustment = TimerAdjustment(
                type: .skipped,
                originalTime: totalTime,
                adjustedTime: actualDuration,
                timestamp: Date()
            )
            adjustmentHistory.append(adjustment)
        }
        
        // Play haptic feedback to indicate skip
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
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
            // Timer is already at zero
            // If it was manually adjusted, don't complete automatically
            // If it reached zero naturally, it would have been completed already
            return
        }
        
        timeRemaining -= 1
        
        // If we just reached zero naturally (not manually adjusted), complete the timer
        if timeRemaining <= 0 && !wasManuallyAdjusted {
            complete()
        }
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
    
    /// Returns the estimated completion time as a formatted string
    var estimatedCompletionTime: String {
        guard let completionDate = timerCompletionDate else {
            return "Unknown"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        return formatter.string(from: completionDate)
    }
    
    /// Returns whether the timer can be undone
    var canUndo: Bool {
        return !adjustmentHistory.isEmpty
    }
    
    /// Returns the percentage completed (0.0 - 1.0)
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        let progress = 1.0 - (timeRemaining / totalTime)
        // Update the published completionPercent
        completionPercent = progress * 100
        return progress
    }
    
    /// Returns the formatted time remaining string (MM:SS)
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Singleton Instance
    static let shared = RestTimerService()
}

// MARK: - Timer Adjustment

/// Represents an adjustment made to the timer
struct TimerAdjustment {
    let type: AdjustmentType
    let originalTime: TimeInterval
    let adjustedTime: TimeInterval
    let timestamp: Date
    
    enum AdjustmentType {
        case extended
        case reduced
        case skipped
        
        var description: String {
            switch self {
            case .extended:
                return "Extended"
            case .reduced:
                return "Reduced"
            case .skipped:
                return "Skipped"
            }
        }
    }
}