import SwiftUI

// MARK: - Exercise Performance Card

struct ExercisePerformanceCard: View {
    let performance: ExercisePerformance
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(performance.exercise.name ?? "Unknown Exercise")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(performance.exercise.primaryMuscleGroup ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    PerformanceScoreIndicator(score: performance.overallScore)
                }
                
                HStack(spacing: 20) {
                    MetricView(
                        title: "Avg Volume",
                        value: "\(Int(performance.averageVolume))",
                        unit: "lbs",
                        color: .blue
                    )
                    
                    MetricView(
                        title: "Workouts",
                        value: "\(performance.totalWorkouts)",
                        unit: "",
                        color: .green
                    )
                    
                    MetricView(
                        title: "Progress",
                        value: String(format: "%.1f", performance.progressionRate * 100),
                        unit: "%",
                        color: performance.progressionRate > 0 ? .green : .orange
                    )
                }
                
                HStack {
                    ConsistencyBar(score: performance.consistencyScore)
                    
                    Spacer()
                    
                    if let lastDate = performance.lastWorkoutDate {
                        Text("Last: \(lastDate, formatter: DateFormatter.shortDate)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: ExerciseRecommendation
    
    var body: some View {
        HStack(spacing: 16) {
            // Priority indicator
            Circle()
                .fill(recommendation.priority.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(recommendation.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let exerciseName = recommendation.exerciseName {
                    Text("Exercise: \(exerciseName)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Button(recommendation.actionText) {
                // Handle recommendation action
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(recommendation.priority.color.opacity(0.1))
            .foregroundColor(recommendation.priority.color)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Exercise Comparison Card

struct ExerciseComparisonCard: View {
    let comparison: ExerciseComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(comparison.muscleGroup) Comparison")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ComparisonRow(
                    exercise1: comparison.exercise1.name ?? "Exercise 1",
                    exercise2: comparison.exercise2.name ?? "Exercise 2",
                    metric: "Volume",
                    value1: "\(Int(comparison.volume1))lbs",
                    value2: "\(Int(comparison.volume2))lbs",
                    better: comparison.volume1 > comparison.volume2 ? 1 : 2
                )
                
                ComparisonRow(
                    exercise1: comparison.exercise1.name ?? "Exercise 1",
                    exercise2: comparison.exercise2.name ?? "Exercise 2",
                    metric: "Progress",
                    value1: "\(String(format: "%.1f", comparison.progression1 * 100))%",
                    value2: "\(String(format: "%.1f", comparison.progression2 * 100))%",
                    better: comparison.progression1 > comparison.progression2 ? 1 : 2
                )
                
                ComparisonRow(
                    exercise1: comparison.exercise1.name ?? "Exercise 1",
                    exercise2: comparison.exercise2.name ?? "Exercise 2",
                    metric: "Frequency",
                    value1: "\(comparison.frequency1)x",
                    value2: "\(comparison.frequency2)x",
                    better: comparison.frequency1 > comparison.frequency2 ? 1 : 2
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(width: 280)
    }
}

// MARK: - Strength Trends Card

struct StrengthTrendsCard: View {
    let trends: StrengthTrends
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Strength Trends")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                TrendStrengthIndicator(strength: trends.trendStrength)
            }
            
            VStack(spacing: 12) {
                TrendRow(
                    title: "Volume",
                    trend: trends.volumeTrend,
                    description: volumeDescription
                )
                
                TrendRow(
                    title: "Strength",
                    trend: trends.strengthTrend,
                    description: strengthDescription
                )
                
                TrendRow(
                    title: "Endurance",
                    trend: trends.enduranceTrend,
                    description: enduranceDescription
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var volumeDescription: String {
        switch trends.volumeTrend {
        case .improving: return "Training volume is increasing"
        case .stable: return "Volume remains consistent"
        case .declining: return "Volume has decreased recently"
        }
    }
    
    private var strengthDescription: String {
        switch trends.strengthTrend {
        case .improving: return "Getting stronger over time"
        case .stable: return "Strength is maintaining"
        case .declining: return "Strength may be plateauing"
        }
    }
    
    private var enduranceDescription: String {
        switch trends.enduranceTrend {
        case .improving: return "Endurance is improving"
        case .stable: return "Endurance remains steady"
        case .declining: return "Endurance may be declining"
        }
    }
}

// MARK: - Supporting Views

struct PerformanceScoreIndicator: View {
    let score: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(score * 100))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(scoreColor)
            
            Text("Score")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct ConsistencyBar: View {
    let score: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Consistency")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(consistencyColor)
                        .frame(width: geometry.size.width * score, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .frame(width: 80)
    }
    
    private var consistencyColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

struct ComparisonRow: View {
    let exercise1: String
    let exercise2: String
    let metric: String
    let value1: String
    let value2: String
    let better: Int // 1 or 2
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(metric)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(value1)
                        .font(.subheadline)
                        .fontWeight(better == 1 ? .bold : .regular)
                        .foregroundColor(better == 1 ? .green : .primary)
                    
                    Text("vs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value2)
                        .font(.subheadline)
                        .fontWeight(better == 2 ? .bold : .regular)
                        .foregroundColor(better == 2 ? .green : .primary)
                }
            }
            
            Spacer()
            
            if better == 1 {
                Image(systemName: "arrow.left")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Image(systemName: "arrow.right")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }
}

struct TrendRow: View {
    let title: String
    let trend: TrendDirection
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: trend.icon)
                .foregroundColor(trend.color)
                .font(.subheadline)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct TrendStrengthIndicator: View {
    let strength: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < Int(strength * 3) ? .blue : Color(.systemGray4))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

#Preview {
    VStack(spacing: 16) {
        ExercisePerformanceCard(
            performance: ExercisePerformance(
                exercise: Exercise(),
                averageVolume: 1250.0,
                totalWorkouts: 8,
                progressionRate: 0.15,
                consistencyScore: 0.85,
                lastWorkoutDate: Date()
            ),
            onTap: {}
        )
        
        RecommendationCard(
            recommendation: ExerciseRecommendation(
                id: UUID(),
                type: .progression,
                title: "Increase Bench Press Weight",
                description: "You've been using the same weight for 3 workouts. Time to progress!",
                actionText: "Add Weight",
                priority: .high,
                exerciseName: "Bench Press"
            )
        )
    }
    .padding()
}