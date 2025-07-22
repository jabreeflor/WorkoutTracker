import Foundation
import CoreData
import Combine

@MainActor
class AICoachService: ObservableObject {
    static let shared = AICoachService()
    
    private let coreDataManager = CoreDataManager.shared
    private let premiumService = PremiumSubscriptionService.shared
    private let workoutHistoryService = WorkoutHistoryService.shared
    
    @Published var coachingInsights: [CoachingInsight] = []
    @Published var dailyRecommendation: DailyRecommendation?
    @Published var workoutPlan: WeeklyPlan?
    @Published var isGeneratingInsights = false
    @Published var lastUpdateDate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Coaching Models
    
    struct CoachingInsight: Identifiable, Codable {
        let id: UUID
        let type: InsightType
        let title: String
        let message: String
        let actionable: Bool
        let priority: Priority
        let createdDate: Date
        let expiryDate: Date?
        let relatedExercises: [String]
        let metrics: [String: Double]
        
        init(type: InsightType, title: String, message: String, actionable: Bool, priority: Priority, createdDate: Date, expiryDate: Date? = nil, relatedExercises: [String] = [], metrics: [String: Double] = [:]) {
            self.id = UUID()
            self.type = type
            self.title = title
            self.message = message
            self.actionable = actionable
            self.priority = priority
            self.createdDate = createdDate
            self.expiryDate = expiryDate
            self.relatedExercises = relatedExercises
            self.metrics = metrics
        }
        
        enum InsightType: String, CaseIterable, Codable {
            case performance = "performance"
            case recovery = "recovery"
            case progression = "progression"
            case form = "form"
            case motivation = "motivation"
            case nutrition = "nutrition"
            case volume = "volume"
            case frequency = "frequency"
            case balance = "balance"
            case plateau = "plateau"
            
            var icon: String {
                switch self {
                case .performance: return "chart.line.uptrend.xyaxis"
                case .recovery: return "bed.double"
                case .progression: return "arrow.up.right"
                case .form: return "eye"
                case .motivation: return "flame"
                case .nutrition: return "leaf"
                case .volume: return "scalemass"
                case .frequency: return "calendar"
                case .balance: return "scale.3d"
                case .plateau: return "chart.line.flattrend.xyaxis"
                }
            }
            
            var color: String {
                switch self {
                case .performance: return "blue"
                case .recovery: return "purple"
                case .progression: return "green"
                case .form: return "orange"
                case .motivation: return "red"
                case .nutrition: return "green"
                case .volume: return "indigo"
                case .frequency: return "teal"
                case .balance: return "yellow"
                case .plateau: return "gray"
                }
            }
        }
        
        enum Priority: Int, CaseIterable, Codable {
            case low = 1
            case medium = 2
            case high = 3
            case critical = 4
            
            var description: String {
                switch self {
                case .low: return "Low"
                case .medium: return "Medium"
                case .high: return "High"
                case .critical: return "Critical"
                }
            }
        }
    }
    
    struct DailyRecommendation: Identifiable, Codable {
        let id: UUID
        let date: Date
        let recommendedWorkout: RecommendedWorkout?
        let restDay: Bool
        let reason: String
        let tips: [String]
        let estimatedDuration: Int // minutes
        let difficulty: Difficulty
        
        init(date: Date, recommendedWorkout: RecommendedWorkout? = nil, restDay: Bool, reason: String, tips: [String] = [], estimatedDuration: Int, difficulty: Difficulty) {
            self.id = UUID()
            self.date = date
            self.recommendedWorkout = recommendedWorkout
            self.restDay = restDay
            self.reason = reason
            self.tips = tips
            self.estimatedDuration = estimatedDuration
            self.difficulty = difficulty
        }
        
        enum Difficulty: String, CaseIterable, Codable {
            case easy = "easy"
            case moderate = "moderate"
            case hard = "hard"
            case intense = "intense"
            
