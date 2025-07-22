import SwiftUI

struct AICoachDashboardView: View {
    @StateObject private var aiCoach = AICoachService.shared
    @StateObject private var premiumService = PremiumSubscriptionService.shared
    @State private var isRefreshing = false
    @State private var selectedInsightType: AICoachService.CoachingInsight.InsightType?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                coachHeaderView
                
                // Daily Recommendation
                if let recommendation = aiCoach.dailyRecommendation {
                    dailyRecommendationCard(recommendation)
                }
                
                // Insights Overview
                insightsOverviewSection
                
                // High Priority Insights
                highPriorityInsightsSection
                
                // Weekly Plan Preview
                if let weeklyPlan = aiCoach.workoutPlan {
                    weeklyPlanPreview(weeklyPlan)
                }
                
                // All Insights by Category
                insightsByCategorySection
            }
            .padding()
        }
        .refreshable {
            await refreshInsights()
        }
        .task {
            if aiCoach.coachingInsights.isEmpty {
                await aiCoach.generateDailyInsights()
            }
        }
    }
    
    // MARK: - Header
    
    private var coachHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Personal Coach")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let lastUpdate = aiCoach.lastUpdateDate {
                        Text("Updated \(lastUpdate, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await refreshInsights()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .disabled(aiCoach.isGeneratingInsights)
            }
            
            if aiCoach.isGeneratingInsights {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing your training data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Daily Recommendation
    
    private func dailyRecommendationCard(_ recommendation: AICoachService.DailyRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Recommendation")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(recommendation.difficulty.emoji)
                    .font(.title2)
            }
            
            if recommendation.restDay {
                restDayView(recommendation)
            } else {
                workoutDayView(recommendation)
            }
            
            // Tips Section
            if !recommendation.tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coach Tips")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    ForEach(recommendation.tips, id: \.self) { tip in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(tip)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func restDayView(_ recommendation: AICoachService.DailyRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("Rest Day")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Spacer()
            }
            
            Text(recommendation.reason)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func workoutDayView(_ recommendation: AICoachService.DailyRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let workout = recommendation.recommendedWorkout {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(workout.type)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(recommendation.estimatedDuration) min")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(recommendation.difficulty.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Focus Areas
                if !workout.focusAreas.isEmpty {
                    HStack {
                        Text("Focus:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(workout.focusAreas, id: \.self) { area in
                            Text(area)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                }
                
                // Exercise Preview
                if !workout.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Exercises Preview:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ForEach(workout.exercises.prefix(3), id: \.name) { exercise in
                            HStack {
                                Text("• \(exercise.name)")
                                    .font(.caption)
                                Text("\(exercise.sets) sets")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        
                        if workout.exercises.count > 3 {
                            Text("+ \(workout.exercises.count - 3) more exercises")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Insights Overview
    
    private var insightsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                insightMetricCard(
                    title: "Total Insights",
                    value: "\(aiCoach.coachingInsights.count)",
                    icon: "brain.head.profile",
                    color: .blue
                )
                
                insightMetricCard(
                    title: "High Priority",
                    value: "\(aiCoach.getHighPriorityInsights().count)",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )
                
                insightMetricCard(
                    title: "Performance",
                    value: "\(aiCoach.getInsightsByType(.performance).count)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                insightMetricCard(
                    title: "Recovery",
                    value: "\(aiCoach.getInsightsByType(.recovery).count)",
                    icon: "bed.double",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func insightMetricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - High Priority Insights
    
    private var highPriorityInsightsSection: some View {
        let highPriorityInsights = aiCoach.getHighPriorityInsights()
        
        return Group {
            if !highPriorityInsights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("High Priority Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(highPriorityInsights.prefix(3)) { insight in
                        insightCard(insight, isHighlighted: true)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Weekly Plan Preview
    
    private func weeklyPlanPreview(_ plan: AICoachService.WeeklyPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week's Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(plan.totalWorkouts) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(plan.dailyPlans, id: \.dayOfWeek) { dailyPlan in
                        weeklyPlanDayCard(dailyPlan)
                    }
                }
                .padding(.horizontal, 1)
            }
            
            HStack {
                Text("Total Time: \(plan.estimatedTime) min/week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Focus: \(plan.focusAreas.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func weeklyPlanDayCard(_ dailyPlan: AICoachService.DailyPlan) -> some View {
        VStack(spacing: 8) {
            Text(String(dailyPlan.dayName.prefix(3)))
                .font(.caption)
                .fontWeight(.medium)
            
            Circle()
                .fill(dailyPlan.recommendation.restDay ? Color.gray.opacity(0.3) : Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: dailyPlan.recommendation.restDay ? "bed.double" : "dumbbell")
                        .font(.caption)
                        .foregroundColor(dailyPlan.recommendation.restDay ? .gray : .white)
                )
            
            if !dailyPlan.recommendation.restDay {
                Text("\(dailyPlan.recommendation.estimatedDuration)m")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 60)
    }
    
    // MARK: - Insights by Category
    
    private var insightsByCategorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    categoryFilterButton(nil, title: "All")
                    
                    ForEach(AICoachService.CoachingInsight.InsightType.allCases, id: \.rawValue) { type in
                        categoryFilterButton(type, title: type.rawValue.capitalized)
                    }
                }
                .padding(.horizontal, 1)
            }
            
            // Filtered Insights
            let filteredInsights = selectedInsightType == nil ? 
                aiCoach.coachingInsights : 
                aiCoach.getInsightsByType(selectedInsightType!)
            
            if filteredInsights.isEmpty {
                emptyInsightsView
            } else {
                ForEach(filteredInsights) { insight in
                    insightCard(insight)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func categoryFilterButton(_ type: AICoachService.CoachingInsight.InsightType?, title: String) -> some View {
        Button(action: {
            selectedInsightType = type
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedInsightType == type ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(selectedInsightType == type ? .white : .primary)
                .cornerRadius(16)
        }
    }
    
    private var emptyInsightsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title)
                .foregroundColor(.gray)
            
            Text("No insights yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Complete a few workouts to get personalized coaching insights!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Insight Card
    
    private func insightCard(_ insight: AICoachService.CoachingInsight, isHighlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.icon)
                    .foregroundColor(colorForInsightType(insight.type))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(insight.type.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                priorityBadge(insight.priority)
            }
            
            Text(insight.message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if insight.actionable {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    
                    Text("Actionable insight")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Mark as Read") {
                        aiCoach.markInsightAsRead(insight)
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(isHighlighted ? Color.orange.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func priorityBadge(_ priority: AICoachService.CoachingInsight.Priority) -> some View {
        Text(priority.description)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColorForPriority(priority))
            .foregroundColor(textColorForPriority(priority))
            .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func refreshInsights() async {
        isRefreshing = true
        await aiCoach.generateDailyInsights()
        isRefreshing = false
    }
    
    private func colorForInsightType(_ type: AICoachService.CoachingInsight.InsightType) -> Color {
        switch type {
        case .performance: return .blue
        case .recovery: return .purple
        case .progression: return .green
        case .form: return .orange
        case .motivation: return .red
        case .nutrition: return .green
        case .volume: return .indigo
        case .frequency: return .teal
        case .balance: return .yellow
        case .plateau: return .gray
        }
    }
    
    private func backgroundColorForPriority(_ priority: AICoachService.CoachingInsight.Priority) -> Color {
        switch priority {
        case .low: return .blue.opacity(0.2)
        case .medium: return .yellow.opacity(0.2)
        case .high: return .orange.opacity(0.2)
        case .critical: return .red.opacity(0.2)
        }
    }
    
    private func textColorForPriority(_ priority: AICoachService.CoachingInsight.Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

#Preview {
    AICoachDashboardView()
}