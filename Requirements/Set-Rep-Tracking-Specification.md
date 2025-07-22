# Set & Rep Tracking System Specification

## Overview
Detailed specification for the enhanced set and rep tracking system, covering current implementation and future phases.

## Current Implementation (Phase 1 & 2)

### Existing Features
- **Basic Exercise Tracking**: Single set/rep/weight value per exercise
- **Simple Input**: Stepper controls for sets and reps
- **Weight Logging**: Decimal weight input with "lbs" unit
- **Template Support**: Default values from workout templates

### Current Data Model
```swift
// WorkoutExercise (Current)
class WorkoutExercise: NSManagedObject {
    var sets: Int32        // Total number of sets
    var reps: Int32        // Reps per set (uniform)
    var weight: Double     // Weight used (uniform across sets)
    var exercise: Exercise // Reference to exercise
}
```

### Current UI Components
- `WorkoutExerciseRow`: Basic stepper controls
- Simple text field for weight input
- Delete button for exercise removal

## Phase 3 Enhanced Set/Rep System

### New Features Overview
The enhanced system will transform from "exercise-level" tracking to "set-level" tracking, providing granular control and better progress monitoring.

### Core Enhancements

#### 1. Individual Set Tracking
```swift
// New SetData model
struct SetData: Codable {
    let setNumber: Int
    var targetReps: Int      // Planned reps for this set
    var actualReps: Int      // Actually completed reps
    var targetWeight: Double // Planned weight
    var actualWeight: Double // Actually used weight
    var completed: Bool      // Set completion status
    var restTime: Int?       // Rest time after this set
    var notes: String?       // Set-specific notes
    var timestamp: Date?     // When set was completed
}

// Enhanced WorkoutExercise
class WorkoutExercise: NSManagedObject {
    var setDataJSON: String  // JSON encoded [SetData]
    var totalVolume: Double  // Calculated: Σ(reps × weight)
    var exerciseRestTime: Int32 // Default rest between sets
    var exerciseNotes: String?  // Exercise-level notes
    
    // Computed properties
    var setData: [SetData] {
        get { /* decode from JSON */ }
        set { /* encode to JSON */ }
    }
}
```

#### 2. Advanced Set Management UI

##### Set Row Component
```swift
struct SetRow: View {
    @Binding var setData: SetData
    let setNumber: Int
    let previousSetData: SetData?
    
    var body: some View {
        HStack {
            // Set number
            Text("\(setNumber)")
                .frame(width: 30)
            
            // Previous performance indicator
            if let previous = previousSetData {
                VStack {
                    Text("\(previous.actualReps)")
                    Text("\(previous.actualWeight, specifier: "%.1f")")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            
            // Target input fields
            VStack {
                TextField("Reps", value: $setData.targetReps, format: .number)
                TextField("Weight", value: $setData.targetWeight, format: .number)
            }
            
            // Actual input fields (enabled during workout)
            VStack {
                TextField("Reps", value: $setData.actualReps, format: .number)
                TextField("Weight", value: $setData.actualWeight, format: .number)
            }
            
            // Completion checkbox
            Button(action: { setData.completed.toggle() }) {
                Image(systemName: setData.completed ? "checkmark.circle.fill" : "circle")
            }
            
            // Rest timer button
            RestTimerButton(duration: setData.restTime ?? 60)
        }
    }
}
```

#### 3. Rest Timer Implementation

##### Timer Component
```swift
class RestTimer: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    
    private var timer: Timer?
    
    func start(duration: Int) {
        timeRemaining = duration
        isActive = true
        isPaused = false
        startTimer()
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
    }
    
    func resume() {
        isPaused = false
        startTimer()
    }
    
    func skip() {
        stop()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
                // Send notification/haptic feedback
            }
        }
    }
}
```

##### Timer UI Component
```swift
struct RestTimerView: View {
    @StateObject private var timer = RestTimer()
    let defaultDuration: Int
    
    var body: some View {
        VStack {
            if timer.isActive {
                VStack {
                    Text("\(timer.timeRemaining)")
                        .font(.largeTitle)
                        .monospacedDigit()
                    
                    HStack {
                        Button("Pause") { timer.pause() }
                        Button("Skip") { timer.skip() }
                        Button("+30s") { timer.addTime(30) }
                    }
                }
            } else {
                Button("Start Rest Timer") {
                    timer.start(duration: defaultDuration)
                }
            }
        }
    }
}
```

#### 4. Progressive Overload Intelligence

