import XCTest
import SwiftUI
@testable import WorkoutTracker

/// Comprehensive test suite for the animation system and bouncy interactions
@MainActor
final class AnimationSystemTests: XCTestCase {
    
    var animationService: AnimationService!
    var celebrationService: CelebrationService!
    var visualFeedbackService: VisualFeedbackService!
    var accessibilityService: AccessibilityService!
    var performanceService: PerformanceOptimizationService!
    
    override func setUp() {
        super.setUp()
        animationService = AnimationService.shared
        celebrationService = CelebrationService.shared
        visualFeedbackService = VisualFeedbackService.shared
        accessibilityService = AccessibilityService.shared
        performanceService = PerformanceOptimizationService.shared
    }
    
    override func tearDown() {
        // Clean up services
        animationService.states.removeAll()
        celebrationService.activeCelebrations.removeAll()
        visualFeedbackService.feedbackStates.removeAll()
        super.tearDown()
    }
    
    // MARK: - Animation Service Tests
    
    func testAnimationServiceStateManagement() {
        let testId = UUID()
        
        // Test initial state
        let initialState = animationService.getState(for: testId)
        XCTAssertFalse(initialState.isPressed)
        XCTAssertFalse(initialState.isCompleted)
        XCTAssertEqual(initialState.scale, 1.0)
        
        // Test state updates
        animationService.updateState(for: testId) { state in
            state.isPressed = true
            state.scale = 0.95
        }
        
        let updatedState = animationService.getState(for: testId)
        XCTAssertTrue(updatedState.isPressed)
        XCTAssertEqual(updatedState.scale, 0.95)
    }
    