            var emoji: String {
                switch self {
                case .easy: return "😌"
                case .moderate: return "💪"
                case .hard: return "🔥"
                case .intense: return "⚡"
                }
            }
        }
    }
    
    struct RecommendedWorkout: Codable {
        let name: String
        let type: String
        let focusAreas: [String]
        let exercises: [RecommendedExercise]
        let warmup: [String]
        let cooldown: [String]
    }
    
    struct RecommendedExercise: Codable {
        let name: String
        let sets: Int
        let reps: String // Can be range like "8-12"
        let weight: String // Percentage or specific weight
        let notes: String?
    }
    
    struct WeeklyPlan: Identifiable, Codable {
        let id: UUID
        let weekStarting: Date
        let goals: [String]
        let dailyPlans: [DailyPlan]
        let totalWorkouts: Int
        let estimatedTime: Int // minutes per week
        let focusAreas: [String]
        
        init(weekStarting: Date, goals: [String], dailyPlans: [DailyPlan], totalWorkouts: Int, estimatedTime: Int, focusAreas: [String]) {
            self.id = UUID()
            self.weekStarting = weekStarting
            self.goals = goals
            self.dailyPlans = dailyPlans
            self.totalWorkouts = totalWorkouts
            self.estimatedTime = estimatedTime
            self.focusAreas = focusAreas
        }
    }
    
    struct DailyPlan: Codable {
        let dayOfWeek: Int // 1-7
        let dayName: String
        let recommendation: DailyRecommendation
    }
    
    // MARK: - User Profile for AI Analysis
    
    struct UserProfile: Codable {
        let fitnessLevel: FitnessLevel
        let goals: [FitnessGoal]
        let availableDays: [Int] // Days of week available for workout
        let sessionDuration: Int // Preferred session length in minutes
        let equipment: [Equipment]
        let injuries: [String]
        let preferences: WorkoutPreferences
        
        enum FitnessLevel: String, CaseIterable, Codable {
            case beginner = "beginner"
            case intermediate = "intermediate"
            case advanced = "advanced"
            case expert = "expert"
        }
        
        enum FitnessGoal: String, CaseIterable, Codable {
            case strength = "strength"
            case endurance = "endurance"
            case hypertrophy = "hypertrophy"
            case powerlifting = "powerlifting"
            case weightLoss = "weight_loss"
            case athletic = "athletic"
            case general = "general_fitness"
            case rehabilitation = "rehabilitation"
        }
        
        enum Equipment: String, CaseIterable, Codable {
            case bodyweight = "bodyweight"
            case dumbbells = "dumbbells"
            case barbell = "barbell"
            case resistance_bands = "resistance_bands"
            case kettlebells = "kettlebells"
            case machines = "machines"
            case cables = "cables"
            case full_gym = "full_gym"
        }
        
        struct WorkoutPreferences: Codable {
            let intensityPreference: Double // 0.0 - 1.0
            let volumePreference: Double // 0.0 - 1.0
            let varietyPreference: Double // 0.0 - 1.0
            let compoundMovementFocus: Bool
            let cardioIntegration: Bool
        }
    }
    
