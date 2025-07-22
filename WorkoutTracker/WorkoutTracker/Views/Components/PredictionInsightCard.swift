import SwiftUI

struct PredictionInsightCard: View {
    let prediction: PerformancePrediction
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("AI Prediction")
                        .font(.headline)
                    Text(exercise.name ?? "Unknown Exercise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ConfidenceIndicator(confidence: prediction.confidence)
            }
            
            HStack(spacing: 20) {
                PredictionMetric(
                    title: "Predicted Reps",
                    value: "\(prediction.predictedReps)",
                    color: .blue
                )
                
                PredictionMetric(
                    title: "Weight",
                    value: "\(Int(prediction.predictedWeight))lbs",
                    color: .green
                )
                
                PredictionMetric(
                    title: "Success Rate",
                    value: "\(Int(prediction.successProbability * 100))%",
                    color: successRateColor
                )
            }
            
            if !prediction.reasoning.isEmpty {
                Text(prediction.reasoning)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var successRateColor: Color {
        switch prediction.successProbability {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

struct PredictionMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < Int(confidence * 5) ? confidenceColor : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

struct ProgressionTimelineCard: View {
    let timeline: ProgressionTimeline
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Progression Timeline")
                        .font(.headline)
                    
                    if let weeks = timeline.estimatedWeeks {
                        Text("\(weeks) weeks to \(Int(timeline.targetWeight))lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Unable to predict timeline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                ConfidenceIndicator(confidence: timeline.confidence)
            }
            
            if !timeline.milestones.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(timeline.milestones.prefix(6).enumerated()), id: \.offset) { index, milestone in
                            MilestoneView(milestone: milestone, isFirst: index == 0)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            Text(timeline.recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MilestoneView: View {
    let milestone: ProgressionMilestone
    let isFirst: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isFirst ? Color.blue : Color.gray.opacity(0.6))
                .frame(width: 8, height: 8)
            
            Text("\(Int(milestone.weight))lbs")
                .font(.caption2)
                .fontWeight(.medium)
            
            Text("Week \(milestone.estimatedWeek)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct RestTimePredictionCard: View {
    let prediction: RestTimePrediction
    
    var body: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Optimal Rest Time")
                    .font(.headline)
                
                Text(formatRestTime(prediction.recommendedSeconds))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text(prediction.reasoning)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ConfidenceIndicator(confidence: prediction.confidence)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if remainingSeconds == 0 {
            return "\(minutes)m"
        } else {
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
}

// MARK: - Usage Example View

struct AIInsightsView: View {
    @State private var selectedExercise: Exercise?
    @State private var prediction: PerformancePrediction?
    @State private var timeline: ProgressionTimeline?
    @State private var restPrediction: RestTimePrediction?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let exercise = selectedExercise {
                        if let prediction = prediction {
                            PredictionInsightCard(prediction: prediction, exercise: exercise)
                        }
                        
                        if let timeline = timeline {
                            ProgressionTimelineCard(timeline: timeline, exercise: exercise)
                        }
                        
                        if let restPrediction = restPrediction {
                            RestTimePredictionCard(prediction: restPrediction)
                        }
                    } else {
                        Text("Select an exercise to see AI insights")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("AI Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Demo") {
                        loadDemoData()
                    }
                }
            }
        }
    }
    
    private func loadDemoData() {
        // Demo data for testing
        let demoExercise = Exercise(context: CoreDataManager.shared.context)
        demoExercise.name = "Bench Press"
        demoExercise.primaryMuscleGroup = "Chest"
        
        selectedExercise = demoExercise
        
        prediction = PerformancePrediction(
            predictedReps: 8,
            predictedWeight: 185.0,
            successProbability: 0.85,
            confidence: 0.78,
            reasoning: "High success probability based on recent performance trends"
        )
        
        timeline = ProgressionTimeline(
            targetWeight: 225.0,
            estimatedWeeks: 8,
            confidence: 0.72,
            milestones: [
                ProgressionMilestone(weight: 190.0, estimatedWeek: 2, confidence: 0.85),
                ProgressionMilestone(weight: 200.0, estimatedWeek: 4, confidence: 0.78),
                ProgressionMilestone(weight: 210.0, estimatedWeek: 6, confidence: 0.70),
                ProgressionMilestone(weight: 225.0, estimatedWeek: 8, confidence: 0.65)
            ],
            recommendation: "Maintain consistent training schedule for optimal progression"
        )
        
        restPrediction = RestTimePrediction(
            recommendedSeconds: 150,
            confidence: 0.75,
            reasoning: "Based on compound movement and current weight"
        )
    }
}

#Preview {
    AIInsightsView()
}