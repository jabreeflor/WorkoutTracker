import UIKit
import SwiftUI

/// Service for providing haptic feedback throughout the app
class HapticService: ObservableObject {
    static let shared = HapticService()
    
    private init() {}
    
    // MARK: - Configuration
    @Published var isEnabled: Bool = true
    
    enum FeedbackType {
        case button
        case impact(UIImpactFeedbackGenerator.FeedbackStyle)
        case notification(UINotificationFeedbackGenerator.FeedbackType)
        case success
        case warning
        case error
        case selection
        case timerAction(TimerAction)
        
        enum TimerAction {
            case start
            case pause
            case resume
            case complete
            case extend
            case reduce
        }
    }
    
    func provideFeedback(for type: FeedbackType) {
        switch type {
        case .button:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
            
        case .notification(let type):
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(type)
            
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            
        case .timerAction(let action):
            switch action {
            case .start, .resume:
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            case .pause:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            case .complete:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            case .extend, .reduce:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    func bouncyPress() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func bouncyRelease() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    func focusChanged() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Provides feedback for increment actions
    func incrementValue() {
        guard isEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Provides feedback for decrement actions
    func decrementValue() {
        guard isEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Provides celebration feedback
    func celebration() {
        guard isEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        // Add a slight delay and another impact for celebration effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }
    }
}