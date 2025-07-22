import SwiftUI

struct FormAnalysisResultView: View {
    let result: VideoFormAnalysisResult
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tabItem {
                            Image(systemName: "chart.bar.fill")
                            Text("Overview")
                        }
                        .tag(0)
                    
                    feedbackTab
                        .tabItem {
                            Image(systemName: "bubble.left.fill")
                            Text("Feedback")
                        }
                        .tag(1)
                    
                    detailsTab
                        .tabItem {
                            Image(systemName: "info.circle.fill")
                            Text("Details")
                        }
                        .tag(2)
                }
            }
            .navigationTitle("Form Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(result.exerciseType.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(formatDate(result.analysisDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ScoreCircle(score: result.overallScore)
            }
            .padding(.horizontal)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                scoreSummarySection
                strengthsSection
                issuesSection
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private var feedbackTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                mainFeedbackSection
                correctionsSection
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private var detailsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                videoDetailsSection
                poseQualitySection
                technicalDetailsSection
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private var scoreSummarySection: some View {
        VStack(spacing: 16) {
            Text("Form Score Breakdown")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(Array(result.formAnalysis.detailedScores.keys.sorted()), id: \.self) { key in
                    if let score = result.formAnalysis.detailedScores[key] {
                        ScoreRow(title: formatScoreTitle(key), score: score)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var strengthsSection: some View {
        VStack(spacing: 12) {
            Text("What You Did Well")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if result.formAnalysis.strengths.isEmpty {
                Text("Keep practicing to build your strengths!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(result.formAnalysis.strengths.enumerated()), id: \.offset) { index, strength in
                        StrengthRow(strength: strength)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var issuesSection: some View {
        VStack(spacing: 12) {
            Text("Areas for Improvement")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if result.formAnalysis.identifiedIssues.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No major issues detected!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(result.formAnalysis.identifiedIssues.enumerated()), id: \.offset) { index, issue in
                        IssueRow(issue: issue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var mainFeedbackSection: some View {
        VStack(spacing: 12) {
            Text("AI Coach Feedback")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(result.feedback.mainFeedback)
                .font(.body)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var correctionsSection: some View {
        VStack(spacing: 12) {
            Text("Specific Corrections")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if result.feedback.specificCorrections.isEmpty {
                Text("No specific corrections needed at this time.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(result.feedback.specificCorrections.enumerated()), id: \.offset) { index, correction in
                        CorrectionCard(correction: correction, index: index + 1)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var videoDetailsSection: some View {
        VStack(spacing: 12) {
            Text("Video Quality")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                DetailRow(title: "Resolution", value: result.videoQuality.resolutionString)
                DetailRow(title: "Frame Rate", value: "\(String(format: "%.1f", result.videoQuality.frameRate)) fps")
                DetailRow(title: "Duration", value: formatDuration(result.videoQuality.duration))
                DetailRow(title: "Quality", value: result.videoQuality.isHighQuality ? "High" : "Standard")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var poseQualitySection: some View {
        VStack(spacing: 12) {
            Text("Pose Detection Quality")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                DetailRow(title: "Average Confidence", value: "\(Int(result.poseQuality.averageConfidence * 100))%")
                DetailRow(title: "Completeness", value: "\(Int(result.poseQuality.completenessScore * 100))%")
                DetailRow(title: "Consistency", value: "\(Int(result.poseQuality.consistencyScore * 100))%")
                DetailRow(title: "Overall Quality", value: result.poseQuality.qualityLevel)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var technicalDetailsSection: some View {
        VStack(spacing: 12) {
            Text("Technical Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                DetailRow(title: "Reps Detected", value: "\(result.formAnalysis.repCount)")
                DetailRow(title: "User Level", value: result.feedback.userLevel.description)
                DetailRow(title: "Analysis ID", value: String(result.id.uuidString.prefix(8)))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatScoreTitle(_ key: String) -> String {
        switch key {
        case "kneeTracking": return "Knee Tracking"
        case "depth": return "Squat Depth"
        case "spinalAlignment": return "Spinal Alignment"
        case "tempo": return "Movement Tempo"
        case "barPath": return "Bar Path"
        case "hipHinge": return "Hip Hinge"
        case "shoulderStability": return "Shoulder Stability"
        default: return key.capitalized
        }
    }
}

struct ScoreCircle: View {
    let score: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 6)
                .opacity(0.3)
                .foregroundColor(scoreColor)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(score, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .foregroundColor(scoreColor)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: score)
            
            VStack {
                Text("\(Int(score * 100))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
                
                Text("SCORE")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80, height: 80)
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct ScoreRow: View {
    let title: String
    let score: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 8) {
                ProgressView(value: score)
                    .progressViewStyle(LinearProgressViewStyle(tint: scoreColor))
                    .frame(width: 60)
                
                Text("\(Int(score * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(scoreColor)
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct StrengthRow: View {
    let strength: FormStrength
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(strength.description)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct IssueRow: View {
    let issue: FormIssue
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
                .frame(width: 20)
            
            Text(issue.description)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var severityIcon: String {
        switch issue.severity {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "info.circle.fill"
        }
    }
    
    private var severityColor: Color {
        switch issue.severity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct CorrectionCard: View {
    let correction: FormCorrection
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(priorityColor)
                .clipShape(Circle())
            
            Text(correction.instruction)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch correction.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Extensions
extension UserFitnessLevel {
    var description: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

#Preview {
    FormAnalysisResultView(
        result: VideoFormAnalysisResult(
            id: UUID(),
            session: VideoSession(
                id: UUID(),
                exerciseType: .squat,
                recordingURL: URL(string: "file://test")!,
                startTime: Date()
            ),
            formAnalysis: FormAnalysisResult(
                exerciseType: .squat,
                overallScore: 0.75,
                identifiedIssues: [
                    FormIssue(
                        type: .kneeValgus,
                        severity: .medium,
                        description: "Knees are caving inward slightly",
                        affectedFrames: []
                    )
                ],
                strengths: [
                    FormStrength(
                        type: .spinalAlignment,
                        description: "Excellent spinal alignment throughout the movement"
                    )
                ],
                detailedScores: [
                    "kneeTracking": 0.6,
                    "spinalAlignment": 0.9,
                    "depth": 0.8
                ],
                repCount: 8,
                analysisDate: Date()
            ),
            feedback: FormFeedback(
                overallScore: 0.75,
                mainFeedback: "Good form overall with room for improvement in knee tracking.",
                specificCorrections: [
                    FormCorrection(
                        issue: .kneeValgus,
                        instruction: "Focus on pushing your knees out",
                        priority: .medium
                    )
                ],
                strengths: [],
                exerciseType: .squat,
                userLevel: .beginner,
                priority: .medium
            ),
            poseQuality: PoseQualityMetrics(
                averageConfidence: 0.85,
                completenessScore: 0.9,
                consistencyScore: 0.8,
                overallScore: 0.85
            ),
            videoQuality: VideoQualityMetrics(
                resolution: CGSize(width: 1920, height: 1080),
                frameRate: 30,
                duration: 25,
                qualityScore: 0.9,
                isHighQuality: true
            ),
            analysisDate: Date()
        )
    )
}
