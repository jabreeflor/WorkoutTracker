import SwiftUI
import UIKit

/// Service for managing comprehensive accessibility support throughout the app
@MainActor
class AccessibilityService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isVoiceOverEnabled: Bool = UIAccessibility.isVoiceOverRunning
    @Published var isReduceMotionEnabled: Bool = UIAccessibility.isReduceMotionEnabled
    @Published var isHighContrastEnabled: Bool = UIAccessibility.isDarkerSystemColorsEnabled
    @Published var preferredContentSizeCategory: ContentSizeCategory = .medium
    
    // MARK: - Singleton
    static let shared = AccessibilityService()
    
    private init() {
        setupAccessibilityNotifications()
        updateContentSizeCategory()
    }
    
    // MARK: - Accessibility State Management
    
    /// Setup notifications for accessibility changes
    private func setupAccessibilityNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
            self?.updateAnimationServices()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateContentSizeCategory()
        }
    }
    
    /// Update animation services based on accessibility settings
    private func updateAnimationServices() {
        if isReduceMotionEnabled {
            AnimationService.shared.reduceAnimationComplexity()
            VisualFeedbackService.shared.reduceComplexity()
            CelebrationService.shared.reduceComplexity()
        } else {
            AnimationService.shared.restoreAnimationComplexity()
            VisualFeedbackService.shared.restoreComplexity()
        }
    }
    
    /// Update content size category from UIKit to SwiftUI
    private func updateContentSizeCategory() {
        let uiCategory = UIApplication.shared.preferredContentSizeCategory
        
        // Convert UIContentSizeCategory to SwiftUI ContentSizeCategory
        switch uiCategory {
        case .extraSmall: preferredContentSizeCategory = .extraSmall
        case .small: preferredContentSizeCategory = .small
        case .medium: preferredContentSizeCategory = .medium
        case .large: preferredContentSizeCategory = .large
        case .extraLarge: preferredContentSizeCategory = .extraLarge
        case .extraExtraLarge: preferredContentSizeCategory = .extraExtraLarge
        case .extraExtraExtraLarge: preferredContentSizeCategory = .extraExtraExtraLarge
        case .accessibilityMedium: preferredContentSizeCategory = .accessibilityMedium
        case .accessibilityLarge: preferredContentSizeCategory = .accessibilityLarge
        case .accessibilityExtraLarge: preferredContentSizeCategory = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: preferredContentSizeCategory = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        default: preferredContentSizeCategory = .medium
        }
    }
    
    // MARK: - Accessibility Helpers
    
    /// Get accessible color for current contrast settings
    func accessibleColor(_ color: Color, for colorScheme: ColorScheme) -> Color {
        if isHighContrastEnabled {
            return color.opacity(0.8) // Simple accessibility adjustment
        }
        return color
    }
    
    /// Get accessible font size for current content size category
    func accessibleFontSize(_ baseSize: CGFloat) -> CGFloat {
        let scaleFactor = fontScaleFactor
        return baseSize * scaleFactor
    }
    
    /// Get font scale factor based on content size category
    private var fontScaleFactor: CGFloat {
        switch preferredContentSizeCategory {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.8
        case .accessibilityExtraLarge: return 2.0
        case .accessibilityExtraExtraLarge: return 2.2
        case .accessibilityExtraExtraExtraLarge: return 2.4
        @unknown default: return 1.0
        }
    }
    
    /// Check if large text is enabled
    var isLargeTextEnabled: Bool {
        return preferredContentSizeCategory.isAccessibilityCategory ||
               preferredContentSizeCategory >= .extraLarge
    }
    
    /// Get minimum touch target size for accessibility
    var minimumTouchTargetSize: CGFloat {
        return isLargeTextEnabled ? 48 : 44
    }
    
    // MARK: - VoiceOver Support
    
    /// Post accessibility announcement
    func announce(_ message: String, priority: NSAttributedString.Key? = nil) {
        guard isVoiceOverEnabled else { return }
        
        DispatchQueue.main.async {
            if let priority = priority {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: NSAttributedString(
                        string: message,
                        attributes: [priority: NSNumber(value: 1)]
                    )
                )
            } else {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: message
                )
            }
        }
    }
    
    /// Post layout change notification
    func announceLayoutChange(focusElement: Any? = nil) {
        guard isVoiceOverEnabled else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(
                notification: .layoutChanged,
                argument: focusElement
            )
        }
    }
    
    /// Post screen change notification
    func announceScreenChange(focusElement: Any? = nil) {
        guard isVoiceOverEnabled else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(
                notification: .screenChanged,
                argument: focusElement
            )
        }
    }
    
    // MARK: - Accessibility Labels and Hints
    
    /// Generate accessibility label for set row
    func setRowAccessibilityLabel(
        setNumber: Int,
        isCompleted: Bool,
        targetWeight: Double,
        targetReps: Int,
        actualWeight: Double? = nil,
        actualReps: Int? = nil
    ) -> String {
        if isCompleted, let actualWeight = actualWeight, let actualReps = actualReps {
            return "Set \(setNumber), completed with \(actualWeight) kilograms, \(actualReps) repetitions"
        } else {
            return "Set \(setNumber), target \(targetWeight) kilograms, \(targetReps) repetitions"
        }
    }
    
    /// Generate accessibility hint for set row
    func setRowAccessibilityHint(isCompleted: Bool, isActive: Bool) -> String {
        if isCompleted {
            return "Double tap to edit completed set values"
        } else if isActive {
            return "Adjust weight and reps, then tap complete button to finish set"
        } else {
            return "Set not yet active"
        }
    }
    
    /// Generate accessibility label for timer
    func timerAccessibilityLabel(
        timeRemaining: TimeInterval,
        isActive: Bool,
        isPaused: Bool
    ) -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        
        let timeString = minutes > 0 ? 
            "\(minutes) minutes and \(seconds) seconds" : 
            "\(seconds) seconds"
        
        if !isActive {
            return "Rest timer stopped"
        } else if isPaused {
            return "Rest timer paused with \(timeString) remaining"
        } else {
            return "Rest timer active with \(timeString) remaining"
        }
    }
    
    /// Generate accessibility hint for timer controls
    func timerControlAccessibilityHint(action: TimerAction) -> String {
        switch action {
        case .pause: return "Pause the rest timer"
        case .resume: return "Resume the rest timer"
        case .stop: return "Stop the rest timer"
        case .extend: return "Add 15 seconds to the timer"
        case .reduce: return "Subtract 15 seconds from the timer"
        }
    }
    
    // MARK: - Accessibility Actions
    
    /// Create accessibility custom actions for set row
    func setRowAccessibilityActions(
        onIncreaseWeight: @escaping () -> Void,
        onDecreaseWeight: @escaping () -> Void,
        onIncreaseReps: @escaping () -> Void,
        onDecreaseReps: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) -> [AccessibilityActionInfo] {
        return [
            AccessibilityActionInfo(
                name: "Increase weight",
                action: onIncreaseWeight
            ),
            AccessibilityActionInfo(
                name: "Decrease weight",
                action: onDecreaseWeight
            ),
            AccessibilityActionInfo(
                name: "Increase reps",
                action: onIncreaseReps
            ),
            AccessibilityActionInfo(
                name: "Decrease reps",
                action: onDecreaseReps
            ),
            AccessibilityActionInfo(
                name: "Complete set",
                action: onComplete
            )
        ]
    }
    
    // MARK: - Performance Monitoring
    
    /// Check if device should use reduced animations
    var shouldUseReducedAnimations: Bool {
        return isReduceMotionEnabled || 
               ProcessInfo.processInfo.isLowPowerModeEnabled ||
               UIDevice.current.batteryLevel < 0.2
    }
    
    /// Check if device should use reduced visual effects
    var shouldUseReducedVisualEffects: Bool {
        return shouldUseReducedAnimations || 
               UIAccessibility.isReduceTransparencyEnabled
    }
    
    /// Get appropriate animation duration based on accessibility settings
    func accessibleAnimationDuration(_ baseDuration: TimeInterval) -> TimeInterval {
        if isReduceMotionEnabled {
            return baseDuration * 0.3 // Significantly reduce animation time
        } else if isVoiceOverEnabled {
            return baseDuration * 0.7 // Slightly reduce for VoiceOver users
        } else {
            return baseDuration
        }
    }
}

