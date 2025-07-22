import SwiftUI
import CoreData
import UIKit

struct ModernDataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingShareSheet = false
    @State private var exportedData: Data?
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var selectedExportFormat: ExportFormat = .json
    @State private var includePersonalData = true
    @State private var includeWorkoutTemplates = true
    @State private var includeAnalytics = false
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case pdf = "PDF"
        
        var icon: String {
            switch self {
            case .json: return "doc.text"
            case .csv: return "tablecells"
            case .pdf: return "doc.richtext"
            }
        }
        
        var description: String {
            switch self {
            case .json: return "Complete data export with full detail"
            case .csv: return "Spreadsheet format for data analysis"
            case .pdf: return "Formatted report for sharing"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Export Format Selection
                    exportFormatSection
                    
                    // Data Options
                    dataOptionsSection
                    
                    // Export Actions
                    exportActionsSection
                    
                    // Data Statistics
                    dataStatsSection
                    
                    // Import Section
                    importSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = exportedData {
                    ShareSheet(items: [data])
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.connected.to.line.below")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Export Your Workout Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Download your complete workout history, templates, and progress data in various formats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Export Format Section
    
    private var exportFormatSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Format")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(ExportFormat.allCases, id: \.rawValue) { format in
                    formatSelectionRow(format)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    private func formatSelectionRow(_ format: ExportFormat) -> some View {
        Button(action: {
            selectedExportFormat = format
            HapticService.shared.buttonTapped()
        }) {
            HStack(spacing: 16) {
                Image(systemName: format.icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(format.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: selectedExportFormat == format ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedExportFormat == format ? .blue : .secondary)
                    .font(.title3)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Data Options Section
    
    private var dataOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Include Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                ToggleRow(
                    icon: "person.fill",
                    title: "Personal Data",
                    subtitle: "Profile, preferences, and settings",
                    isOn: $includePersonalData
                )
                
                ToggleRow(
                    icon: "folder.fill",
                    title: "Workout Templates",
                    subtitle: "Custom templates and folder organization",
                    isOn: $includeWorkoutTemplates
                )
                
                ToggleRow(
                    icon: "chart.bar.fill",
                    title: "Analytics Data",
                    subtitle: "Performance metrics and insights",
                    isOn: $includeAnalytics
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Export Actions Section
    
    private var exportActionsSection: some View {
        VStack(spacing: 16) {
            if isExporting {
                VStack(spacing: 12) {
                    ProgressView("Exporting data...", value: exportProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("\(Int(exportProgress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            } else {
                Button(action: exportData) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                        
                        Text("Export Data")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isExporting)
            }
        }
    }
    
    // MARK: - Data Stats Section
    
    private var dataStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                DataStatCard(
                    title: "Workouts",
                    count: workoutCount,
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                DataStatCard(
                    title: "Exercises",
                    count: exerciseCount,
                    icon: "list.bullet",
                    color: .green
                )
                
                DataStatCard(
                    title: "Templates",
                    count: templateCount,
                    icon: "folder.fill",
                    color: .orange
                )
                
                DataStatCard(
                    title: "Total Sets",
                    count: totalSetsCount,
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Import Section
    
    private var importSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.green)
                        .font(.title3)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Import from File")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Restore data from a previous export")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Select File") {
                        // Import functionality
                        importData()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Computed Properties
    
    private var workoutCount: Int {
        let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    private var exerciseCount: Int {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    private var templateCount: Int {
        let request: NSFetchRequest<WorkoutTemplate> = WorkoutTemplate.fetchRequest()
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    private var totalSetsCount: Int {
        let request: NSFetchRequest<WorkoutExercise> = WorkoutExercise.fetchRequest()
        let workoutExercises = (try? viewContext.fetch(request)) ?? []
        return workoutExercises.reduce(0) { total, exercise in
            total + exercise.setData.count
        }
    }
    
    // MARK: - Functions
    
    private func exportData() {
        isExporting = true
        exportProgress = 0.0
        
        Task {
            do {
                // Simulate export progress
                for i in 1...10 {
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    await MainActor.run {
                        exportProgress = Double(i) / 10.0
                    }
                }
                
                // Generate export data based on format and options
                let data = try await generateExportData()
                
                await MainActor.run {
                    exportedData = data
                    isExporting = false
                    showingShareSheet = true
                    HapticService.shared.success()
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    print("Export failed: \(error)")
                }
            }
        }
    }
    
    private func generateExportData() async throws -> Data {
        // This would implement actual data export based on selectedExportFormat
        // For now, return sample data
        switch selectedExportFormat {
        case .json:
            return try await generateJSONExport()
        case .csv:
            return try await generateCSVExport()
        case .pdf:
            return try await generatePDFExport()
        }
    }
    
    private func generateJSONExport() async throws -> Data {
        let exportData: [String: Any] = [
            "export_date": ISO8601DateFormatter().string(from: Date()),
            "format": "json",
            "version": "1.0",
            "data": [
                "workouts": workoutCount,
                "exercises": exerciseCount,
                "templates": templateCount
            ]
        ]
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    private func generateCSVExport() async throws -> Data {
        let csvContent = """
        Date,Exercise,Sets,Reps,Weight,Volume
        2024-01-01,Bench Press,3,8,185,4440
        2024-01-01,Squats,3,10,225,6750
        """
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func generatePDFExport() async throws -> Data {
        // This would generate a PDF report
        // For now, return text data
        let pdfContent = "WorkoutTracker Export Report - \(Date())"
        return pdfContent.data(using: .utf8) ?? Data()
    }
    
    private func importData() {
        // This would implement data import functionality
        print("Import data functionality would be implemented here")
    }
}

// MARK: - Supporting Views

struct ToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct DataStatCard: View {
    let title: String
    let count: Int
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
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}


#Preview {
    ModernDataManagementView()
}