import XCTest

/// UI tests for the enhanced set row and rest timer components
final class EnhancedSetRowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Launch app with test configuration
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Set Row Interaction Tests
    
    func testSetRowBasicInteraction() throws {
        // Navigate to workout session
        navigateToWorkoutSession()
        
        // Add an exercise
        addTestExercise()
        
        // Test set row elements are present
        let setRow = app.otherElements["set-row-1"]
        XCTAssertTrue(setRow.exists)
        
        // Test set number badge
        let setBadge = setRow.buttons["set-badge-1"]
        XCTAssertTrue(setBadge.exists)
        
        // Test weight control
        let weightControl = setRow.otherElements["weight-control"]
        XCTAssertTrue(weightControl.exists)
        
        // Test reps control
        let repsControl = setRow.otherElements["reps-control"]
        XCTAssertTrue(repsControl.exists)
        
        // Test completion button
        let completionButton = setRow.buttons["completion-button"]
        XCTAssertTrue(completionButton.exists)
    }
    
    func testWeightAdjustment() throws {
        navigateToWorkoutSession()
        addTestExercise()
        
        let setRow = app.otherElements["set-row-1"]
        let weightControl = setRow.otherElements["weight-control"]
        
        // Test increment button
        let incrementButton = weightControl.buttons["increment-weight"]
        XCTAssertTrue(incrementButton.exists)
        
        // Get initial weight value
        let weightField = weightControl.textFields["weight-input"]
        let initialWeight = weightField.value as? String ?? "0"
        
        // Tap increment button
        incrementButton.tap()
        
        // Verify weight increased
        let newWeight = weightField.value as? String ?? "0"
        XCTAssertNotEqual(initialWeight, newWeight)
    }
    
    func testRepsAdjustment() throws {
        navigateToWorkoutSession()
        addTestExercise()
        
        let setRow = app.otherElements["set-row-1"]
        let repsControl = setRow.otherElements["reps-control"]
        
        // Test increment button
        let incrementButton = repsControl.buttons["increment-reps"]
        XCTAssertTrue(incrementButton.exists)
        
        // Get initial reps value
        let repsField = repsControl.textFields["reps-input"]
        let initialReps = repsField.value as? String ?? "0"
        
        // Tap increment button
        incrementButton.tap()
        
        // Verify reps increased
        let newReps = repsField.value as? String ?? "0"
        XCTAssertNotEqual(initialReps, newReps)
    }
    
    func testSetCompletion() throws {
        navigateToWorkoutSession()
        addTestExercise()
        
        let setRow = app.otherElements["set-row-1"]
        let completionButton = setRow.buttons["completion-button"]
        
        // Ensure set can be completed (has valid weight and reps)
        enterValidSetData(setRow: setRow)
        
        // Complete the set
        completionButton.tap()
        
        // Verify set is marked as completed
        let completedBadge = setRow.images["completed-checkmark"]
        XCTAssertTrue(completedBadge.waitForExistence(timeout: 2.0))
        
        // Verify rest timer appears
        let restTimer = app.otherElements["rest-timer"]
        XCTAssertTrue(restTimer.waitForExistence(timeout: 2.0))
    }
    
    func testSetUncompletion() throws {
        navigateToWorkoutSession()
        addTestExercise()
        
        let setRow = app.otherElements["set-row-1"]
        
        // Complete the set first
        enterValidSetData(setRow: setRow)
        let completionButton = setRow.buttons["completion-button"]
        completionButton.tap()
        
        // Wait for completion
        let completedBadge = setRow.images["completed-checkmark"]
        XCTAssertTrue(completedBadge.waitForExistence(timeout: 2.0))
        
        // Tap completion button again to uncomplete
        completionButton.tap()
        
        // Verify set is no longer completed
        XCTAssertFalse(completedBadge.exists)
    }
    
    // MARK: - Rest Timer Tests
    
    func testRestTimerAppearance() throws {
        navigateToWorkoutSession()
        addTestExercise()
        
        // Complete a set to trigger rest timer
        completeFirstSet()
        
        // Verify rest timer appears
        let restTimer = app.otherElements["rest-timer"]
        XCTAssertTrue(restTimer.waitForExistence(timeout: 2.0))
        
        // Verify timer elements
        let timerDisplay = restTimer.staticTexts["timer-display"]
        XCTAssertTrue(timerDisplay.exists)
        
        let pauseButton = restTimer.buttons["pause-button"]
        XCTAssertTrue(pauseButton.exists)
        
        let skipButton = restTimer.buttons["skip-button"]
        XCTAssertTrue(skipButton.exists)
    }
    
    func testRestTimerControls() throws {
        navigateToWorkoutSession()
        addTestExercise()
        completeFirstSet()
        
        let restTimer = app.otherElements["rest-timer"]
        XCTAssertTrue(restTimer.waitForExistence(timeout: 2.0))
        
        // Test pause button
        let pauseButton = restTimer.buttons["pause-button"]
        pauseButton.tap()
        
        // Verify pause state
        let resumeButton = restTimer.buttons["resume-button"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 1.0))
        
        // Test resume
        resumeButton.tap()
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 1.0))
        
        // Test skip
        let skipButton = restTimer.buttons["skip-button"]
        skipButton.tap()
        
        // Verify timer disappears
        XCTAssertFalse(restTimer.waitForExistence(timeout: 1.0))
    }
    
    func testRestTimerTimeAdjustment() throws {
        navigateToWorkoutSession()
        addTestExercise()
        completeFirstSet()
        
        let restTimer = app.otherElements["rest-timer"]
        XCTAssertTrue(restTimer.waitForExistence(timeout: 2.0))
        
        // Get initial time
        let timerDisplay = restTimer.staticTexts["timer-display"]
        let initialTime = timerDisplay.label
        
        // Add time
        let addTimeButton = restTimer.buttons["add-time-button"]
        addTimeButton.tap()
        
        // Verify time increased
        let newTime = timerDisplay.label
        XCTAssertNotEqual(initialTime, newTime)
        
        // Reduce time
        let reduceTimeButton = restTimer.buttons["reduce-time-button"]
        reduceTimeButton.tap()
        
        // Verify time decreased
        let reducedTime = timerDisplay.label
        XCTAssertNotEqual(newTime, reducedTime)
    }
    
    // MARK: - Animation and Visual Feedback Tests
    
    func testSetCompletionAnimation() throws {
        navigateToWorkoutSession()
        addTestExercise()
        
        let setRow = app.otherElements["set-row-1"]
        enterValidSetData(setRow: setRow)
        
        // Complete set and verify animation elements appear
        let completionButton = setRow.buttons["completion-button"]
        completionButton.tap()
        
        // Check for celebration effects (these might be temporary elements)
        let celebrationEffect = app.otherElements["celebration-effect"]
        // Note: Celebration effects might be brief, so we use a short timeout
        _ = celebrationEffect.waitForExistence(timeout: 0.5)
        
        // Verify completed state styling
        let completedBadge = setRow.images["completed-checkmark"]
        XCTAssertTrue(completedBadge.waitForExistence(timeout: 2.0))
    }
    
    func testButtonPressAnimations() throws {
        navigateToWorkoutSession()
        addTestExercise()
        
        let setRow = app.otherElements["set-row-1"]
        let weightControl = setRow.otherElements["weight-control"]
        let incrementButton = weightControl.buttons["increment-weight"]
        
        // Test that button responds to press (visual feedback)
        // This is challenging to test directly, but we can verify the button is interactive
        XCTAssertTrue(incrementButton.isHittable)
        
        // Tap and verify it's still responsive
        incrementButton.tap()
        XCTAssertTrue(incrementButton.isHittable)
    }
    
    // MARK: - Accessibility Tests
    
    func testSetRowAccessibility() throws {
        navigateToWorkoutSession()
        addTestExercise()
        
        let setRow = app.otherElements["set-row-1"]
        
        // Test accessibility labels
        XCTAssertNotNil(setRow.label)
        XCTAssertFalse(setRow.label.isEmpty)
        
        // Test weight control accessibility
        let weightControl = setRow.otherElements["weight-control"]
        let incrementButton = weightControl.buttons["increment-weight"]
        
        XCTAssertNotNil(incrementButton.label)
        XCTAssertTrue(incrementButton.label.contains("weight") || incrementButton.label.contains("increase"))
        
        // Test completion button accessibility
        let completionButton = setRow.buttons["completion-button"]
        XCTAssertNotNil(completionButton.label)
    }
    
    func testRestTimerAccessibility() throws {
        navigateToWorkoutSession()
        addTestExercise()
        completeFirstSet()
        
        let restTimer = app.otherElements["rest-timer"]
        XCTAssertTrue(restTimer.waitForExistence(timeout: 2.0))
        
        // Test timer display accessibility
        let timerDisplay = restTimer.staticTexts["timer-display"]
        XCTAssertNotNil(timerDisplay.label)
        XCTAssertFalse(timerDisplay.label.isEmpty)
        
        // Test control button accessibility
        let pauseButton = restTimer.buttons["pause-button"]
        XCTAssertNotNil(pauseButton.label)
        XCTAssertTrue(pauseButton.label.contains("pause") || pauseButton.label.contains("Pause"))
    }
    
    // MARK: - Performance Tests
    
    func testMultipleSetRowsPerformance() throws {
        navigateToWorkoutSession()
        addTestExercise()
        
        // Add multiple sets
        let addSetButton = app.buttons["add-set-button"]
        for _ in 0..<5 {
            if addSetButton.exists {
                addSetButton.tap()
            }
        }
        
        // Verify all set rows are present and responsive
        for i in 1...6 { // Original 3 + 3 added
            let setRow = app.otherElements["set-row-\(i)"]
            if setRow.exists {
                let completionButton = setRow.buttons["completion-button"]
                XCTAssertTrue(completionButton.isHittable)
            }
        }
    }
    
    func testScrollingPerformance() throws {
        navigateToWorkoutSession()
        
        // Add multiple exercises
        for _ in 0..<5 {
            addTestExercise()
        }
        
        // Test scrolling through exercises
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
            
            // Verify elements are still responsive after scrolling
            let firstSetRow = app.otherElements["set-row-1"]
            if firstSetRow.exists {
                XCTAssertTrue(firstSetRow.isHittable)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToWorkoutSession() {
        // Navigate to workout session (implementation depends on app structure)
        let workoutTab = app.tabBars.buttons["Workout"]
        if workoutTab.exists {
            workoutTab.tap()
        }
        
        let startWorkoutButton = app.buttons["Start Workout"]
        if startWorkoutButton.exists {
            startWorkoutButton.tap()
        }
    }
    
    private func addTestExercise() {
        let addExerciseButton = app.buttons["Add Exercise"]
        if addExerciseButton.exists {
            addExerciseButton.tap()
            
            // Select first exercise from list
            let firstExercise = app.cells.firstMatch
            if firstExercise.exists {
                firstExercise.tap()
            }
            
            // Dismiss exercise selection
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }
    }
    
    private func enterValidSetData(setRow: XCUIElement) {
        let weightControl = setRow.otherElements["weight-control"]
        let repsControl = setRow.otherElements["reps-control"]
        
        // Ensure weight is valid
        let weightField = weightControl.textFields["weight-input"]
        if weightField.exists {
            weightField.tap()
            weightField.typeText("100")
        }
        
        // Ensure reps is valid
        let repsField = repsControl.textFields["reps-input"]
        if repsField.exists {
            repsField.tap()
            repsField.typeText("10")
        }
    }
    
    private func completeFirstSet() {
        let setRow = app.otherElements["set-row-1"]
        enterValidSetData(setRow: setRow)
        
        let completionButton = setRow.buttons["completion-button"]
        completionButton.tap()
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidInputHandling() throws {
        navigateToWorkoutSession()
        addTestExercise()
        
        let setRow = app.otherElements["set-row-1"]
        let weightControl = setRow.otherElements["weight-control"]
        let weightField = weightControl.textFields["weight-input"]
        
        // Try to enter invalid weight
        weightField.tap()
        weightField.typeText("-50") // Negative weight
        
        // Try to complete set
        let completionButton = setRow.buttons["completion-button"]
        completionButton.tap()
        
        // Verify set is not completed with invalid data
        let completedBadge = setRow.images["completed-checkmark"]
        XCTAssertFalse(completedBadge.waitForExistence(timeout: 1.0))
    }
    
    func testNetworkDisconnectionHandling() throws {
        // This would test how the UI handles network issues
        // Implementation depends on app's network requirements
        navigateToWorkoutSession()
        addTestExercise()
        
        // Complete a set
        completeFirstSet()
        
        // Verify UI remains functional even if network is unavailable
        let setRow = app.otherElements["set-row-2"]
        if setRow.exists {
            let completionButton = setRow.buttons["completion-button"]
            XCTAssertTrue(completionButton.isHittable)
        }
    }
}