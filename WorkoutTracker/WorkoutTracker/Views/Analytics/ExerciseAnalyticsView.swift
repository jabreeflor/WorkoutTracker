import SwiftUI
import Charts

struct ExerciseAnalyticsView: View {
    let exercise: Exercise
    @StateObject private var historyService = WorkoutHistoryService.shared
    @State private var selectedPeriod: ProgressPeriod = .month
    @State private var showingPersonalRecords = false
    
    private var exerciseHistory: [ExerciseHistoryEntry] {
        historyService.getExerciseHistory(for: exercise, limit: 10)
    }
    
    private var personalRecords: PersonalRecords {
        historyService.getPersonalRecords(for: exercise)
    }
    
    private var progressTrend: ProgressTrend {
        historyService.getProgressTrend(for: exercise, period: selectedPeriod)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name ?? "Exercise")
                        .font(.largeTitle)
                        .bold()
                    
                    HStack {
                        Text("Primary: \(exercise.primaryMuscleGroup ?? "Unknown")")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text("\(exerciseHistory.count) workouts tracked")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // Personal Records Section
                PersonalRecordsSection(records: personalRecords)
                
                // Progress Trend Section
                ProgressTrendSection(
                    trend: progressTrend,
                    selectedPeriod: $selectedPeriod
                )
                
                // Volume Chart
                if !exerciseHistory.isEmpty {
                    VolumeChartSection(history: exerciseHistory)
                }
                
                // Recent History
                RecentHistorySection(history: exerciseHistory)
                
                Spacer(minLength: 20)
            }
        }
        .navigationTitle("Exercise Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PersonalRecordsSection: View {
    let records: PersonalRecords
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)
                .bold()
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let maxWeight = records.maxWeight {
                    RecordCard(
                        title: "Max Weight",
                        value: String(format: "%.1f lbs", maxWeight.weight),
                        date: maxWeight.date,
                        icon: "scalemass.fill",
                        color: .red
                    )
                }
                
                if let maxVolume = records.maxVolume {
                    RecordCard(
                        title: "Max Volume",
                        value: String(format: "%.0f lbs", maxVolume.volume),
                        date: maxVolume.date,
                        icon: "chart.bar.fill",
                        color: .purple
                    )
                }
                
                if let maxReps = records.maxReps {
                    RecordCard(
                        title: "Max Reps",
                        value: "\(maxReps.reps)",
                        date: maxReps.date,
                        icon: "repeat",
                        color: .green
                    )
                }
                
                if let bestSet = records.bestSet {
                    RecordCard(
                        title: "Best Set",
                        value: String(format: "%d × %.1f", bestSet.actualReps, bestSet.actualWeight),
                        date: bestSet.timestamp,
                        icon: "star.fill",
                        color: .orange
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

struct RecordCard: View {
    let title: String
    let value: String
    let date: Date?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .bold()
                
                if let date = date {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProgressTrendSection: View {
    let trend: ProgressTrend
    @Binding var selectedPeriod: ProgressPeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress Trend")
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                Picker("Period", selection: $selectedPeriod) {
                    Text("Week").tag(ProgressPeriod.week)
                    Text("Month").tag(ProgressPeriod.month)
                    Text("Quarter").tag(ProgressPeriod.quarter)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            HStack(spacing: 16) {
                TrendMetric(
                    title: "Volume",
                    value: trend.volumeChangeFormatted,
                    isPositive: trend.volumeChange > 0,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                TrendMetric(
                    title: "Strength",
                    value: trend.strengthChangeFormatted,
                    isPositive: trend.strengthChange > 0,
                    icon: "bolt.fill"
                )
                
                TrendMetric(
                    title: "Consistency",
                    value: trend.consistencyFormatted,
                    isPositive: trend.consistency > 0.8,
                    icon: "target"
                )
            }
            
            Text("\(trend.workoutCount) workouts in \(selectedPeriod.displayName.lowercased())")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
}

struct TrendMetric: View {
    let title: String
    let value: String
    let isPositive: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(isPositive ? .green : .orange)
                .font(.title3)
            
            Text(value)
                .font(.headline)
                .bold()
                .foregroundColor(isPositive ? .green : .orange)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct VolumeChartSection: View {
    let history: [ExerciseHistoryEntry]
    
    private var chartData: [VolumeDataPoint] {
        return history.reversed().enumerated().map { index, entry in
            VolumeDataPoint(
                workout: index + 1,
                volume: entry.totalVolume,
                date: entry.date
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Volume Progression")
                .font(.headline)
                .bold()
                .padding(.horizontal)
            
            if #available(iOS 16.0, *) {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Workout", point.workout),
                        y: .value("Volume", point.volume)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Workout", point.workout),
                        y: .value("Volume", point.volume)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                // Fallback for iOS 15
                VStack(spacing: 8) {
                    ForEach(chartData.suffix(5), id: \.workout) { point in
                        HStack {
                            Text("Workout \(point.workout)")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.0f lbs", point.volume))
                                .font(.caption)
                                .bold()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RecentHistorySection: View {
    let history: [ExerciseHistoryEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
                .bold()
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(history.prefix(5).indices, id: \.self) { index in
                    let entry = history[index]
                    HistoryEntryRow(entry: entry)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct HistoryEntryRow: View {
    let entry: ExerciseHistoryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.workoutName)
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sets")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("\(entry.setData.count)")
                        .font(.caption)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("Volume")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f lbs", entry.totalVolume))
                        .font(.caption)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Max Weight")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f lbs", entry.maxWeight))
                        .font(.caption)
                        .bold()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct VolumeDataPoint: Identifiable {
    let id = UUID()
    let workout: Int
    let volume: Double
    let date: Date
}

#Preview {
    let exercise = Exercise()
    exercise.name = "Bench Press"
    exercise.primaryMuscleGroup = "Chest"
    
    return NavigationView {
        ExerciseAnalyticsView(exercise: exercise)
    }
}