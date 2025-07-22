import SwiftUI
import CoreData

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)],
        animation: .default
    ) private var exercises: FetchedResults<Exercise>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: false)],
        animation: .default
    ) private var workoutSessions: FetchedResults<WorkoutSession>
    
    @StateObject private var insightsService = ExerciseInsightsService()
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var selectedExercise: Exercise?
    @State private var insights: ExerciseInsights?
    @State private var recommendations: [ExerciseRecommendation] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // AI Form Coach Section
                    aiCoachSection
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Exercise Performance Overview
                    exercisePerformanceSection
                    
                    // AI Recommendations
                    recommendationsSection
                    
                    // Exercise Comparison
                    exerciseComparisonSection
                    
                    // Progression Insights
                    progressionInsightsSection
                }
                .padding()
            }
            .navigationTitle("AI Insights")
            .refreshable {
                await refreshInsights()
            }
            .onAppear {
                Task {
                    await loadInsights()
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Workout Intelligence")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("AI-powered insights from your training data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            if isLoading {
                ProgressView("Analyzing workout data...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .onChange(of: selectedTimeframe) { _, _ in
            Task {
                await loadInsights()
            }
        }
    }
    
    // MARK: - AI Form Coach Section
    
    private var aiCoachSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "AI Form Coach", icon: "eye.fill")
            
            NavigationLink(destination: AICoachView()) {
                HStack(spacing: 16) {
                    VStack {
                        Image(systemName: "video.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                        
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analyze Your Form")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Record or import videos to get instant AI feedback on your exercise form and technique")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            InsightStatCard(
                title: "Total Workouts",
                value: "\(recentWorkoutCount)",
                icon: "dumbbell.fill",
                color: .blue
            )
            
            InsightStatCard(
                title: "Exercises Tracked",
                value: "\(exercisesWithData.count)",
                icon: "list.bullet",
                color: .green
            )
            
            InsightStatCard(
                title: "Average Volume",
                value: "\(Int(averageWeeklyVolume))lbs",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
            
            InsightStatCard(
                title: "Consistency Score",
                value: "\(Int(consistencyScore * 100))%",
                icon: "target",
                color: .purple
            )
        }
    }
    
    // MARK: - Exercise Performance Section
    
    private var exercisePerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Exercise Performance", icon: "chart.bar.fill")
            
            if !topPerformingExercises.isEmpty {
                VStack(spacing: 12) {
                    ForEach(topPerformingExercises, id: \.exercise.objectID) { performance in
                        ExercisePerformanceCard(performance: performance) {
                            selectedExercise = performance.exercise
                            Task {
                                await loadExerciseInsights(for: performance.exercise)
                            }
                        }
                    }
                }
            } else {
                EmptyStateView(
                    title: "No Exercise Data",
                    subtitle: "Complete some workouts to see performance insights",
                    icon: "chart.bar"
                )
            }
        }
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "AI Recommendations", icon: "lightbulb.fill")
            
            if !recommendations.isEmpty {
                VStack(spacing: 12) {
                    ForEach(recommendations, id: \.id) { recommendation in
                        RecommendationCard(recommendation: recommendation)
                    }
                }
            } else {
                EmptyStateView(
                    title: "Building Recommendations",
                    subtitle: "Complete more workouts for personalized AI suggestions",
                    icon: "brain.head.profile"
                )
            }
        }
    }
    
    // MARK: - Exercise Comparison Section
    
    private var exerciseComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Exercise Comparison", icon: "arrow.left.arrow.right")
            
            if exercisesWithData.count >= 2 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(exerciseComparisons, id: \.id) { comparison in
                            ExerciseComparisonCard(comparison: comparison)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                EmptyStateView(
                    title: "Need More Data",
                    subtitle: "Track at least 2 exercises to see comparisons",
                    icon: "arrow.left.arrow.right"
                )
            }
        }
    }
    
    // MARK: - Progression Insights Section
    
    private var progressionInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Progression Insights", icon: "chart.line.uptrend.xyaxis")
            
            if let selectedExercise = selectedExercise, let insights = insights {
                VStack(spacing: 16) {
                    // Performance Prediction Card
                    if let prediction = insights.nextWorkoutPrediction {
                        PredictionInsightCard(prediction: prediction, exercise: selectedExercise)
                    }
                    
                    // Progression Timeline Card
                    if let timeline = insights.progressionTimeline {
                        ProgressionTimelineCard(timeline: timeline, exercise: selectedExercise)
                    }
                    
                    // Strength Trends
                    StrengthTrendsCard(trends: insights.strengthTrends)
                }
            } else {
                VStack(spacing: 12) {
                    Text("Select an exercise above to see detailed progression insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if !exercisesWithData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(exercisesWithData.prefix(5), id: \.objectID) { exercise in
                                    Button(exercise.name ?? "Unknown") {
                                        selectedExercise = exercise
                                        Task {
                                            await loadExerciseInsights(for: exercise)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var recentWorkoutCount: Int {
        let cutoffDate = selectedTimeframe.cutoffDate
        return workoutSessions.filter { session in
            guard let date = session.date else { return false }
            return date >= cutoffDate
        }.count
    }
    
    private var exercisesWithData: [Exercise] {
        exercises.filter { exercise in
            guard let workoutExercises = exercise.workoutExercises?.allObjects as? [WorkoutExercise] else {
                return false
            }
            return !workoutExercises.isEmpty
        }
    }
    
    private var averageWeeklyVolume: Double {
        let cutoffDate = selectedTimeframe.cutoffDate
        let recentSessions = workoutSessions.filter { session in
            guard let date = session.date else { return false }
            return date >= cutoffDate
        }
        
        let totalVolume = recentSessions.reduce(0.0) { total, session in
            guard let exercises = session.exercises?.allObjects as? [WorkoutExercise] else {
                return total
            }
            return total + exercises.reduce(0.0) { $0 + $1.totalVolume }
        }
        
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], 
                                                           from: cutoffDate, 
                                                           to: Date()).weekOfYear ?? 1)
        return totalVolume / Double(weeks)
    }
    
    private var consistencyScore: Double {
        let cutoffDate = selectedTimeframe.cutoffDate
        let days = Calendar.current.dateComponents([.day], from: cutoffDate, to: Date()).day ?? 1
        let workoutDays = Set(workoutSessions.compactMap { session -> DateComponents? in
            guard let date = session.date, date >= cutoffDate else { return nil }
            return Calendar.current.dateComponents([.year, .month, .day], from: date)
        }).count
        
        return min(1.0, Double(workoutDays) / Double(days) * 7) // Normalize to weekly consistency
    }
    
    private var topPerformingExercises: [ExercisePerformance] {
        insightsService.getTopPerformingExercises(
            exercises: Array(exercisesWithData),
            timeframe: selectedTimeframe,
            context: viewContext
        )
    }
    
    private var exerciseComparisons: [ExerciseComparison] {
        insightsService.generateExerciseComparisons(
            exercises: Array(exercisesWithData.prefix(4)),
            timeframe: selectedTimeframe,
            context: viewContext
        )
    }
    
    // MARK: - Functions
    
    private func loadInsights() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load recommendations based on all exercise data
        recommendations = await insightsService.generateRecommendations(
            exercises: Array(exercisesWithData),
            workoutSessions: Array(workoutSessions),
            timeframe: selectedTimeframe,
            context: viewContext
        )
    }
    
    private func loadExerciseInsights(for exercise: Exercise) async {
        isLoading = true
        defer { isLoading = false }
        
        insights = await insightsService.generateExerciseInsights(
            for: exercise,
            timeframe: selectedTimeframe,
            context: viewContext
        )
    }
    
    private func refreshInsights() async {
        await loadInsights()
        if let selectedExercise = selectedExercise {
            await loadExerciseInsights(for: selectedExercise)
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct InsightStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Enums


#Preview {
    InsightsView()
}