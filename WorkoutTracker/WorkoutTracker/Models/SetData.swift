import Foundation

struct SetData: Codable, Identifiable, Equatable {
    let id: UUID
    var setNumber: Int
    var targetReps: Int
    var actualReps: Int
    var targetWeight: Double
    var actualWeight: Double
    var completed: Bool
    var restTime: Int?
    var notes: String?
    var timestamp: Date?
    
    init(setNumber: Int, targetReps: Int = 10, targetWeight: Double = 0.0) {
        self.id = UUID()
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.actualReps = targetReps
        self.targetWeight = targetWeight
        self.actualWeight = targetWeight
        self.completed = false
        self.restTime = nil
        self.notes = nil
        self.timestamp = nil
    }
    
    var volume: Double {
        return Double(actualReps) * actualWeight
    }
    
    var isCompleted: Bool {
        return completed && actualReps > 0
    }
    
    mutating func markCompleted() {
        completed = true
        timestamp = Date()
    }
    
    mutating func updateActuals(reps: Int, weight: Double) {
        actualReps = reps
        actualWeight = weight
    }
    
    static func == (lhs: SetData, rhs: SetData) -> Bool {
        return lhs.id == rhs.id
    }
}



extension SetData {
    static let sample = SetData(
        setNumber: 1,
        targetReps: 10,
        targetWeight: 135.0
    )
    
    static let sampleCompleted: SetData = {
        var set = SetData(setNumber: 1, targetReps: 10, targetWeight: 135.0)
        set.actualReps = 12
        set.actualWeight = 135.0
        set.completed = true
        set.timestamp = Date()
        return set
    }()
}

// MARK: - JSON Encoding/Decoding Helpers
extension Array where Element == SetData {
    func toJSON() -> String {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            print("Error encoding SetData array: \(error)")
            return "[]"
        }
    }
    
    static func fromJSON(_ jsonString: String) -> [SetData] {
        guard let data = jsonString.data(using: .utf8) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([SetData].self, from: data)
        } catch {
            print("Error decoding SetData array: \(error)")
            return []
        }
    }
}

// MARK: - Analytics Helpers
extension Array where Element == SetData {
    var totalVolume: Double {
        return reduce(0) { $0 + $1.volume }
    }
    
    var completedSets: [SetData] {
        return filter { $0.isCompleted }
    }
    
    var completionRate: Double {
        guard !isEmpty else { return 0.0 }
        return Double(completedSets.count) / Double(count)
    }
    
    var averageReps: Double {
        let completed = completedSets
        guard !completed.isEmpty else { return 0.0 }
        return Double(completed.reduce(0) { $0 + $1.actualReps }) / Double(completed.count)
    }
    
    var averageWeight: Double {
        let completed = completedSets
        guard !completed.isEmpty else { return 0.0 }
        return completed.reduce(0) { $0 + $1.actualWeight } / Double(completed.count)
    }
    

}