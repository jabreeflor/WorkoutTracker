import SwiftUI

/// Enhanced set row with modern card aesthetics, bouncy animations, and celebration effects
struct EnhancedSetRowView: View {
    
    // MARK: - Properties
    @Binding var setData: SetData
    let previousSetData: SetData?
    let isActive: Bool
    let onSetCompleted: () -> Void
    let onStartRestTimer: (Int) -> Void
    let onValueChange: (SetData) -> Void
    
    // MARK: - State
    @State private var isPressed = false
    @State private var isEditingWeight = false
    @State private var isEditingReps = false
    @State private var weightInput = ""
    @State private var repsInput = ""
    @State private var showCelebration = false
    @State private var celebrationTrigger = false
    @State private var showingRestTimePicker = false
    
    // MARK: - Services
    @StateObject private var animationService = AnimationService.shared
    @StateObject private var celebrationService = CelebrationService.shared
    @StateObject private var restTimeResolver = RestTimeResolver.shared
    @StateObject private var restTimerService = RestTimerService.shared
    private let rowId = UUID()
    
    // MARK: - Settings
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    
    // MARK: - Initialization
    init(
        setData: Binding<SetData>,
        previousSetData: SetData? = nil,
        isActive: Bool = true,
        onSetCompleted: @escaping () -> Void = {},
        onStartRestTimer: @escaping (Int) -> Void = { _ in },
        onValueChange: @escaping (SetData) -> Void = { _ in }
    ) {
        self._setData = setData
        self.previousSetData = previousSetData
        self.isActive = isActive
        self.onSetCompleted = onSetCompleted
        self.onStartRestTimer = onStartRestTimer
        self.onValueChange = onValueChange
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Main set row content
            cardContainer
            
            // Rest timer integration (appears after completion)
            if setData.completed && !restTimerService.isActive {
                restTimerIntegration
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)).animation(.spring(response: 0.6, dampingFraction: 0.8)),
                        removal: .opacity.animation(.easeOut(duration: 0.3))
                    ))
            }
            
            // Progress indicator for completed sets
            if setData.completed {
                progressIndicator
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .scaleEffect(cardScale)
        .accessibleAnimation(AnimationService.bouncySpring, value: cardScale)
        .onAppear {
            initializeInputs()
        }
        .onChange(of: setData.completed) { _, completed in
            if completed {
                triggerCelebration()
                // Auto-start rest timer with intelligent duration
                let restDuration = restTimeResolver.resolveRestTime(for: setData)
                restTimerService.start(duration: TimeInterval(restDuration))
                onStartRestTimer(restDuration)
            }
        }
        .sheet(isPresented: $showingRestTimePicker) {
            RestTimePickerView(restTime: Binding(
                get: { setData.restTime },
                set: { newValue in
                    var updatedSet = setData
                    updatedSet.restTime = newValue
                    onValueChange(updatedSet)
                }
            ))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Set \(setData.setNumber)")
        .accessibilityValue(accessibilityDescription)
    }
    
    // MARK: - Card Container
    private var cardContainer: some View {
        VStack(spacing: 8) {
            // Top row: Set badge, previous set indicator, completion button
            HStack(spacing: 8) {
                // Set number badge
                setNumberBadge
                
                // Previous set comparison (if available)
                if let previousSet = previousSetData {
                    previousSetIndicator(previousSet)
                }
                
                Spacer()
                
                // Completion button
                completionButton
            }
            
            // Bottom row: Weight and reps controls
            HStack(spacing: 8) {
                Spacer()
                weightControl
                repsControl
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(cardBackground)
        .overlay(cardBorder)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: setData.completed ? Color.successGreen.opacity(0.3) : Color.black.opacity(0.05),
            radius: setData.completed ? 8 : 4,
            x: 0,
            y: setData.completed ? 4 : 2
        )
        .overlay(
            // Celebration effects overlay
            Group {
                if showCelebration {
                    CelebrationEffectsView(
                        effect: celebrationEffect,
                        duration: 2.0,
                        onComplete: { showCelebration = false }
                    )
                    .allowsHitTesting(false)
                }
            }
        )
        .bouncyPress(scale: 0.98, hapticFeedback: false)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Set Number Badge
    private var setNumberBadge: some View {
        ZStack {
            Circle()
                .fill(badgeBackground)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(badgeBorder, lineWidth: 2)
                )
                .glowShadow(
                    color: setData.completed ? .successGreen : .clear,
                    radius: 8,
                    isActive: setData.completed
                )
            
            if setData.completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(celebrationTrigger ? 1.2 : 1.0)
                    .accessibleAnimation(AnimationService.celebration, value: celebrationTrigger)
            } else {
                Text("\(setData.setNumber)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(badgeTextColor)
            }
        }
        .accessibilityLabel(setData.completed ? "Set \(setData.setNumber) completed" : "Set \(setData.setNumber)")
    }
    
    // MARK: - Previous Set Indicator
    private func previousSetIndicator(_ previousSet: SetData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Previous")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(String(format: "%.1f", previousSet.actualWeight))kg")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("\(previousSet.actualReps) reps")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            // Performance comparison
            if setData.completed {
                performanceComparison(with: previousSet)
            }
        }
        .frame(width: 45)
        .accessibilityLabel("Previous set: \(previousSet.actualWeight) kg, \(previousSet.actualReps) reps")
    }
    
    // MARK: - Performance Comparison
    private func performanceComparison(with previousSet: SetData) -> some View {
        let volumeChange = setData.volume - previousSet.volume
        let color: Color = volumeChange > 0 ? .successGreen : volumeChange < 0 ? .red : .gray
        let icon = volumeChange > 0 ? "arrow.up" : volumeChange < 0 ? "arrow.down" : "minus"
        
        return HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(volumeChange == 0 ? "Same" : String(format: "%.1f", abs(volumeChange)))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .accessibilityLabel("Volume change: \(volumeChange > 0 ? "increased" : volumeChange < 0 ? "decreased" : "same")")
    }
    
    // MARK: - Weight Control
    private var weightControl: some View {
        AnimatedInputControl(
            label: weightUnit,
            unit: weightUnit,
            value: $weightInput,
            incrementAmount: 2.5,
            decrementAmount: 2.5,
            keyboardType: .decimalPad,
            onValueChange: { newValue in
                handleWeightChange(newValue)
            },
            onIncrement: {
                incrementWeight()
            },
            onDecrement: {
                decrementWeight()
            }
        )
        .disabled(!isActive || setData.completed)
    }
    
    // MARK: - Reps Control
    private var repsControl: some View {
        AnimatedInputControl(
            label: "reps",
            unit: "reps",
            value: $repsInput,
            incrementAmount: 1,
            decrementAmount: 1,
            minValue: 0,
            maxValue: 100,
            keyboardType: .numberPad,
            onValueChange: { newValue in
                handleRepsChange(newValue)
            },
            onIncrement: {
                incrementReps()
            },
            onDecrement: {
                decrementReps()
            }
        )
        .disabled(!isActive || setData.completed)
    }
    
    // MARK: - Completion Button
    private var completionButton: some View {
        Button(action: toggleCompletion) {
            ZStack {
                Circle()
                    .fill(completionButtonBackground)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(completionButtonBorder, lineWidth: 3)
                    )
                    .glowShadow(
                        color: setData.completed ? .successGreen : .clear,
                        radius: 12,
                        isActive: setData.completed
                    )
                
                if setData.completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(celebrationTrigger ? 1.3 : 1.0)
                        .accessibleAnimation(AnimationService.celebration, value: celebrationTrigger)
                } else {
                    // Progress ring for incomplete sets
                    Circle()
                        .trim(from: 0, to: completionProgress)
                        .stroke(
                            Color.primaryBlue,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                        .accessibleAnimation(AnimationService.bouncySpring, value: completionProgress)
                    
                    if canComplete {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primaryBlue)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .disabled(!canComplete && !setData.completed)
        .bouncyPress(
            scale: 0.9,
            hapticFeedback: true
        )
        .accessibilityLabel(setData.completed ? "Mark set as incomplete" : "Complete set")
        .accessibilityHint(setData.completed ? "Tap to undo completion" : "Tap to mark set as complete")
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.successGreen.opacity(0.3))
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.successGreen)
                    .font(.caption)
                
                Text("Completed: \(String(format: "%.1f", setData.actualWeight))kg × \(setData.actualReps)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.successGreen)
                
                Spacer()
                
                if let timestamp = setData.timestamp {
                    Text(timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }
    
    // MARK: - Rest Timer Integration
    private var restTimerIntegration: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.successGreen.opacity(0.3))
            
            HStack(spacing: 12) {
                // Rest timer icon with pulse animation
                ZStack {
                    Circle()
                        .fill(Color.primaryBlue.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .scaleEffect(restTimerService.isActive ? 1.1 : 1.0)
                        .accessibleAnimation(
                            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: restTimerService.isActive
                        )
                    
                    Image(systemName: "timer")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest Timer Started")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let restTime = setData.restTime {
                        Text("\(RestTimeResolver.formatRestTime(restTime)) rest period")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Default rest period")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Quick rest time adjust buttons
                HStack(spacing: 8) {
                    Button(action: {
                        let currentTime = setData.restTime ?? 90
                        let newTime = max(30, currentTime - 30)
                        onStartRestTimer(newTime)
                        HapticService.shared.provideFeedback(for: .button)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.primaryBlue)
                    }
                    .accessibilityLabel("Decrease rest time")
                    
                    Button(action: {
                        let currentTime = setData.restTime ?? 90
                        let newTime = currentTime + 30
                        onStartRestTimer(newTime)
                        HapticService.shared.provideFeedback(for: .button)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.primaryBlue)
                    }
                    .accessibilityLabel("Increase rest time")
                    
                    Button(action: {
                        showingRestTimePicker = true
                        HapticService.shared.provideFeedback(for: .selection)
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Customize rest time")
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primaryBlue.opacity(0.05))
                .padding(.horizontal, 4)
        )
    }
    
    // MARK: - Sheet Modifiers
    private var sheetModifiers: some View {
        Group {
            sheet(isPresented: $showingRestTimePicker) {
                RestTimePickerView(restTime: Binding(
                    get: { setData.restTime },
                    set: { newValue in
                        var updatedSet = setData
                        updatedSet.restTime = newValue
                        onValueChange(updatedSet)
                    }
                ))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var showRestTimeIndicator: Bool {
        // Always show if a custom rest time is set
        if setData.restTime != nil {
            return true
        }
        
        // Show when the set is active or completed
        return isActive || setData.completed
    }
    
    private var cardScale: CGFloat {
        if setData.completed {
            return celebrationTrigger ? 1.02 : 1.0
        } else if isPressed {
            return 0.98
        } else {
            return 1.0
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(cardBackgroundGradient)
    }
    
    private var cardBackgroundGradient: LinearGradient {
        if setData.completed {
            return Color.enhancedSuccessGradient
        } else if isActive {
            return LinearGradient(
                gradient: Gradient(colors: [Color.primaryBlue.opacity(0.05)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [Color.neutralGray.opacity(0.3)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                cardBorderGradient,
                lineWidth: setData.completed ? 2 : 1
            )
    }
    
    private var cardBorderGradient: LinearGradient {
        if setData.completed {
            return Color.enhancedSuccessGradient
        } else if isActive {
            return LinearGradient(
                gradient: Gradient(colors: [Color.primaryBlue.opacity(0.3)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.2)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var badgeBackground: LinearGradient {
        if setData.completed {
            return Color.enhancedSuccessGradient
        } else if isActive {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.primaryBlue.opacity(0.8),
                    Color.primaryBlue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return Color.neutralGradient
        }
    }
    
    private var badgeBorder: Color {
        if setData.completed {
            return .celebrationGold
        } else if isActive {
            return .primaryBlue
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var badgeTextColor: Color {
        if setData.completed {
            return .white
        } else if isActive {
            return .primaryBlue
        } else {
            return .secondary
        }
    }
    
    private var completionButtonBackground: LinearGradient {
        if setData.completed {
            return Color.enhancedSuccessGradient
        } else if canComplete {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.primaryBlue.opacity(0.8),
                    Color.primaryBlue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return Color.neutralGradient
        }
    }
    
    private var completionButtonBorder: Color {
        if setData.completed {
            return .celebrationGold
        } else if canComplete {
            return .primaryBlue
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var canComplete: Bool {
        guard let weight = Double(weightInput),
              let reps = Int(repsInput) else {
            return false
        }
        return weight > 0 && reps > 0 && isActive && !setData.completed
    }
    
    private var completionProgress: CGFloat {
        let weightValid = Double(weightInput) ?? 0 > 0
        let repsValid = Int(repsInput) ?? 0 > 0
        
        if weightValid && repsValid {
            return 1.0
        } else if weightValid || repsValid {
            return 0.5
        } else {
            return 0.0
        }
    }
    
    private var celebrationEffect: CelebrationEffect {
        // Check if this is a personal record
        if let previous = previousSetData {
            let isVolumeRecord = setData.volume > previous.volume
            let isWeightRecord = setData.actualWeight > previous.actualWeight
            
            if isVolumeRecord || isWeightRecord {
                return CelebrationEffect.confetti(colors: Color.sparkleColors, count: 30)
            }
        }
        
        return CelebrationEffect.confetti(colors: [.successGreen, .mint, .successGreenLight], count: 20)
    }
    
    private var accessibilityDescription: String {
        if setData.completed {
            return "Completed: \(setData.actualWeight) kg, \(setData.actualReps) reps"
        } else {
            return "Target: \(setData.targetWeight) kg, \(setData.targetReps) reps"
        }
    }
    
    // MARK: - Action Handlers
    
    private func initializeInputs() {
        if setData.completed {
            weightInput = String(format: "%.1f", setData.actualWeight)
            repsInput = "\(setData.actualReps)"
        } else {
            weightInput = String(format: "%.1f", setData.targetWeight)
            repsInput = "\(setData.targetReps)"
        }
    }
    
    private func handleWeightChange(_ newValue: String) {
        guard let weight = Double(newValue), weight >= 0 else { return }
        
        if setData.completed {
            setData.actualWeight = weight
        } else {
            setData.targetWeight = weight
        }
        
        onValueChange(setData)
    }
    
    private func handleRepsChange(_ newValue: String) {
        guard let reps = Int(newValue), reps >= 0 else { return }
        
        if setData.completed {
            setData.actualReps = reps
        } else {
            setData.targetReps = reps
        }
        
        onValueChange(setData)
    }
    
    private func incrementWeight() {
        let currentWeight = Double(weightInput) ?? 0
        let newWeight = currentWeight + 2.5
        weightInput = String(format: "%.1f", newWeight)
        handleWeightChange(weightInput)
    }
    
    private func decrementWeight() {
        let currentWeight = Double(weightInput) ?? 0
        let newWeight = max(0, currentWeight - 2.5)
        weightInput = String(format: "%.1f", newWeight)
        handleWeightChange(weightInput)
    }
    
    private func incrementReps() {
        let currentReps = Int(repsInput) ?? 0
        let newReps = currentReps + 1
        repsInput = "\(newReps)"
        handleRepsChange(repsInput)
    }
    
    private func decrementReps() {
        let currentReps = Int(repsInput) ?? 0
        let newReps = max(0, currentReps - 1)
        repsInput = "\(newReps)"
        handleRepsChange(repsInput)
    }
    
    private func toggleCompletion() {
        if setData.completed {
            // Uncomplete the set
            setData.completed = false
            setData.timestamp = nil
            initializeInputs()
            
            HapticService.shared.provideFeedback(for: .button)
        } else {
            // Complete the set
            guard canComplete else { return }
            
            guard let weight = Double(weightInput),
                  let reps = Int(repsInput) else { return }
            
            setData.actualWeight = weight
            setData.actualReps = reps
            setData.completed = true
            setData.timestamp = Date()
            
            triggerCelebration()
            onSetCompleted()
            
            // Start rest timer with intelligent duration
            let restDuration = restTimeResolver.resolveRestTime(for: setData)
            restTimerService.start(duration: TimeInterval(restDuration))
            onStartRestTimer(restDuration)
        }
        
        onValueChange(setData)
    }
    
    private func triggerCelebration() {
        showCelebration = true
        celebrationTrigger.toggle()
        
        // Trigger celebration service
        celebrationService.celebrateSetCompletion(for: rowId)
        
        HapticService.shared.celebration()
    }
    
    private func isPersonalRecord() -> Bool {
        guard let previous = previousSetData else { return true }
        return setData.volume > previous.volume || setData.actualWeight > previous.actualWeight
    }
}

// MARK: - Preview

struct EnhancedSetRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Incomplete set
            EnhancedSetRowView(
                setData: .constant(SetData(setNumber: 1, targetReps: 10, targetWeight: 100.0)),
                isActive: true
            )
            
            // Completed set with previous data
            EnhancedSetRowView(
                setData: .constant({
                    var set = SetData(setNumber: 2, targetReps: 10, targetWeight: 100.0)
                    set.actualWeight = 102.5
                    set.actualReps = 8
                    set.completed = true
                    set.timestamp = Date()
                    return set
                }()),
                previousSetData: {
                    var prev = SetData(setNumber: 2, targetReps: 10, targetWeight: 95.0)
                    prev.actualWeight = 95.0
                    prev.actualReps = 10
                    prev.completed = true
                    return prev
                }(),
                isActive: true
            )
            
            // Inactive set
            EnhancedSetRowView(
                setData: .constant(SetData(setNumber: 3, targetReps: 10, targetWeight: 100.0)),
                isActive: false
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}