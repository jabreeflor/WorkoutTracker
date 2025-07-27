import SwiftUI
import Combine
import UIKit

/// Service for monitoring and optimizing animation performance and memory usage
@MainActor
class PerformanceOptimizationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentFrameRate: Double = 60.0
    @Published var memoryUsage: Double = 0.0
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var batteryLevel: Float = 1.0
    @Published var isLowPowerModeEnabled: Bool = false
    @Published var performanceMode: PerformanceMode = .optimal
    
    // MARK: - Private Properties
    private var displayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var performanceTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    static let shared = PerformanceOptimizationService()
    
    private init() {
        setupPerformanceMonitoring()
        setupNotifications()
    }
    
    // MARK: - Performance Monitoring Setup
    
    private func setupPerformanceMonitoring() {
        // Setup display link for frame rate monitoring
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
        displayLink?.add(to: .main, forMode: .common)
        
        // Setup performance monitoring timer
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePerformanceMetrics()
            }
        }
    }
    
    private func setupNotifications() {
        // Battery state notifications
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.batteryLevel = UIDevice.current.batteryLevel
                    self?.updatePerformanceMode()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
                    self?.updatePerformanceMode()
                }
            }
            .store(in: &cancellables)
        
        // Thermal state notifications
        NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.thermalState = ProcessInfo.processInfo.thermalState
                    self?.updatePerformanceMode()
                }
            }
            .store(in: &cancellables)
        
        // Memory warning notifications
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleMemoryWarning()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Frame Rate Monitoring
    
    @objc private func displayLinkCallback(_ displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        frameCount += 1
        let elapsed = displayLink.timestamp - lastTimestamp
        
        if elapsed >= 1.0 {
            let fps = Double(frameCount) / elapsed
            
            Task { @MainActor in
                self.currentFrameRate = fps
                self.checkFrameRatePerformance(fps)
            }
            
            frameCount = 0
            lastTimestamp = displayLink.timestamp
        }
    }
    
    private func checkFrameRatePerformance(_ fps: Double) {
        if fps < 45 && performanceMode != .reduced {
            // Frame rate is too low, reduce animation complexity
            reduceAnimationComplexity()
        } else if fps > 55 && performanceMode == .reduced {
            // Frame rate is good, can restore animations
            restoreAnimationComplexity()
        }
    }
    
    // MARK: - Memory Monitoring
    
    private func updatePerformanceMetrics() {
        memoryUsage = getCurrentMemoryUsage()
        batteryLevel = UIDevice.current.batteryLevel
        thermalState = ProcessInfo.processInfo.thermalState
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        updatePerformanceMode()
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        
        return 0.0
    }
    
    // MARK: - Performance Mode Management
    
    private func updatePerformanceMode() {
        let newMode = calculateOptimalPerformanceMode()
        
        if newMode != performanceMode {
            performanceMode = newMode
            applyPerformanceMode(newMode)
        }
    }
    
    private func calculateOptimalPerformanceMode() -> PerformanceMode {
        // Check critical conditions first
        if isLowPowerModeEnabled || batteryLevel < 0.15 {
            return .battery
        }
        
        if thermalState == .critical || thermalState == .serious {
            return .thermal
        }
        
        if memoryUsage > 200 { // 200MB threshold
            return .memory
        }
        
        if currentFrameRate < 45 {
            return .reduced
        }
        
        // Check for accessibility requirements
        if UIAccessibility.isReduceMotionEnabled {
            return .accessibility
        }
        
        return .optimal
    }
    
    private func applyPerformanceMode(_ mode: PerformanceMode) {
        switch mode {
        case .optimal:
            restoreAnimationComplexity()
            
        case .reduced:
            reduceAnimationComplexity()
            
        case .battery:
            minimizeAnimations()
            
        case .thermal:
            minimizeAnimations()
            reduceVisualEffects()
            
        case .memory:
            cleanupMemory()
            reduceAnimationComplexity()
            
        case .accessibility:
            applyAccessibilityOptimizations()
        }
    }
    
    // MARK: - Performance Optimizations
    
    private func reduceAnimationComplexity() {
        AnimationService.shared.reduceAnimationComplexity()
        VisualFeedbackService.shared.reduceComplexity()
        CelebrationService.shared.reduceComplexity()
    }
    
    private func restoreAnimationComplexity() {
        AnimationService.shared.restoreAnimationComplexity()
        VisualFeedbackService.shared.restoreComplexity()
    }
    
    private func minimizeAnimations() {
        // Disable non-essential animations
        AnimationService.shared.reduceAnimationComplexity()
        VisualFeedbackService.shared.reduceComplexity()
        
        // Reduce celebration effects
        CelebrationService.shared.reduceComplexity()
    }
    
    private func reduceVisualEffects() {
        // Reduce shadow complexity, blur effects, etc.
        // This would be implemented in individual components
    }
    
    private func cleanupMemory() {
        // Cleanup old animation states
        AnimationService.shared.cleanupUnusedStates()
        VisualFeedbackService.shared.cleanupOldStates()
        CelebrationService.shared.cleanupOldCelebrations()
        
        // Force garbage collection
        autoreleasepool {
            // Temporary objects will be cleaned up
        }
    }
    
    private func applyAccessibilityOptimizations() {
        // Apply accessibility-specific optimizations
        Task { @MainActor in
            if AccessibilityService.shared.isReduceMotionEnabled {
                reduceAnimationComplexity()
            }
        }
    }
    
    private func handleMemoryWarning() {
        // Immediate memory cleanup
        cleanupMemory()
        
        // Switch to memory-optimized mode
        performanceMode = .memory
        applyPerformanceMode(.memory)
        
        // Post notification for other services
        NotificationCenter.default.post(name: .performanceMemoryWarning, object: nil)
    }
    
    // MARK: - Animation Optimization Helpers
    
    /// Get optimal animation duration based on current performance
    func optimizedAnimationDuration(_ baseDuration: TimeInterval) -> TimeInterval {
        switch performanceMode {
        case .optimal:
            return baseDuration
        case .reduced:
            return baseDuration * 0.7
        case .battery, .thermal:
            return baseDuration * 0.3
        case .memory:
            return baseDuration * 0.5
        case .accessibility:
            return AccessibilityService.shared.accessibleAnimationDuration(baseDuration)
        }
    }
    
    /// Check if complex animations should be enabled
    var shouldEnableComplexAnimations: Bool {
        switch performanceMode {
        case .optimal, .accessibility:
            return true
        case .reduced, .battery, .thermal, .memory:
            return false
        }
    }
    
    /// Check if particle effects should be enabled
    var shouldEnableParticleEffects: Bool {
        switch performanceMode {
        case .optimal:
            return true
        case .reduced, .accessibility:
            return currentFrameRate > 50
        case .battery, .thermal, .memory:
            return false
        }
    }
    
    /// Get maximum particle count for celebrations
    func maxParticleCount(_ baseCount: Int) -> Int {
        switch performanceMode {
        case .optimal:
            return baseCount
        case .reduced, .accessibility:
            return baseCount / 2
        case .battery, .thermal, .memory:
            return min(baseCount / 4, 5)
        }
    }
    
    // MARK: - Performance Metrics
    
    /// Get current performance score (0-100)
    var performanceScore: Int {
        var score = 100
        
        // Frame rate impact
        if currentFrameRate < 30 {
            score -= 40
        } else if currentFrameRate < 45 {
            score -= 20
        } else if currentFrameRate < 55 {
            score -= 10
        }
        
        // Memory impact
        if memoryUsage > 300 {
            score -= 30
        } else if memoryUsage > 200 {
            score -= 15
        } else if memoryUsage > 150 {
            score -= 5
        }
        
        // Thermal impact
        switch thermalState {
        case .critical:
            score -= 50
        case .serious:
            score -= 30
        case .fair:
            score -= 10
        case .nominal:
            break
        @unknown default:
            break
        }
        
        // Battery impact
        if isLowPowerModeEnabled {
            score -= 20
        } else if batteryLevel < 0.15 {
            score -= 15
        } else if batteryLevel < 0.3 {
            score -= 5
        }
        
        return max(0, score)
    }
    
    // MARK: - Cleanup
    
    deinit {
        displayLink?.invalidate()
        performanceTimer?.invalidate()
        Task { @MainActor in
            UIDevice.current.isBatteryMonitoringEnabled = false
        }
    }
}