// MARK: - Accessibility Action Info

struct AccessibilityActionInfo {
    let name: String
    let action: () -> Void
}

// MARK: - Timer Action

enum TimerAction {
    case pause, resume, stop, extend, reduce
}

// MARK: - Accessibility View Modifiers

extension View {
    
    /// Add comprehensive accessibility support
    func accessibilitySupport(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        actions: [AccessibilityActionInfo] = [],
        traits: AccessibilityTraits = []
    ) -> some View {
        modifier(AccessibilitySupportModifier(
            label: label,
            hint: hint,
            value: value,
            actions: actions,
            traits: traits
        ))
    }
    
    /// Add accessible touch target sizing
    func accessibleTouchTarget(
        accessibilityService: AccessibilityService? = nil
    ) -> some View {
        modifier(AccessibleTouchTargetModifier(accessibilityService: accessibilityService ?? AccessibilityService.shared))
    }
    
    /// Add accessible font scaling
    func accessibleFont(
        _ font: Font,
        accessibilityService: AccessibilityService? = nil
    ) -> some View {
        modifier(AccessibleFontModifier(font: font, accessibilityService: accessibilityService ?? AccessibilityService.shared))
    }
    
    /// Add accessible color support
    func accessibleColor(
        _ color: Color,
        accessibilityService: AccessibilityService? = nil
    ) -> some View {
        modifier(AccessibleColorModifier(color: color, accessibilityService: accessibilityService ?? AccessibilityService.shared))
    }
}

// MARK: - Accessibility Modifiers

struct AccessibilitySupportModifier: ViewModifier {
    let label: String
    let hint: String?
    let value: String?
    let actions: [AccessibilityActionInfo]
    let traits: AccessibilityTraits
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityActions {
                ForEach(actions.indices, id: \.self) { index in
                    Button(actions[index].name) {
                        actions[index].action()
                    }
                }
            }
    }
}

struct AccessibleTouchTargetModifier: ViewModifier {
    @ObservedObject var accessibilityService: AccessibilityService
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: accessibilityService.minimumTouchTargetSize,
                   minHeight: accessibilityService.minimumTouchTargetSize)
    }
}

struct AccessibleFontModifier: ViewModifier {
    let font: Font
    @ObservedObject var accessibilityService: AccessibilityService
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

struct AccessibleColorModifier: ViewModifier {
    let color: Color
    @ObservedObject var accessibilityService: AccessibilityService
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(accessibilityService.accessibleColor(color, for: colorScheme))
    }
}

// MARK: - Preview

struct AccessibilityService_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Accessible button
            Button("Complete Set") {
                // Action
            }
            .accessibilitySupport(
                label: "Complete set button",
                hint: "Tap to mark the current set as completed",
                traits: [.isButton]
            )
            .accessibleTouchTarget()
            
            // Accessible text
            Text("Set 1: 100kg × 10 reps")
                .accessibleFont(.headline)
                .accessibleColor(.primary)
            
            // Timer with accessibility
            Text("2:30")
                .accessibilitySupport(
                    label: "Rest timer",
                    hint: "Timer is currently running",
                    value: "2 minutes and 30 seconds remaining"
                )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}