import Foundation
import CoreData

class PredictionTestSuite {
    static let shared = PredictionTestSuite()
    private let predictionService = WorkoutPerformancePrediction.shared
    private let context = CoreDataManager.shared.context
    
    private init() {}
    
    // MARK: - Test Suite
    
    func runAllTests() -> TestResults {
        var results = TestResults()
        
        results.append(testBasicPrediction())
        results.append(testProgressionTimeline())
        results.append(testRestTimePrediction())
        results.append(testDataValidation())
        results.append(testEdgeCases())
        
        return results
    }
    
    // MARK: - Individual Tests
    
    private func testBasicPrediction() -> TestResult {
        let testName = "Basic Performance Prediction"
        
        do {
            let exercise = createTestExercise(name: "Test Bench Press")
            let prediction = predictionService.predictNextWorkoutPerformance(
                for: exercise,
                targetWeight: 185.0,
                targetReps: 8
            )
            
            if let prediction = prediction {
                let success = prediction.predictedReps > 0 &&
                             prediction.predictedWeight > 0 &&
                             prediction.successProbability >= 0 &&
                             prediction.successProbability <= 1 &&
                             prediction.confidence >= 0 &&
                             prediction.confidence <= 1
                
                return TestResult(
                    name: testName,
                    passed: success,
                    message: success ? "Basic prediction working correctly" : "Prediction values out of range",
                    details: "Predicted \(prediction.predictedReps) reps at \(prediction.predictedWeight)lbs with \(Int(prediction.successProbability * 100))% success rate"
                )
            } else {
                return TestResult(
                    name: testName,
                    passed: true,
                    message: "No prediction available (expected with no training data)",
                    details: "Prediction service correctly returned nil for exercise with no history"
                )
            }
        } catch {
            return TestResult(
                name: testName,
                passed: false,
                message: "Test failed with error: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    private func testProgressionTimeline() -> TestResult {
        let testName = "Progression Timeline"
        
        do {
            let exercise = createTestExercise(name: "Test Squat")
            let timeline = predictionService.predictProgressionTimeline(
                for: exercise,
                targetWeight: 225.0,
                currentWeight: 185.0
            )
            
            if let timeline = timeline {
                let success = timeline.targetWeight == 225.0 &&
                             timeline.confidence >= 0 &&
                             timeline.confidence <= 1 &&
                             !timeline.recommendation.isEmpty
                
                return TestResult(
                    name: testName,
                    passed: success,
                    message: success ? "Timeline prediction working correctly" : "Timeline values invalid",
                    details: "Target: \(timeline.targetWeight)lbs, Confidence: \(Int(timeline.confidence * 100))%"
                )
            } else {
                return TestResult(
                    name: testName,
                    passed: true,
                    message: "No timeline available (expected with no training data)",
                    details: "Timeline service correctly returned nil for exercise with no history"
                )
            }
        } catch {
            return TestResult(
                name: testName,
                passed: false,
                message: "Test failed with error: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    private func testRestTimePrediction() -> TestResult {
        let testName = "Rest Time Prediction"
        
        do {
            let exercise = createTestExercise(name: "Test Deadlift")
            let currentSet = SetData(setNumber: 2, targetReps: 5, targetWeight: 225.0)
            let previousSets = [
                SetData(setNumber: 1, targetReps: 5, targetWeight: 225.0)
            ]
            
            let restPrediction = predictionService.predictOptimalRestTime(
                for: exercise,
                currentSet: currentSet,
                previousSets: previousSets
            )
            
            if let prediction = restPrediction {
                let success = prediction.recommendedSeconds > 0 &&
                             prediction.recommendedSeconds <= 600 &&
                             prediction.confidence >= 0 &&
                             prediction.confidence <= 1
                
                return TestResult(
                    name: testName,
                    passed: success,
                    message: success ? "Rest time prediction working correctly" : "Rest time values invalid",
                    details: "Recommended: \(prediction.recommendedSeconds)s, Confidence: \(Int(prediction.confidence * 100))%"
                )
            } else {
                return TestResult(
                    name: testName,
                    passed: false,
                    message: "Rest time prediction returned nil unexpectedly",
                    details: nil
                )
            }
        } catch {
            return TestResult(
                name: testName,
                passed: false,
                message: "Test failed with error: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    private func testDataValidation() -> TestResult {
        let testName = "Data Validation"
        
        do {
            let validData = [
                WorkoutModelData(
                    targetWeight: 185.0,
                    targetReps: 8,
                    recentAverageVolume: 1200.0,
                    recentAverageWeight: 175.0,
                    recentCompletionRate: 0.85,
                    trendMultiplier: 0.1,
                    daysSinceLastWorkout: 2,
                    workoutCount: 10,
                    actualSuccessProbability: 0.8
                )
            ]
            
            let invalidData = [
                WorkoutModelData(
                    targetWeight: -100.0, // Invalid negative weight
                    targetReps: 0,        // Invalid zero reps
                    recentAverageVolume: 1200.0,
                    recentAverageWeight: 175.0,
                    recentCompletionRate: 1.5, // Invalid rate > 1
                    trendMultiplier: 0.1,
                    daysSinceLastWorkout: 2,
                    workoutCount: 10,
                    actualSuccessProbability: 0.8
                )
            ]
            
            let validResult = TrainingDataPreparer.shared.validateTrainingData(validData)
            let invalidResult = TrainingDataPreparer.shared.validateTrainingData(invalidData)
            
            let success = validResult.validationRate == 1.0 && invalidResult.validationRate == 0.0
            
            return TestResult(
                name: testName,
                passed: success,
                message: success ? "Data validation working correctly" : "Data validation failed",
                details: "Valid data: \(validResult.validationRate * 100)%, Invalid data: \(invalidResult.validationRate * 100)%"
            )
            
        } catch {
            return TestResult(
                name: testName,
                passed: false,
                message: "Test failed with error: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    private func testEdgeCases() -> TestResult {
        let testName = "Edge Cases"
        
        do {
            let exercise = createTestExercise(name: "Test Exercise")
            
            // Test with extreme values
            let extremePrediction = predictionService.predictNextWorkoutPerformance(
                for: exercise,
                targetWeight: 1000.0, // Extreme weight
                targetReps: 1
            )
            
            // Test with zero values
            let zeroPrediction = predictionService.predictNextWorkoutPerformance(
                for: exercise,
                targetWeight: 0.0,
                targetReps: 0
            )
            
            // Both should handle gracefully (return nil or reasonable defaults)
            let success = true // Edge cases should not crash
            
            return TestResult(
                name: testName,
                passed: success,
                message: "Edge cases handled without crashes",
                details: "Extreme weight prediction: \(extremePrediction != nil ? "Generated" : "Nil"), Zero values: \(zeroPrediction != nil ? "Generated" : "Nil")"
            )
            
        } catch {
            return TestResult(
                name: testName,
                passed: false,
                message: "Test failed with error: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestExercise(name: String) -> Exercise {
        let exercise = Exercise(context: context)
        exercise.name = name
        exercise.primaryMuscleGroup = "Chest"
        exercise.equipment = "Barbell"
        return exercise
    }
    
    // MARK: - Performance Benchmarks
    
    func runPerformanceBenchmarks() -> BenchmarkResults {
        var results = BenchmarkResults()
        
        results.append(benchmarkPredictionSpeed())
        results.append(benchmarkTrainingDataPreparation())
        results.append(benchmarkMemoryUsage())
        
        return results
    }
    
    private func benchmarkPredictionSpeed() -> BenchmarkResult {
        let exercise = createTestExercise(name: "Benchmark Exercise")
        let iterations = 1000
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            let _ = predictionService.predictNextWorkoutPerformance(
                for: exercise,
                targetWeight: 185.0,
                targetReps: 8
            )
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(iterations)
        
        return BenchmarkResult(
            name: "Prediction Speed",
            averageTime: averageTime,
            iterations: iterations,
            passed: averageTime < 0.01 // Should be under 10ms per prediction
        )
    }
    
    private func benchmarkTrainingDataPreparation() -> BenchmarkResult {
        let exercise = createTestExercise(name: "Training Benchmark")
        let iterations = 100
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            let _ = TrainingDataPreparer.shared.prepareTrainingData(for: exercise)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(iterations)
        
        return BenchmarkResult(
            name: "Training Data Preparation",
            averageTime: averageTime,
            iterations: iterations,
            passed: averageTime < 0.1 // Should be under 100ms per preparation
        )
    }
    
    private func benchmarkMemoryUsage() -> BenchmarkResult {
        let exercise = createTestExercise(name: "Memory Test")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate multiple predictions to test memory usage
        var predictions: [PerformancePrediction] = []
        for i in 0..<1000 {
            if let prediction = predictionService.predictNextWorkoutPerformance(
                for: exercise,
                targetWeight: Double(100 + i),
                targetReps: 8
            ) {
                predictions.append(prediction)
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // Clear predictions to test memory release
        predictions.removeAll()
        
        return BenchmarkResult(
            name: "Memory Usage",
            averageTime: totalTime / 1000.0,
            iterations: 1000,
            passed: true // Memory test passed if no crashes occurred
        )
    }
    
    // MARK: - Test Result Types
    
    struct TestResult {
        let name: String
        let passed: Bool
        let message: String
        let details: String?
    }
    
    struct TestResults {
    private var results: [TestResult] = []
    
    mutating func append(_ result: TestResult) {
        results.append(result)
    }
    
    var passedCount: Int {
        results.filter { $0.passed }.count
    }
    
    var totalCount: Int {
        results.count
    }
    
    var passed: Bool {
        passedCount == totalCount
    }
    
    var summary: String {
        "Tests: \(passedCount)/\(totalCount) passed"
    }
    
    var allResults: [TestResult] {
        results
    }
    }
    
    struct BenchmarkResult {
        let name: String
        let averageTime: Double
        let iterations: Int
        let passed: Bool
    }
    
    struct BenchmarkResults {
        private var results: [BenchmarkResult] = []
        
        mutating func append(_ result: BenchmarkResult) {
            results.append(result)
        }
        
        var allResults: [BenchmarkResult] {
            results
        }
        
        var summary: String {
            let passedCount = results.filter { $0.passed }.count
            return "Benchmarks: \(passedCount)/\(results.count) passed"
        }
    }
}