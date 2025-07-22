import Foundation
import CoreML
#if canImport(CreateML)
import CreateML
#endif

class CoreMLModelManager {
    static let shared = CoreMLModelManager()
    private let modelName = "WorkoutPerformanceModel"
    private var performanceModel: MLModel?
    
    private init() {
        loadModel()
    }
    
    // MARK: - Model Loading
    
    private func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") else {
            print("Performance model not found in bundle")
            return
        }
        
        do {
            performanceModel = try MLModel(contentsOf: modelURL)
            print("Performance model loaded successfully")
        } catch {
            print("Failed to load performance model: \(error)")
        }
    }
    
    // MARK: - Model Training (Development Only - macOS/Catalyst)
    
    func trainPerformanceModel(with data: [WorkoutModelData]) -> Bool {
        #if canImport(CreateML) && !targetEnvironment(simulator)
        guard data.count >= 10 else {
            print("Insufficient training data. Need at least 10 samples.")
            return false
        }
        
        do {
            let trainingData = try MLDataTable(dictionary: prepareTrainingData(data))
            
            let regressor = try MLRegressor(trainingData: trainingData, 
                                         targetColumn: "success_probability")
            
            let modelURL = getModelURL()
            try regressor.write(to: modelURL)
            
            // Reload the model
            performanceModel = try MLModel(contentsOf: modelURL)
            
            print("Model trained and saved successfully")
            return true
            
        } catch {
            print("Failed to train model: \(error)")
            return false
        }
        #else
        print("Model training not available on this platform. Use fallback algorithm.")
        return false
        #endif
    }
    
    // MARK: - Prediction
    
    func predictPerformance(
        targetWeight: Double,
        targetReps: Int,
        recentAverageVolume: Double,
        recentAverageWeight: Double,
        recentCompletionRate: Double,
        trendMultiplier: Double,
        daysSinceLastWorkout: Int,
        workoutCount: Int
    ) -> Double? {
        guard let model = performanceModel else {
            print("Performance model not available")
            return nil
        }
        
        do {
            let input = WorkoutPerformanceInput(
                targetWeight: targetWeight,
                targetReps: Double(targetReps),
                recentAverageVolume: recentAverageVolume,
                recentAverageWeight: recentAverageWeight,
                recentCompletionRate: recentCompletionRate,
                trendMultiplier: trendMultiplier,
                daysSinceLastWorkout: Double(daysSinceLastWorkout),
                workoutCount: Double(workoutCount)
            )
            
            let prediction = try model.prediction(from: input)
            
            if let probabilityValue = prediction.featureValue(for: "success_probability")?.doubleValue {
                return probabilityValue
            }
            
        } catch {
            print("Prediction failed: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Data Preparation
    
    private func prepareTrainingData(_ data: [WorkoutModelData]) -> [String: Any] {
        #if canImport(CreateML) && !targetEnvironment(simulator)
        return [
            "target_weight": MLDataValue.doubleArray(data.map { $0.targetWeight }),
            "target_reps": MLDataValue.doubleArray(data.map { Double($0.targetReps) }),
            "recent_average_volume": MLDataValue.doubleArray(data.map { $0.recentAverageVolume }),
            "recent_average_weight": MLDataValue.doubleArray(data.map { $0.recentAverageWeight }),
            "recent_completion_rate": MLDataValue.doubleArray(data.map { $0.recentCompletionRate }),
            "trend_multiplier": MLDataValue.doubleArray(data.map { $0.trendMultiplier }),
            "days_since_last_workout": MLDataValue.doubleArray(data.map { Double($0.daysSinceLastWorkout) }),
            "workout_count": MLDataValue.doubleArray(data.map { Double($0.workoutCount) }),
            "success_probability": MLDataValue.doubleArray(data.map { $0.actualSuccessProbability })
        ]
        #else
        return [:]
        #endif
    }
    
    private func getModelURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("\(modelName).mlmodel")
    }
    
    // MARK: - Model Utilities
    
    func isModelAvailable() -> Bool {
        return performanceModel != nil
    }
    
    func retrain(with newData: [WorkoutModelData]) {
        DispatchQueue.global(qos: .background).async {
            let success = self.trainPerformanceModel(with: newData)
            DispatchQueue.main.async {
                if success {
                    print("Model retrained successfully")
                } else {
                    print("Model retraining failed")
                }
            }
        }
    }
}

// MARK: - Model Input Structure

class WorkoutPerformanceInput: NSObject, MLFeatureProvider {
    let targetWeight: Double
    let targetReps: Double
    let recentAverageVolume: Double
    let recentAverageWeight: Double
    let recentCompletionRate: Double
    let trendMultiplier: Double
    let daysSinceLastWorkout: Double
    let workoutCount: Double
    
    init(targetWeight: Double, targetReps: Double, recentAverageVolume: Double, 
         recentAverageWeight: Double, recentCompletionRate: Double, 
         trendMultiplier: Double, daysSinceLastWorkout: Double, workoutCount: Double) {
        self.targetWeight = targetWeight
        self.targetReps = targetReps
        self.recentAverageVolume = recentAverageVolume
        self.recentAverageWeight = recentAverageWeight
        self.recentCompletionRate = recentCompletionRate
        self.trendMultiplier = trendMultiplier
        self.daysSinceLastWorkout = daysSinceLastWorkout
        self.workoutCount = workoutCount
        super.init()
    }
    
    var featureNames: Set<String> {
        return [
            "target_weight",
            "target_reps",
            "recent_average_volume",
            "recent_average_weight",
            "recent_completion_rate",
            "trend_multiplier",
            "days_since_last_workout",
            "workout_count"
        ]
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        switch featureName {
        case "target_weight":
            return MLFeatureValue(double: targetWeight)
        case "target_reps":
            return MLFeatureValue(double: targetReps)
        case "recent_average_volume":
            return MLFeatureValue(double: recentAverageVolume)
        case "recent_average_weight":
            return MLFeatureValue(double: recentAverageWeight)
        case "recent_completion_rate":
            return MLFeatureValue(double: recentCompletionRate)
        case "trend_multiplier":
            return MLFeatureValue(double: trendMultiplier)
        case "days_since_last_workout":
            return MLFeatureValue(double: daysSinceLastWorkout)
        case "workout_count":
            return MLFeatureValue(double: workoutCount)
        default:
            return nil
        }
    }
}

// MARK: - Training Data Structure

struct WorkoutModelData: Codable {
    let targetWeight: Double
    let targetReps: Int
    let recentAverageVolume: Double
    let recentAverageWeight: Double
    let recentCompletionRate: Double
    let trendMultiplier: Double
    let daysSinceLastWorkout: Int
    let workoutCount: Int
    let actualSuccessProbability: Double
    
    enum CodingKeys: String, CodingKey {
        case targetWeight = "target_weight"
        case targetReps = "target_reps"
        case recentAverageVolume = "recent_average_volume"
        case recentAverageWeight = "recent_average_weight"
        case recentCompletionRate = "recent_completion_rate"
        case trendMultiplier = "trend_multiplier"
        case daysSinceLastWorkout = "days_since_last_workout"
        case workoutCount = "workout_count"
        case actualSuccessProbability = "actual_success_probability"
    }
}

// MARK: - Model Performance Metrics

struct ModelMetrics {
    let accuracy: Double
    let meanSquaredError: Double
    let trainingDataSize: Int
    let lastTrainingDate: Date
    
    var isReliable: Bool {
        return accuracy > 0.7 && trainingDataSize > 50
    }
}