##### Recommendation Engine
```swift
class ProgressiveOverloadEngine {
    static func getRecommendations(
        for exercise: Exercise,
        lastWorkout: [SetData],
        userPreferences: UserPreferences
    ) -> [SetData] {
        var recommendations: [SetData] = []
        
        for (index, lastSet) in lastWorkout.enumerated() {
            var newSet = SetData(setNumber: index + 1)
            
            // If user completed all reps, suggest progression
            if lastSet.actualReps >= lastSet.targetReps {
                // Option 1: Increase weight by 2.5-5lbs
                newSet.targetWeight = lastSet.actualWeight + getWeightIncrement(for: exercise)
                newSet.targetReps = lastSet.targetReps
            } else {
                // Option 2: Keep weight, try to hit rep target
                newSet.targetWeight = lastSet.actualWeight
                newSet.targetReps = lastSet.targetReps
            }
            
            recommendations.append(newSet)
        }
        
        return recommendations
    }
    
    private static func getWeightIncrement(for exercise: Exercise) -> Double {
        switch exercise.primaryMuscleGroup {
        case "Chest", "Back", "Quadriceps":
            return 5.0  // Larger muscle groups
        default:
            return 2.5  // Smaller muscle groups
        }
    }
}
```

### Implementation Timeline

#### Phase 3.1 (Weeks 1-2): Core Set Tracking
- [ ] Update Core Data model with SetData JSON storage
- [ ] Implement SetRow component
- [ ] Add set completion checkboxes
- [ ] Basic set addition/removal functionality

#### Phase 3.2 (Weeks 3-4): Rest Timer
- [ ] Implement RestTimer class
- [ ] Add timer UI components
- [ ] Background timer support
- [ ] Notification integration

#### Phase 3.3 (Weeks 5-6): Intelligence Features
- [ ] Previous workout data display
- [ ] Progressive overload recommendations
- [ ] Volume calculations
- [ ] Performance analytics per set

#### Phase 3.4 (Weeks 7-8): Polish & Optimization
- [ ] Smooth animations and transitions
- [ ] Haptic feedback integration
- [ ] Performance optimization
- [ ] Comprehensive testing

### User Experience Flow

#### During Workout Session
1. **Exercise Setup**: Template loads with recommended sets/reps/weight
2. **Set Execution**: User performs set, inputs actual reps/weight
3. **Set Completion**: Tap checkbox to mark set complete
4. **Rest Period**: Timer automatically starts, user can modify duration
5. **Next Set**: Previous set data shows as reference
6. **Exercise Completion**: All sets marked complete, move to next exercise

#### Progressive Disclosure
- **Beginner Mode**: Simple interface, hide advanced features
- **Advanced Mode**: Full set tracking, detailed analytics
- **Quick Mode**: Minimal input, auto-progression

### Data Migration Strategy

#### From Current to Enhanced
```swift
// Migration function
func migrateWorkoutExercises() {
    let fetchRequest: NSFetchRequest<WorkoutExercise> = WorkoutExercise.fetchRequest()
    let exercises = try! context.fetch(fetchRequest)
    
    for exercise in exercises {
        // Convert old format to new set-based format
        var setData: [SetData] = []
        
        for setNumber in 1...exercise.sets {
            let set = SetData(
                setNumber: Int(setNumber),
                targetReps: Int(exercise.reps),
                actualReps: Int(exercise.reps),
                targetWeight: exercise.weight,
                actualWeight: exercise.weight,
                completed: true  // Assume completed for historical data
            )
            setData.append(set)
        }
        
        exercise.setData = setData
        // Keep old fields for backward compatibility during transition
    }
    
    try! context.save()
}
```

### Analytics & Insights

#### Set-Level Analytics
- **Volume Per Set**: Reps × Weight for each set
- **Completion Rate**: Percentage of sets completed as planned
- **Rest Time Analysis**: Average rest between sets
- **Progressive Overload Tracking**: Weight/rep progression over time

#### Exercise-Level Analytics
- **Total Volume**: Sum of all set volumes
- **Set Consistency**: Variance in performance across sets
- **Strength Curve**: How performance drops across sets
- **Recovery Patterns**: Rest time requirements

### Testing Strategy

#### Unit Tests
- SetData model operations
- RestTimer functionality
- Progressive overload calculations
- Data migration accuracy

#### Integration Tests
- Core Data persistence of set data
- UI updates during workout sessions
- Timer background operation
- Notification delivery

#### User Experience Tests
- Workout flow with multiple exercises
- Timer interruption scenarios
- Data loss prevention
- Performance with large datasets

---

*This enhanced set/rep system will be the cornerstone of Phase 3, providing users with professional-level workout tracking capabilities while maintaining the app's ease of use.*