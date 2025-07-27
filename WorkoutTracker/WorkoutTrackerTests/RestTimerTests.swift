import XCTest
@testable import WorkoutTracker

class RestTimerTests: XCTestCase {
    
    var restTimerService: RestTimerService!
    var restTimeResolver: RestTimeResolver!
    
    override func setUp() {
        super.setUp()
        restTimerService = RestTimerService()
        restTimeResolver = RestTimeResolver.shared
    }
    
    override func tearDown() {
        restTimerService = nil
        super.tearDown()
    }
    
    // MARK: - RestTimerService Tests
    
    func testTimerInitialization() {
        XCTAssertFalse(restTimerService.isActive)
        XCTAssertEqual(restTimerService.timeRemaining, 0)
        XCTAssertEqual(restTimerService.totalTime, 0)
    }
    
    func testTimerStart() {
        restTimerService.start(duration: 60, source: .globalDefault)
        
        XCTAssertTrue(restTimerService.isActive)
        XCTAssertEqual(restTimerService.timeRemaining, 60)
        XCTAssertEqual(restTimerService.totalTime, 60)
        XCTAssertFalse(restTimerService.isPaused)
        XCTAssertEqual(restTimerService.restTimeSource, .globalDefault)
    }
    
    func testTimerPauseResume() {
        restTimerService.start(duration: 60)
        
        // Test pause
        restTimerService.pause()
        XCTAssertTrue(restTimerService.isPaused)
        
        // Test resume
        restTimerService.resume()
        XCTAssertFalse(restTimerService.isPaused)
    }
    
    func testTimerStop() {
        restTimerService.start(duration: 60)
        restTimerService.stop()
        
        XCTAssertFalse(restTimerService.isActive)
        XCTAssertEqual(restTimerService.timeRemaining, 0)
        XCTAssertEqual(restTimerService.totalTime, 0)
    }
    
    func testTimerExtend() {
        restTimerService.start(duration: 60)
        restTimerService.extend(by: 30)
        
        XCTAssertEqual(restTimerService.timeRemaining, 90)
        XCTAssertEqual(restTimerService.totalTime, 90)
        XCTAssertEqual(restTimerService.adjustmentHistory.count, 1)
        XCTAssertEqual(restTimerService.adjustmentHistory.last?.type, .extended)
    }
    
    func testTimerReduce() {
        restTimerService.start(duration: 60)
        restTimerService.reduce(by: 30)
        
        XCTAssertEqual(restTimerService.timeRemaining, 30)
        XCTAssertEqual(restTimerService.totalTime, 60) // Total time doesn't change when reducing
        XCTAssertEqual(restTimerService.adjustmentHistory.count, 1)
        XCTAssertEqual(restTimerService.adjustmentHistory.last?.type, .reduced)
    }
    
    func testTimerProgress() {
        restTimerService.start(duration: 100)
        restTimerService.reduce(by: 50) // Now at 50% completion
        
        XCTAssertEqual(restTimerService.progress, 0.5, accuracy: 0.01)
    }
    
    func testTimerUndo() {
        restTimerService.start(duration: 60)
        restTimerService.extend(by: 30) // Now at 90 seconds
        
        XCTAssertTrue(restTimerService.canUndo)
        restTimerService.undoLastAdjustment() // Should go back to 60 seconds
        
        XCTAssertEqual(restTimerService.timeRemaining, 60, accuracy: 0.1)
        XCTAssertEqual(restTimerService.adjustmentHistory.count, 0)
    }
    
    // MARK: - RestTimeResolver Tests
    
    func testRestTimeHierarchy() {
        // Create a test context
        let testContext = CoreDataManager.shared.context
        
        // Create an exercise
        let exercise = Exercise(context: testContext)
        exercise.name = "Test Exercise"
        exercise.id = UUID()
        
        // Set exercise-specific rest time
        restTimeResolver.setExerciseRestTime(for: exercise, seconds: 120)
        
        // Set global default rest time
        restTimeResolver.setGlobalDefaultRestTime(90)
        
        // Create a set with no specific rest time
        var setData = SetData(setNumber: 1, targetReps: 10, targetWeight: 100)
        
        // Test exercise-specific rest time takes precedence over global
        XCTAssertEqual(restTimeResolver.resolveRestTime(for: setData, exercise: exercise), 120)
        XCTAssertEqual(restTimeResolver.getRestTimeSource(for: setData, exercise: exercise), .exerciseSpecific)
        
        // Now set a set-specific rest time
        setData.restTime = 60
        
        // Test set-specific rest time takes precedence over both
        XCTAssertEqual(restTimeResolver.resolveRestTime(for: setData, exercise: exercise), 60)
        XCTAssertEqual(restTimeResolver.getRestTimeSource(for: setData, exercise: exercise), .setSpecific)
    }
    
    func testGlobalDefaultRestTime() {
        // Set global default rest time
        restTimeResolver.setGlobalDefaultRestTime(75)
        
        // Verify it was set correctly
        XCTAssertEqual(restTimeResolver.getGlobalDefaultRestTime(), 75)
    }
    
    func testExerciseRestTimePersistence() {
        // Create a test context
        let testContext = CoreDataManager.shared.context
        
        // Create an exercise
        let exercise = Exercise(context: testContext)
        exercise.name = "Persistence Test Exercise"
        exercise.id = UUID()
        
        // Set and then get the exercise-specific rest time
        restTimeResolver.setExerciseRestTime(for: exercise, seconds: 150)
        XCTAssertEqual(restTimeResolver.getExerciseRestTime(for: exercise), 150)
        
        // Clear the exercise-specific rest time
        restTimeResolver.setExerciseRestTime(for: exercise, seconds: nil)
        XCTAssertNil(restTimeResolver.getExerciseRestTime(for: exercise))
    }
}