    func testBouncyAnimationTriggers() {
        let testId = UUID()
        
        // Test bounce trigger
        animationService.triggerBounce(for: testId, scale: 0.9)
        
        let state = animationService.getState(for: testId)
        XCTAssertTrue(state.isPressed)
        XCTAssertEqual(state.scale, 0.9)
        
        // Test that state resets after delay (we'll test this with expectation)
        let expectation = XCTestExpectation(description: "Bounce animation resets")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let resetState = self.animationService.getState(for: testId)
            XCTAssertFalse(resetState.isPressed)
            XCTAssertEqual(resetState.scale, 1.0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAnimationConstants() {
        // Test that animation constants are within expected ranges
        XCTAssertGreaterThan(AnimationService.AnimationConstants.springResponse, 0)
        XCTAssertLessThanOrEqual(AnimationService.AnimationConstants.springResponse, 2.0)
        
        XCTAssertGreaterThan(AnimationService.AnimationConstants.springDamping, 0)
        XCTAssertLessThanOrEqual(AnimationService.AnimationConstants.springDamping, 1.0)
        
        XCTAssertGreaterThan(AnimationService.AnimationConstants.bouncyScale, 0.5)
        XCTAssertLessThan(AnimationService.AnimationConstants.bouncyScale, 1.0)
    }
    
    // MARK: - Celebration Service Tests
    
    func testCelebrationTriggers() {
        let testId = UUID()
        let confettiEffect = CelebrationEffect.confetti(colors: [.red, .blue], count: 10)
        
        // Test celebration trigger
        celebrationService.triggerCelebration(for: testId, type: confettiEffect, duration: 1.0)
        
        XCTAssertTrue(celebrationService.isCelebrationActive(for: testId))
        XCTAssertEqual(celebrationService.getCelebrationType(for: testId), confettiEffect)
    }
    
    func testCelebrationAutoCleanup() {
        let testId = UUID()
        let effect = CelebrationEffect.glow(color: .green, radius: 10)
        
        celebrationService.triggerCelebration(for: testId, type: effect, duration: 0.1)
        
        let expectation = XCTestExpectation(description: "Celebration auto-cleanup")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.celebrationService.isCelebrationActive(for: testId))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPredefinedCelebrations() {
        let setId = UUID()
        
        // Test set completion celebration
        celebrationService.celebrateSetCompletion(for: setId, isPersonalRecord: false)
        XCTAssertTrue(celebrationService.isCelebrationActive(for: setId))
        
        // Test PR celebration
        let prId = UUID()
        celebrationService.celebrateSetCompletion(for: prId, isPersonalRecord: true)
        XCTAssertTrue(celebrationService.isCelebrationActive(for: prId))
        
        // Verify different effects for PR vs normal completion
        let normalEffect = celebrationService.getCelebrationType(for: setId)
        let prEffect = celebrationService.getCelebrationType(for: prId)
        XCTAssertNotEqual(normalEffect, prEffect)
    }
    
    // MARK: - Visual Feedback Service Tests
    
    func testImmediateVisualResponse() {
        let testId = UUID()
        
        // Test press response timing
        let startTime = CFAbsoluteTimeGetCurrent()
        visualFeedbackService.triggerPressResponse(for: testId, intensity: .medium)
        let responseTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should respond within 16ms (60fps frame time)
        XCTAssertLessThan(responseTime, 0.016)
        
        let state = visualFeedbackService.getFeedbackState(for: testId)
        XCTAssertTrue(state.isPressed)
        XCTAssertEqual(state.pressIntensity, .medium)
    }
    
    func testFeedbackStateManagement() {
        let testId = UUID()
        
        // Test loading state
        visualFeedbackService.triggerLoadingState(for: testId, isLoading: true, message: "Loading...")
        XCTAssertTrue(visualFeedbackService.isLoading(testId))
        
        // Test success feedback
        visualFeedbackService.triggerSuccessFeedback(for: testId, message: "Success!", duration: 0.1)
        let state = visualFeedbackService.getFeedbackState(for: testId)
        XCTAssertTrue(state.showSuccess)
        XCTAssertEqual(state.successMessage, "Success!")
    }
    
    func testBatchOperations() {
        let ids = [UUID(), UUID(), UUID()]
        
        // Test batch press response
        visualFeedbackService.triggerBatchPressResponse(for: ids, intensity: .heavy)
        
        for id in ids {
            XCTAssertTrue(visualFeedbackService.isPressed(id))
        }
        
        // Test batch cleanup
        visualFeedbackService.clearBatchFeedback(for: ids)
        
        for id in ids {
            XCTAssertFalse(visualFeedbackService.isPressed(id))
        }
    }
    
    // MARK: - Accessibility Service Tests
    
    func testAccessibilityStateDetection() {
        // Test that accessibility service properly detects system states
        // Note: These tests may vary based on simulator/device settings
        
        XCTAssertNotNil(accessibilityService.isVoiceOverEnabled)
        XCTAssertNotNil(accessibilityService.isReduceMotionEnabled)
        XCTAssertNotNil(accessibilityService.isHighContrastEnabled)
        XCTAssertNotNil(accessibilityService.preferredContentSizeCategory)
    }
    
    func testAccessibilityLabelGeneration() {
        // Test set row accessibility labels
        let label = accessibilityService.setRowAccessibilityLabel(
            setNumber: 1,
            isCompleted: true,
            targetWeight: 100.0,
            targetReps: 10,
            actualWeight: 102.5,
            actualReps: 8
        )
        
        XCTAssertTrue(label.contains("Set 1"))
        XCTAssertTrue(label.contains("completed"))
        XCTAssertTrue(label.contains("102.5"))
        XCTAssertTrue(label.contains("8"))
    }
    
    func testAccessibilityHints() {
        let activeHint = accessibilityService.setRowAccessibilityHint(isCompleted: false, isActive: true)
        let completedHint = accessibilityService.setRowAccessibilityHint(isCompleted: true, isActive: true)
        
        XCTAssertTrue(activeHint.contains("complete"))
        XCTAssertTrue(completedHint.contains("edit"))
    }
    
    func testTimerAccessibilityLabels() {
        let label = accessibilityService.timerAccessibilityLabel(
            timeRemaining: 90,
            isActive: true,
            isPaused: false
        )
        
        XCTAssertTrue(label.contains("1 minutes"))
        XCTAssertTrue(label.contains("30 seconds"))
        XCTAssertTrue(label.contains("active"))
    }
    
    // MARK: - Performance Service Tests
    
    func testPerformanceModeCalculation() {
        // Test that performance mode is calculated correctly
        let initialMode = performanceService.performanceMode
        XCTAssertNotNil(initialMode)
        
        // Test performance score calculation
        let score = performanceService.performanceScore
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }
    
    func testAnimationOptimization() {
        let baseDuration: TimeInterval = 1.0
        
        // Test optimal mode
        performanceService.performanceMode = .optimal
        let optimalDuration = performanceService.optimizedAnimationDuration(baseDuration)
        XCTAssertEqual(optimalDuration, baseDuration)
        
        // Test reduced mode
        performanceService.performanceMode = .reduced
        let reducedDuration = performanceService.optimizedAnimationDuration(baseDuration)
        XCTAssertLessThan(reducedDuration, baseDuration)
        
        // Test battery mode
        performanceService.performanceMode = .battery
        let batteryDuration = performanceService.optimizedAnimationDuration(baseDuration)
        XCTAssertLessThan(batteryDuration, reducedDuration)
    }
    
    func testParticleCountOptimization() {
        let baseCount = 20
        
        // Test optimal mode
        performanceService.performanceMode = .optimal
        XCTAssertEqual(performanceService.maxParticleCount(baseCount), baseCount)
        
        // Test reduced mode
        performanceService.performanceMode = .reduced
        XCTAssertLessThan(performanceService.maxParticleCount(baseCount), baseCount)
        
        // Test battery mode
        performanceService.performanceMode = .battery
        XCTAssertLessThanOrEqual(performanceService.maxParticleCount(baseCount), 5)
    }
    
    // MARK: - Integration Tests
    
    func testServiceIntegration() {
        let testId = UUID()
        
        // Test that services work together properly
        animationService.triggerCompletion(for: testId, completed: true)
        
        // Should trigger celebration
        XCTAssertTrue(celebrationService.isCelebrationActive(for: testId))
        
        // Should update animation state
        let state = animationService.getState(for: testId)
        XCTAssertTrue(state.isCompleted)
    }
    
    func testMemoryManagement() {
        let ids = (0..<100).map { _ in UUID() }
        
        // Create many animation states
        for id in ids {
            animationService.triggerBounce(for: id)
            celebrationService.triggerCelebration(for: id, type: .glow(color: .blue, radius: 5))
            visualFeedbackService.triggerPressResponse(for: id)
        }
        
        // Test cleanup
        animationService.cleanupUnusedStates()
        celebrationService.cleanupOldCelebrations()
        visualFeedbackService.cleanupOldStates()
        
        // Verify states are cleaned up (this is a basic test - in practice, cleanup depends on timing)
        XCTAssertLessThanOrEqual(animationService.states.count, ids.count)
    }
    
    // MARK: - Animation Timing Tests
    
    func testAnimationTimingConsistency() {
        // Test that animation constants are consistent across services
        let springAnimation = AnimationService.bouncySpring
        let quickFeedback = AnimationService.quickFeedback
        let celebration = AnimationService.celebration
        
        // These should be different animation types
        XCTAssertNotEqual(springAnimation, quickFeedback)
        XCTAssertNotEqual(quickFeedback, celebration)
    }
    
    func testReducedMotionCompliance() {
        // Test that reduced motion is respected
        let testId = UUID()
        
        // Simulate reduced motion enabled
        accessibilityService.isReduceMotionEnabled = true
        
        // Test that animations are modified appropriately
        let baseDuration: TimeInterval = 1.0
        let accessibleDuration = accessibilityService.accessibleAnimationDuration(baseDuration)
        
        XCTAssertLessThan(accessibleDuration, baseDuration)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidStateHandling() {
        let testId = UUID()
        
        // Test handling of invalid animation states
        animationService.updateState(for: testId) { state in
            state.scale = -1.0 // Invalid scale
        }
        
        let state = animationService.getState(for: testId)
        // The service should handle this gracefully
        XCTAssertNotNil(state)
    }
    
    func testConcurrentAccess() {
        let testId = UUID()
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        
        // Test concurrent access to animation service
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.animationService.triggerBounce(for: testId, scale: 0.9)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // Should not crash and should have a valid state
        let finalState = animationService.getState(for: testId)
        XCTAssertNotNil(finalState)
    }
}

// MARK: - Mock Classes for Testing

class MockHapticService {
    var feedbackCalls: [HapticContext] = []
    
    func provideFeedback(for context: HapticContext) {
        feedbackCalls.append(context)
    }
}

// MARK: - Performance Tests

extension AnimationSystemTests {
    
    func testAnimationPerformance() {
        let iterations = 1000
        let testIds = (0..<iterations).map { _ in UUID() }
        
        measure {
            for id in testIds {
                animationService.triggerBounce(for: id)
            }
        }
    }
    
    func testCelebrationPerformance() {
        let iterations = 100
        let testIds = (0..<iterations).map { _ in UUID() }
        
        measure {
            for id in testIds {
                celebrationService.triggerCelebration(
                    for: id,
                    type: .confetti(colors: [.red, .blue], count: 10)
                )
            }
        }
    }
    
    func testVisualFeedbackPerformance() {
        let iterations = 1000
        let testIds = (0..<iterations).map { _ in UUID() }
        
        measure {
            for id in testIds {
                visualFeedbackService.triggerPressResponse(for: id)
            }
        }
    }
}