// MARK: - Performance Mode

enum PerformanceMode: String, CaseIterable {
    case optimal = "Optimal"
    case reduced = "Reduced"
    case battery = "Battery Saver"
    case thermal = "Thermal Management"
    case memory = "Memory Optimized"
    case accessibility = "Accessibility"
    
    var description: String {
        switch self {
        case .optimal:
            return "Full animations and effects enabled"
        case .reduced:
            return "Reduced animation complexity for better performance"
        case .battery:
            return "Minimal animations to preserve battery"
        case .thermal:
            return "Reduced processing to manage device temperature"
        case .memory:
            return "Optimized for low memory usage"
        case .accessibility:
            return "Optimized for accessibility features"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let performanceMemoryWarning = Notification.Name("performanceMemoryWarning")
    static let performanceModeChanged = Notification.Name("performanceModeChanged")
}

// MARK: - Performance View Modifiers

extension View {
    
    /// Add performance-aware animations
    func performanceOptimizedAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        Group {
            if PerformanceOptimizationService.shared.shouldEnableComplexAnimations {
                self.animation(animation, value: value)
            } else {
                self.animation(
                    animation?.speed(2.0), // Faster, simpler animations
                    value: value
                )
            }
        }
    }
    
    /// Add performance monitoring overlay (debug only)
    func performanceMonitor() -> some View {
        #if DEBUG
        overlay(
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("FPS: \(Int(PerformanceOptimizationService.shared.currentFrameRate))")
                        Text("Mem: \(Int(PerformanceOptimizationService.shared.memoryUsage))MB")
                        Text("Mode: \(PerformanceOptimizationService.shared.performanceMode.rawValue)")
                        Text("Score: \(PerformanceOptimizationService.shared.performanceScore)")
                    }
                    .font(.caption2)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                }
                Spacer()
            }
        )
        #else
        self
        #endif
    }
}

// MARK: - Preview

struct PerformanceOptimizationService_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Performance Monitoring")
                .font(.title)
            
            Text("Current Mode: \(PerformanceOptimizationService.shared.performanceMode.rawValue)")
                .font(.headline)
            
            Text("Frame Rate: \(Int(PerformanceOptimizationService.shared.currentFrameRate)) FPS")
            
            Text("Memory Usage: \(Int(PerformanceOptimizationService.shared.memoryUsage)) MB")
            
            Text("Performance Score: \(PerformanceOptimizationService.shared.performanceScore)/100")
        }
        .performanceMonitor()
        .padding()
        .previewLayout(.sizeThatFits)
    }
}