    private init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Update insights when premium status changes
        premiumService.$isSubscribed
            .sink { [weak self] isSubscribed in
                if isSubscribed {
                    Task {
                        await self?.generateDailyInsights()
                    }
                } else {
                    self?.clearPremiumData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func generateDailyInsights() async {
        guard premiumService.canUseAICoach else {
            print("AI Coach requires premium subscription")
            return
        }
        
        isGeneratingInsights = true
        
        do {
            // Analyze recent workout data
            let recentWorkouts = await getRecentWorkouts()
            let userProfile = await getUserProfile()
            
            // Generate various types of insights
            var insights: [CoachingInsight] = []
            
            insights.append(contentsOf: await analyzePerformanceTrends(recentWorkouts))
            insights.append(contentsOf: await analyzeRecoveryPatterns(recentWorkouts))
            insights.append(contentsOf: await analyzeProgression(recentWorkouts))
            insights.append(contentsOf: await detectPlateaus(recentWorkouts))
            insights.append(contentsOf: await analyzeWorkoutBalance(recentWorkouts))
            insights.append(contentsOf: await generateMotivationalInsights(recentWorkouts))
            
            // Sort by priority and date
            insights.sort { 
                if $0.priority.rawValue != $1.priority.rawValue {
                    return $0.priority.rawValue > $1.priority.rawValue
                }
                return $0.createdDate > $1.createdDate
            }
            
            // Generate daily recommendation
            let recommendation = await generateDailyRecommendation(
                recentWorkouts: recentWorkouts,
                userProfile: userProfile,
                insights: insights
            )
            
            // Generate weekly plan
            let weeklyPlan = await generateWeeklyPlan(
                userProfile: userProfile,
                insights: insights
            )
            
            coachingInsights = insights
            dailyRecommendation = recommendation
            workoutPlan = weeklyPlan
            lastUpdateDate = Date()
        } catch {
            print("Error generating insights: \(error)")
        }
        
        isGeneratingInsights = false
    }
    
    func getInsightsByType(_ type: CoachingInsight.InsightType) -> [CoachingInsight] {
        return coachingInsights.filter { $0.type == type }
    }
    
    func getHighPriorityInsights() -> [CoachingInsight] {
        return coachingInsights.filter { $0.priority.rawValue >= CoachingInsight.Priority.high.rawValue }
    }
    
    func markInsightAsRead(_ insight: CoachingInsight) {
        // In a real implementation, this would persist the read state
        // For now, we'll just remove it from the active insights
        coachingInsights.removeAll { $0.id == insight.id }
    }
    
    // MARK: - AI Analysis Methods
    
    private func getRecentWorkouts() async -> [WorkoutSession] {
        let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 30 // Last 30 workouts
        
        do {
            return try coreDataManager.context.fetch(request)
        } catch {
            print("Error fetching recent workouts: \(error)")
            return []
        }
    }
    
    private func getUserProfile() async -> UserProfile {
        // In a real implementation, this would be saved in Core Data or UserDefaults
        // For now, return a default profile
        return UserProfile(
            fitnessLevel: .intermediate,
            goals: [.strength, .hypertrophy],
            availableDays: [1, 3, 5], // Mon, Wed, Fri
            sessionDuration: 60,
            equipment: [.dumbbells, .barbell],
            injuries: [],
            preferences: UserProfile.WorkoutPreferences(
                intensityPreference: 0.7,
                volumePreference: 0.6,
                varietyPreference: 0.8,
                compoundMovementFocus: true,
                cardioIntegration: false
            )
        )
    }
    
    private func analyzePerformanceTrends(_ workouts: [WorkoutSession]) async -> [CoachingInsight] {
        var insights: [CoachingInsight] = []
        
        // Analyze volume trends
        if workouts.count >= 5 {
            let recentVolume = calculateAverageVolume(workouts.prefix(5))
            let previousVolume = calculateAverageVolume(workouts.dropFirst(5).prefix(5))
            
            if recentVolume > previousVolume * 1.15 {
                insights.append(CoachingInsight(
                    type: .performance,
                    title: "Volume Increase Detected",
                    message: "Your training volume has increased by \(Int((recentVolume / previousVolume - 1) * 100))% recently. Great progress! Make sure you're managing recovery properly.",
                    actionable: true,
                    priority: .medium,
                    createdDate: Date(),
                    expiryDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                    relatedExercises: [],
                    metrics: ["volume_increase": (recentVolume / previousVolume - 1) * 100]
                ))
            } else if recentVolume < previousVolume * 0.85 {
                insights.append(CoachingInsight(
                    type: .performance,
                    title: "Volume Decrease",
                    message: "Your training volume has decreased recently. Consider whether this is intentional (deload) or if you need to increase intensity.",
                    actionable: true,
                    priority: .medium,
                    createdDate: Date(),
                    expiryDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                    relatedExercises: [],
                    metrics: ["volume_decrease": (1 - recentVolume / previousVolume) * 100]
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeRecoveryPatterns(_ workouts: [WorkoutSession]) async -> [CoachingInsight] {
        var insights: [CoachingInsight] = []
        
        // Analyze workout frequency
        if workouts.count >= 7 {
            let dates = workouts.prefix(7).compactMap { $0.date }
            let daysBetweenWorkouts = zip(dates, dates.dropFirst()).map { 
                Calendar.current.dateComponents([.day], from: $1, to: $0).day ?? 0
            }
            
            let averageRestDays = Double(daysBetweenWorkouts.reduce(0, +)) / Double(daysBetweenWorkouts.count)
            
            if averageRestDays < 1 {
                insights.append(CoachingInsight(
                    type: .recovery,
                    title: "Insufficient Recovery Time",
                    message: "You're training very frequently with minimal rest days. Consider adding at least one full rest day per week for optimal recovery.",
                    actionable: true,
                    priority: .high,
                    createdDate: Date(),
                    expiryDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                    relatedExercises: [],
                    metrics: ["avg_rest_days": averageRestDays]
                ))
            } else if averageRestDays > 3 {
                insights.append(CoachingInsight(
                    type: .recovery,
                    title: "Long Rest Periods",
                    message: "You have long gaps between workouts. Consider increasing frequency for better consistency and progression.",
                    actionable: true,
                    priority: .medium,
                    createdDate: Date(),
                    expiryDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                    relatedExercises: [],
                    metrics: ["avg_rest_days": averageRestDays]
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeProgression(_ workouts: [WorkoutSession]) async -> [CoachingInsight] {
        var insights: [CoachingInsight] = []
        
        // Analyze exercise progression
        let exerciseProgressions = analyzeExerciseProgressions(workouts)
        
        for (exerciseName, progression) in exerciseProgressions {
            if progression.isImproving {
                insights.append(CoachingInsight(
                    type: .progression,
                    title: "Excellent Progress: \(exerciseName)",
                    message: "You've improved your \(exerciseName) by \(String(format: "%.1f", progression.improvementPercentage))% over recent sessions. Keep it up!",
                    actionable: false,
                    priority: .low,
                    createdDate: Date(),
                    expiryDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                    relatedExercises: [exerciseName],
                    metrics: ["improvement": progression.improvementPercentage]
                ))
            }
        }
        
        return insights
    }
    
    private func detectPlateaus(_ workouts: [WorkoutSession]) async -> [CoachingInsight] {
        var insights: [CoachingInsight] = []
        
        let exerciseProgressions = analyzeExerciseProgressions(workouts)
        
        for (exerciseName, progression) in exerciseProgressions {
            if progression.isPlateaued {
                insights.append(CoachingInsight(
                    type: .plateau,
                    title: "Plateau Detected: \(exerciseName)",
                    message: "Your \(exerciseName) hasn't improved in the last \(progression.stagnantSessions) sessions. Try varying rep ranges, tempo, or taking a deload week.",
                    actionable: true,
                    priority: .medium,
                    createdDate: Date(),
                    expiryDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
                    relatedExercises: [exerciseName],
                    metrics: ["stagnant_sessions": Double(progression.stagnantSessions)]
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeWorkoutBalance(_ workouts: [WorkoutSession]) async -> [CoachingInsight] {
        var insights: [CoachingInsight] = []
        
        // Analyze muscle group balance
        let muscleGroupFrequency = analyzeMuscleGroupFrequency(workouts.prefix(10))
        
        let totalWorkouts = muscleGroupFrequency.values.reduce(0, +)
        
        for (muscleGroup, frequency) in muscleGroupFrequency {
            let percentage = Double(frequency) / Double(totalWorkouts) * 100
            
            if percentage < 10 && ["Back", "Legs", "Chest"].contains(muscleGroup) {
                insights.append(CoachingInsight(
                    type: .balance,
                    title: "Underworked Muscle Group",
                    message: "You've only worked \(muscleGroup) in \(Int(percentage))% of recent workouts. Consider adding more \(muscleGroup.lowercased()) exercises for balanced development.",
                    actionable: true,
                    priority: .medium,
                    createdDate: Date(),
                    expiryDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                    relatedExercises: [],
                    metrics: ["frequency_percentage": percentage]
                ))
            }
        }
        
        return insights
    }
    
    private func generateMotivationalInsights(_ workouts: [WorkoutSession]) async -> [CoachingInsight] {
        var insights: [CoachingInsight] = []
        
        // Consistency insights
        if workouts.count >= 7 {
            let thisWeek = workouts.filter { 
                guard let date = $0.date else { return false }
                return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
            }
            
            if thisWeek.count >= 3 {
                insights.append(CoachingInsight(
                    type: .motivation,
                    title: "Consistency Champion!",
                    message: "You've completed \(thisWeek.count) workouts this week. Your consistency is paying off - keep up the excellent work!",
                    actionable: false,
                    priority: .low,
                    createdDate: Date(),
                    expiryDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                    relatedExercises: [],
                    metrics: ["weekly_workouts": Double(thisWeek.count)]
                ))
            }
        }
        
        return insights
    }
    
    private func generateDailyRecommendation(recentWorkouts: [WorkoutSession], userProfile: UserProfile, insights: [CoachingInsight]) async -> DailyRecommendation {
        let today = Date()
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: today)
        
        // Check if today is a scheduled workout day
        let isWorkoutDay = userProfile.availableDays.contains(dayOfWeek)
        
        // Check if user worked out yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let workedOutYesterday = recentWorkouts.contains { workout in
            guard let date = workout.date else { return false }
            return calendar.isDate(date, inSameDayAs: yesterday)
        }
        
        if !isWorkoutDay || (workedOutYesterday && shouldRecommendRest(recentWorkouts: recentWorkouts)) {
            return DailyRecommendation(
                date: today,
                recommendedWorkout: nil,
                restDay: true,
                reason: "Rest day for optimal recovery and muscle growth",
                tips: [
                    "Stay hydrated throughout the day",
                    "Focus on getting quality sleep",
                    "Consider light stretching or walking",
                    "Plan your next workout"
                ],
                estimatedDuration: 0,
                difficulty: .easy
            )
        }
        
        // Generate workout recommendation based on recent patterns
        let recommendedWorkout = generateWorkoutRecommendation(
            recentWorkouts: recentWorkouts,
            userProfile: userProfile,
            insights: insights
        )
        
        return DailyRecommendation(
            date: today,
            recommendedWorkout: recommendedWorkout,
            restDay: false,
            reason: "Based on your recent training patterns and goals",
            tips: [
                "Warm up thoroughly before starting",
                "Focus on proper form over heavy weight",
                "Stay hydrated throughout your workout",
                "Cool down and stretch after training"
            ],
            estimatedDuration: userProfile.sessionDuration,
            difficulty: .moderate
        )
    }
    
    private func generateWeeklyPlan(userProfile: UserProfile, insights: [CoachingInsight]) async -> WeeklyPlan {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        var dailyPlans: [DailyPlan] = []
        
        for dayOfWeek in 1...7 {
            let date = Calendar.current.date(byAdding: .day, value: dayOfWeek - 1, to: startOfWeek)!
            let dayName = Calendar.current.weekdaySymbols[dayOfWeek - 1]
            
            let isWorkoutDay = userProfile.availableDays.contains(dayOfWeek)
            
            let recommendation = DailyRecommendation(
                date: date,
                recommendedWorkout: isWorkoutDay ? generateWorkoutRecommendation(recentWorkouts: [], userProfile: userProfile, insights: insights) : nil,
                restDay: !isWorkoutDay,
                reason: isWorkoutDay ? "Scheduled training day" : "Rest and recovery day",
                tips: isWorkoutDay ? ["Focus on progressive overload", "Maintain proper form"] : ["Active recovery", "Prepare for next workout"],
                estimatedDuration: isWorkoutDay ? userProfile.sessionDuration : 0,
                difficulty: isWorkoutDay ? .moderate : .easy
            )
            
            dailyPlans.append(DailyPlan(
                dayOfWeek: dayOfWeek,
                dayName: dayName,
                recommendation: recommendation
            ))
        }
        
        return WeeklyPlan(
            weekStarting: startOfWeek,
            goals: userProfile.goals.map { $0.rawValue.capitalized },
            dailyPlans: dailyPlans,
            totalWorkouts: userProfile.availableDays.count,
            estimatedTime: userProfile.availableDays.count * userProfile.sessionDuration,
            focusAreas: ["Strength", "Muscle Building", "Progressive Overload"]
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateAverageVolume(_ workouts: some Collection<WorkoutSession>) -> Double {
        let volumes = workouts.compactMap { workout -> Double? in
            guard let exercises = workout.exercises?.allObjects as? [WorkoutExercise] else { return nil }
            return exercises.reduce(0.0) { total, exercise in
                total + exercise.setData.reduce(0.0) { setTotal, setData in
                    setTotal + (setData.actualWeight * Double(setData.actualReps))
                }
            }
        }
        
        return volumes.isEmpty ? 0 : volumes.reduce(0, +) / Double(volumes.count)
    }
    
    private func analyzeExerciseProgressions(_ workouts: [WorkoutSession]) -> [String: ExerciseProgression] {
        var progressions: [String: ExerciseProgression] = [:]
        
        // Group workouts by exercise
        var exerciseWorkouts: [String: [WorkoutExercise]] = [:]
        
        for workout in workouts {
            guard let exercises = workout.exercises?.allObjects as? [WorkoutExercise] else { continue }
            
            for exercise in exercises {
                guard let name = exercise.exercise?.name else { continue }
                exerciseWorkouts[name, default: []].append(exercise)
            }
        }
        
        // Analyze progression for each exercise
        for (exerciseName, exercises) in exerciseWorkouts {
            let sortedExercises = exercises.sorted { (ex1, ex2) in
                guard let date1 = ex1.workoutSession?.date, let date2 = ex2.workoutSession?.date else { return false }
                return date1 < date2
            }
            
            let progression = calculateExerciseProgression(sortedExercises)
            progressions[exerciseName] = progression
        }
        
        return progressions
    }
    
    private func calculateExerciseProgression(_ exercises: [WorkoutExercise]) -> ExerciseProgression {
        guard exercises.count >= 3 else {
            return ExerciseProgression(isImproving: false, isPlateaued: false, improvementPercentage: 0, stagnantSessions: 0)
        }
        
        let maxWeights = exercises.map { exercise in
            exercise.setData.map(\.actualWeight).max() ?? 0
        }
        
        let recent = maxWeights.suffix(3)
        let previous = maxWeights.dropLast(3).suffix(3)
        
        guard !previous.isEmpty else {
            return ExerciseProgression(isImproving: false, isPlateaued: false, improvementPercentage: 0, stagnantSessions: 0)
        }
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let previousAvg = previous.reduce(0, +) / Double(previous.count)
        
        let improvementPercentage = ((recentAvg - previousAvg) / previousAvg) * 100
        let isImproving = improvementPercentage > 5 // 5% improvement threshold
        
        // Check for plateau (no improvement in last few sessions)
        let lastThree = maxWeights.suffix(3)
        let isPlateaued = lastThree.allSatisfy { abs($0 - lastThree.first!) < 2.5 } && lastThree.count >= 3
        
        let stagnantSessions = isPlateaued ? lastThree.count : 0
        
        return ExerciseProgression(
            isImproving: isImproving,
            isPlateaued: isPlateaued,
            improvementPercentage: improvementPercentage,
            stagnantSessions: stagnantSessions
        )
    }
    
    private func analyzeMuscleGroupFrequency(_ workouts: some Collection<WorkoutSession>) -> [String: Int] {
        var frequency: [String: Int] = [:]
        
        for workout in workouts {
            guard let exercises = workout.exercises?.allObjects as? [WorkoutExercise] else { continue }
            
            var workoutMuscleGroups: Set<String> = []
            
            for exercise in exercises {
                if let primaryMuscle = exercise.exercise?.primaryMuscleGroup {
                    workoutMuscleGroups.insert(primaryMuscle)
                }
            }
            
            for muscleGroup in workoutMuscleGroups {
                frequency[muscleGroup, default: 0] += 1
            }
        }
        
        return frequency
    }
    
    private func shouldRecommendRest(recentWorkouts: [WorkoutSession]) -> Bool {
        // Recommend rest if worked out 3+ days in a row
        let last3Days = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let recentWorkoutDays = recentWorkouts.compactMap { $0.date }.filter { $0 >= last3Days }
        
        return recentWorkoutDays.count >= 3
    }
    
    private func generateWorkoutRecommendation(recentWorkouts: [WorkoutSession], userProfile: UserProfile, insights: [CoachingInsight]) -> RecommendedWorkout {
        // Simple workout generation based on muscle group rotation
        let muscleGroupFrequency = analyzeMuscleGroupFrequency(recentWorkouts.prefix(5))
        
        // Find least worked muscle group
        let primaryMuscleGroups = ["Chest", "Back", "Legs", "Shoulders", "Arms"]
        let leastWorked = primaryMuscleGroups.min { 
            muscleGroupFrequency[$0, default: 0] < muscleGroupFrequency[$1, default: 0] 
        } ?? "Chest"
        
        let workoutName = "\(leastWorked) Focus Workout"
        let exercises = generateExercisesForMuscleGroup(leastWorked, userProfile: userProfile)
        
        return RecommendedWorkout(
            name: workoutName,
            type: "Strength Training",
            focusAreas: [leastWorked],
            exercises: exercises,
            warmup: ["5 min light cardio", "Dynamic stretching", "Activation exercises"],
            cooldown: ["5 min cool down", "Static stretching", "Foam rolling"]
        )
    }
    
    private func generateExercisesForMuscleGroup(_ muscleGroup: String, userProfile: UserProfile) -> [RecommendedExercise] {
        let exerciseDatabase: [String: [String]] = [
            "Chest": ["Push-ups", "Bench Press", "Dumbbell Press", "Chest Flyes"],
            "Back": ["Pull-ups", "Rows", "Lat Pulldowns", "Deadlifts"],
            "Legs": ["Squats", "Lunges", "Leg Press", "Romanian Deadlifts"],
            "Shoulders": ["Overhead Press", "Lateral Raises", "Front Raises", "Rear Delts"],
            "Arms": ["Bicep Curls", "Tricep Dips", "Hammer Curls", "Tricep Extensions"]
        ]
        
        let exercises = exerciseDatabase[muscleGroup] ?? ["Push-ups"]
        
        return exercises.prefix(4).map { exerciseName in
            RecommendedExercise(
                name: exerciseName,
                sets: userProfile.fitnessLevel == .beginner ? 3 : 4,
                reps: userProfile.goals.contains(.strength) ? "4-6" : "8-12",
                weight: "Previous weight + 2.5lbs",
                notes: userProfile.fitnessLevel == .beginner ? "Focus on form over weight" : nil
            )
        }
    }
    
    private func clearPremiumData() {
        coachingInsights = []
        dailyRecommendation = nil
        workoutPlan = nil
        lastUpdateDate = nil
    }
    
    // MARK: - Supporting Types
    
    struct ExerciseProgression {
        let isImproving: Bool
        let isPlateaued: Bool
        let improvementPercentage: Double
        let stagnantSessions: Int
    }
}