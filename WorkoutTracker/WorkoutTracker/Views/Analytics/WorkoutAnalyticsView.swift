import SwiftUI
import Charts

struct WorkoutAnalyticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: false)],
        animation: .default
    ) private var workoutSessions: FetchedResults<WorkoutSession>
    
    @State private var selectedTimeframe: AnalyticsTimeframe = .month
    @State private var selectedMetric: AnalyticsMetric = .volume
    
    private var filteredWorkouts: [WorkoutSession] {
        let cutoffDate = Calendar.current.date(
            byAdding: selectedTimeframe.dateComponent,
            value: -selectedTimeframe.value,
            to: Date()
        ) ?? Date()
        
        return workoutSessions.filter { workout in
            guard let date = workout.date else { return false }
            return date >= cutoffDate
        }
    }
    
    private var totalVolume: Double {
        filteredWorkouts.reduce(0) { total, workout in
            guard let exercises = workout.exercises?.allObjects as? [WorkoutExercise] else { return total }
            return total + exercises.reduce(0) { $0 + $1.exerciseVolume }
        }
    }
    
    private var averageWorkoutDuration: Double {
        guard !filteredWorkouts.isEmpty else { return 0 }
        let totalDuration = filteredWorkouts.reduce(0) { $0 + Double($1.duration) }
        return totalDuration / Double(filteredWorkouts.count)
    }
    
    private var workoutFrequency: Double {
        let days = Double(selectedTimeframe.value * selectedTimeframe.daysMultiplier)
        return Double(filteredWorkouts.count) / days * 7 // Per week
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Period Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Analytics Period")
                            .font(.headline)
                            .bold()
                        
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                                Text(timeframe.displayName).tag(timeframe)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    // Summary Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        AnalyticsCard(
                            title: "Total Volume",
                            value: String(format: "%.0f lbs", totalVolume),
                            subtitle: "Combined weight × reps",
                            icon: "scalemass.fill",
                            color: .purple
                        )
                        
                        AnalyticsCard(
                            title: "Workouts",
                            value: "\(filteredWorkouts.count)",
                            subtitle: selectedTimeframe.displayName,
                            icon: "dumbbell.fill",
                            color: .blue
                        )
                        
                        AnalyticsCard(
                            title: "Frequency",
                            value: String(format: "%.1f/week", workoutFrequency),
                            subtitle: "Average per week",
                            icon: "calendar",
                            color: .green
                        )
                        
                        AnalyticsCard(
                            title: "Avg Duration",
                            value: formatDuration(Int(averageWorkoutDuration)),
                            subtitle: "Per workout",
                            icon: "clock.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Charts Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Trends")
                                .font(.headline)
                                .bold()
                            
                            Spacer()
                            
                            Picker("Metric", selection: $selectedMetric) {
                                ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                                    Text(metric.displayName).tag(metric)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        if #available(iOS 16.0, *) {
                            MetricChart(
                                workouts: filteredWorkouts,
                                metric: selectedMetric
                            )
                        } else {
                            // Fallback chart for iOS 15
                            LegacyMetricChart(
                                workouts: filteredWorkouts,
                                metric: selectedMetric
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Muscle Group Distribution
                    MuscleGroupDistribution(workouts: filteredWorkouts)
                    
                    // Top Exercises
                    TopExercisesSection(workouts: filteredWorkouts)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Workout Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .bold()
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

@available(iOS 16.0, *)
struct MetricChart: View {
    let workouts: [WorkoutSession]
    let metric: AnalyticsMetric
    
    private var chartData: [ChartDataPoint] {
        let sortedWorkouts = workouts.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
        
        return sortedWorkouts.enumerated().compactMap { index, workout in
            guard let date = workout.date else { return nil }
            
            let value: Double
            switch metric {
            case .volume:
                guard let exercises = workout.exercises?.allObjects as? [WorkoutExercise] else { return nil }
                value = exercises.reduce(0) { $0 + $1.exerciseVolume }
            case .duration:
                value = Double(workout.duration)
            case .exerciseCount:
                value = Double(workout.exercises?.count ?? 0)
            }
            
            return ChartDataPoint(date: date, value: value, workoutIndex: index + 1)
        }
    }
    
    var body: some View {
        Chart(chartData) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value(metric.displayName, point.value)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            PointMark(
                x: .value("Date", point.date),
                y: .value(metric.displayName, point.value)
            )
            .foregroundStyle(.blue)
        }
        .frame(height: 200)
        .chartYAxisLabel(metric.unit)
        .chartXAxisLabel("Date")
    }
}

struct LegacyMetricChart: View {
    let workouts: [WorkoutSession]
    let metric: AnalyticsMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent \(metric.displayName)")
                .font(.subheadline)
                .bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(workouts.prefix(10).indices, id: \.self) { index in
                        let workout = workouts[index]
                        LegacyChartBar(workout: workout, metric: metric)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct LegacyChartBar: View {
    let workout: WorkoutSession
    let metric: AnalyticsMetric
    
    private var value: Double {
        switch metric {
        case .volume:
            guard let exercises = workout.exercises?.allObjects as? [WorkoutExercise] else { return 0 }
            return exercises.reduce(0) { $0 + $1.exerciseVolume }
        case .duration:
            return Double(workout.duration)
        case .exerciseCount:
            return Double(workout.exercises?.count ?? 0)
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(.blue)
                .frame(width: 20, height: max(4, value / 100))
                .cornerRadius(2)
            
            Text(workout.date ?? Date(), format: .dateTime.month().day())
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

struct MuscleGroupDistribution: View {
    let workouts: [WorkoutSession]
    
    private var muscleGroupData: [MuscleGroupData] {
        var counts: [String: Int] = [:]
        
        for workout in workouts {
            guard let exercises = workout.exercises?.allObjects as? [WorkoutExercise] else { continue }
            
            for exercise in exercises {
                let muscleGroup = exercise.exercise?.primaryMuscleGroup ?? "Unknown"
                counts[muscleGroup, default: 0] += 1
            }
        }
        
        return counts.map { MuscleGroupData(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muscle Group Focus")
                .font(.headline)
                .bold()
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(muscleGroupData.prefix(5), id: \.name) { data in
                    MuscleGroupRow(data: data, total: muscleGroupData.reduce(0) { $0 + $1.count })
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MuscleGroupRow: View {
    let data: MuscleGroupData
    let total: Int
    
    private var percentage: Double {
        return total > 0 ? Double(data.count) / Double(total) : 0
    }
    
    var body: some View {
        HStack {
            Text(data.name)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(data.count) exercises")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("(\(Int(percentage * 100))%)")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct TopExercisesSection: View {
    let workouts: [WorkoutSession]
    
    private var topExercises: [ExerciseFrequency] {
        var exerciseCounts: [String: Int] = [:]
        
        for workout in workouts {
            guard let exercises = workout.exercises?.allObjects as? [WorkoutExercise] else { continue }
            
            for exercise in exercises {
                let name = exercise.exercise?.name ?? "Unknown"
                exerciseCounts[name, default: 0] += 1
            }
        }
        
        return exerciseCounts.map { ExerciseFrequency(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Performed Exercises")
                .font(.headline)
                .bold()
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(topExercises.prefix(5), id: \.name) { exercise in
                    HStack {
                        Text(exercise.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(exercise.count)x")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Types

enum AnalyticsTimeframe: CaseIterable {
    case week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .quarter: return "3 Months"
        case .year: return "This Year"
        }
    }
    
    var value: Int {
        switch self {
        case .week: return 1
        case .month: return 1
        case .quarter: return 3
        case .year: return 1
        }
    }
    
    var dateComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        case .quarter: return .month
        case .year: return .year
        }
    }
    
    var daysMultiplier: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
}

enum AnalyticsMetric: CaseIterable {
    case volume, duration, exerciseCount
    
    var displayName: String {
        switch self {
        case .volume: return "Volume"
        case .duration: return "Duration"
        case .exerciseCount: return "Exercises"
        }
    }
    
    var unit: String {
        switch self {
        case .volume: return "lbs"
        case .duration: return "minutes"
        case .exerciseCount: return "count"
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let workoutIndex: Int
}

struct MuscleGroupData {
    let name: String
    let count: Int
}

struct ExerciseFrequency {
    let name: String
    let count: Int
}

#Preview {
    WorkoutAnalyticsView()
}