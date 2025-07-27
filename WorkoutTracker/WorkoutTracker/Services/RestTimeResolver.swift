import Foundation
import SwiftUI
import CoreData

/// Service responsible for resolving rest times based on hierarchy: Set-specific > Exercise-specific > Global default
@MainActor
class RestTimeResolver: ObservableObject {
    static let shared = RestTimeResolver()
    
    // MARK: - Default Rest Times
    private let globalDefaultRestTime: Int = 90 // 90 seconds default
    
    // MARK: - Settings Keys
    private let globalRestTimeKey = "globalDefaultRestTime"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Resolves the appropriate rest time for a given set
    /// Priority: Set-specific > Exercise-specific > Global default
    func resolveRestTime(for setData: SetData, exercise: Exercise? = nil) -> Int {
        // 1. Check for set-specific rest time (highest priority)
        if let setRestTime = setData.restTime {
            return setRestTime
        }
        
        // 2. Check for exercise-specific rest time
        if let exercise = exercise, let exerciseRestTime = getExerciseRestTime(for: exercise) {
            return exerciseRestTime
        }
        
        // 3. Fall back to global default
        return getGlobalDefaultRestTime()
    }
    
    /// Gets the global default rest time
    func getGlobalDefaultRestTime() -> Int {
        return UserDefaults.standard.object(forKey: globalRestTimeKey) as? Int ?? globalDefaultRestTime
    }
    
    /// Sets the global default rest time
    func setGlobalDefaultRestTime(_ seconds: Int) {
        UserDefaults.standard.set(seconds, forKey: globalRestTimeKey)
    }
    
    /// Gets the exercise-specific rest time if set
    func getExerciseRestTime(for exercise: Exercise) -> Int? {
        // For now, we'll use a simple UserDefaults approach
        // In a full implementation, this would be stored in Core Data
        let key = "exerciseRestTime_\(exercise.objectID.uriRepresentation().absoluteString)"
        let restTime = UserDefaults.standard.object(forKey: key) as? Int
        return restTime == 0 ? nil : restTime
    }
    
    /// Sets the exercise-specific rest time
    func setExerciseRestTime(for exercise: Exercise, seconds: Int?) {
        let key = "exerciseRestTime_\(exercise.objectID.uriRepresentation().absoluteString)"
        if let seconds = seconds {
            UserDefaults.standard.set(seconds, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    /// Returns a description of which rest time source is being used
    func getRestTimeSource(for setData: SetData, exercise: Exercise? = nil) -> RestTimeSource {
        if setData.restTime != nil {
            return .setSpecific
        }
        
        if let exercise = exercise, getExerciseRestTime(for: exercise) != nil {
            return .exerciseSpecific
        }
        
        return .globalDefault
    }
    
    /// Common rest time presets
    static let commonRestTimes: [RestTimePreset] = [
        RestTimePreset(seconds: 30, label: "30s", description: "Quick rest"),
        RestTimePreset(seconds: 60, label: "1m", description: "Light exercises"),
        RestTimePreset(seconds: 90, label: "1m 30s", description: "Moderate exercises"),
        RestTimePreset(seconds: 120, label: "2m", description: "Heavy exercises"),
        RestTimePreset(seconds: 180, label: "3m", description: "Compound movements"),
        RestTimePreset(seconds: 300, label: "5m", description: "Max effort sets")
    ]
    
    /// Formats rest time in seconds to a readable string
    static func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds % 60 == 0 {
            let minutes = seconds / 60
            return "\(minutes)m"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
    
    // MARK: - Bulk Operations
    
    /// Sets the rest time for multiple exercises at once
    func setBulkExerciseRestTimes(for exercises: [Exercise], seconds: Int?) {
        for exercise in exercises {
            setExerciseRestTime(for: exercise, seconds: seconds)
        }
    }
    
    /// Exports rest time settings as a dictionary
    func exportRestTimeSettings() -> [String: Any] {
        var settings: [String: Any] = [:]
        
        // Export global settings
        settings["globalDefaultRestTime"] = getGlobalDefaultRestTime()
        
        // Export exercise-specific settings
        var exerciseSettings: [String: Int] = [:]
        
        // We need to fetch all exercises to get their IDs
        let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        
        if let exercises = try? CoreDataManager.shared.context.fetch(fetchRequest) {
            for exercise in exercises {
                if let restTime = getExerciseRestTime(for: exercise) {
                    let key = exercise.objectID.uriRepresentation().absoluteString
                    exerciseSettings[key] = restTime
                }
            }
        }
        
        settings["exerciseRestTimes"] = exerciseSettings
        
        return settings
    }
    
    /// Imports rest time settings from a dictionary
    func importRestTimeSettings(from settings: [String: Any]) -> Bool {
        // Import global settings
        if let globalTime = settings["globalDefaultRestTime"] as? Int {
            setGlobalDefaultRestTime(globalTime)
        }
        
        // Import exercise-specific settings
        if let exerciseSettings = settings["exerciseRestTimes"] as? [String: Int] {
            for (urlString, restTime) in exerciseSettings {
                // Try to find the exercise by URL representation
                if let url = URL(string: urlString),
                   let objectID = CoreDataManager.shared.context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
                   let exercise = try? CoreDataManager.shared.context.existingObject(with: objectID) as? Exercise {
                    setExerciseRestTime(for: exercise, seconds: restTime)
                }
            }
            return true
        }
        
        return false
    }
}

// MARK: - Supporting Types

enum RestTimeSource {
    case setSpecific
    case exerciseSpecific
    case globalDefault
    
    var description: String {
        switch self {
        case .setSpecific:
            return "Set-specific"
        case .exerciseSpecific:
            return "Exercise default"
        case .globalDefault:
            return "Global default"
        }
    }
    
    var color: Color {
        switch self {
        case .setSpecific:
            return .blue
        case .exerciseSpecific:
            return .orange
        case .globalDefault:
            return .gray
        }
    }
}

struct RestTimePreset: Identifiable {
    let id = UUID()
    let seconds: Int
    let label: String
    let description: String
}