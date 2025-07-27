import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultRestTime") private var defaultRestTime: Int = 60
    @AppStorage("enableHapticFeedback") private var enableHapticFeedback: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("autoStartRestTimer") private var autoStartRestTimer: Bool = false
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @AppStorage("enableProgressiveOverload") private var enableProgressiveOverload: Bool = true
    @AppStorage("progressiveOverloadIncrement") private var progressiveOverloadIncrement: Double = 2.5
    @AppStorage("enableVolumeWarnings") private var enableVolumeWarnings: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    @AppStorage("enableSetReminders") private var enableSetReminders: Bool = true
    @AppStorage("reminderInterval") private var reminderInterval: Int = 5
    
    @State private var showingDataManagement = false
    @State private var showingExportData = false
    @State private var showingResetAlert = false
    @State private var showingAbout = false
    @State private var showingIconGenerator = false
    
    var body: some View {
        NavigationView {
            Form {
                // Workout Settings
                Section(header: Text("Workout Settings")) {
                    NavigationLink(destination: RestTimeSettingsView()) {
                        HStack {
                            Image(systemName: "timer.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Rest Time Settings")
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Default Rest Time")
                                .font(.subheadline)
                            Text("\(defaultRestTime) seconds")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Stepper("", value: $defaultRestTime, in: 30...300, step: 15)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Image(systemName: "play.circle")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        Toggle("Auto-start Rest Timer", isOn: $autoStartRestTimer)
                    }
                    
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Weight Unit")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Picker("Weight Unit", selection: $weightUnit) {
                            Text("Pounds (lbs)").tag("lbs")
                            Text("Kilograms (kg)").tag("kg")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // Progressive Overload Settings
                Section(header: Text("Progressive Overload")) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        Toggle("Enable Progressive Overload", isOn: $enableProgressiveOverload)
                    }
                    
                    if enableProgressiveOverload {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("Weight Increment")
                                    .font(.subheadline)
                                Text("\(progressiveOverloadIncrement, specifier: "%.1f") \(weightUnit)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Stepper("", value: $progressiveOverloadIncrement, in: 1.0...10.0, step: 0.5)
                                .labelsHidden()
                        }
                    }
                }
                
                // Notifications & Feedback
                Section(header: Text("Notifications & Feedback")) {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Toggle("Enable Notifications", isOn: $enableNotifications)
                    }
                    
                    HStack {
                        Image(systemName: "hand.tap")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Toggle("Haptic Feedback", isOn: $enableHapticFeedback)
                    }
                    
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        Toggle("Set Reminders", isOn: $enableSetReminders)
                    }
                    
                    if enableSetReminders {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("Reminder Interval")
                                    .font(.subheadline)
                                Text("Every \(reminderInterval) minutes")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Stepper("", value: $reminderInterval, in: 1...30, step: 1)
                                .labelsHidden()
                        }
                    }
                }
                
                // Analytics & Tracking
                Section(header: Text("Analytics & Tracking")) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.yellow)
                            .frame(width: 24)
                        
                        Toggle("Volume Warnings", isOn: $enableVolumeWarnings)
                    }
                }
                
                // Appearance
                Section(header: Text("Appearance")) {
                    HStack {
                        Image(systemName: "moon")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        
                        Toggle("Dark Mode", isOn: $darkModeEnabled)
                    }
                }
                
                // Data Management
                Section(header: Text("Data Management")) {
                    Button(action: {
                        showingDataManagement = true
                    }) {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Export Data")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("Reset All Data")
                                .foregroundColor(.red)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                
                // Developer Tools
                #if DEBUG
                Section(header: Text("Developer Tools")) {
                    Button(action: {
                        showingIconGenerator = true
                    }) {
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            Text("Generate App Icons")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                #endif
                
                // About
                Section(header: Text("About")) {
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("About WorkoutTracker")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Version")
                                .font(.subheadline)
                            Text("1.0.0")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDataManagement) {
                DataManagementView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingIconGenerator) {
                IconGeneratorView()
            }
            .alert("Reset All Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your workout data, templates, and settings. This action cannot be undone.")
            }
        }
    }
    
    private func resetAllData() {
        // Reset Core Data
        let entities = ["WorkoutSession", "WorkoutExercise", "Exercise", "WorkoutTemplate", "TemplateExercise", "Folder", "UserProfile"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try viewContext.execute(deleteRequest)
            } catch {
                print("Error deleting \(entityName): \(error)")
            }
        }
        
        // Reset UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "defaultRestTime")
        defaults.removeObject(forKey: "enableHapticFeedback")
        defaults.removeObject(forKey: "enableNotifications")
        defaults.removeObject(forKey: "autoStartRestTimer")
        defaults.removeObject(forKey: "weightUnit")
        defaults.removeObject(forKey: "enableProgressiveOverload")
        defaults.removeObject(forKey: "progressiveOverloadIncrement")
        defaults.removeObject(forKey: "enableVolumeWarnings")
        defaults.removeObject(forKey: "darkModeEnabled")
        defaults.removeObject(forKey: "enableSetReminders")
        defaults.removeObject(forKey: "reminderInterval")
        
        try? viewContext.save()
        HapticService.shared.provideFeedback(for: .success)
        
        dismiss()
    }
}

struct DataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var exportedData: Data?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Export Your Data")
                    .font(.title2)
                    .bold()
                
                Text("Export all your workout data, templates, and settings to a file that can be imported later or shared with other apps.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Button(action: exportData) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    Text("This will create a JSON file containing all your workout data.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Data Export")
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func exportData() {
        // This would implement actual data export functionality
        // For now, we'll just show the share sheet
        let sampleData = "Sample exported data".data(using: .utf8)!
        exportedData = sampleData
        showingShareSheet = true
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("WorkoutTracker")
                    .font(.title)
                    .bold()
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Features")
                        .font(.headline)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "dumbbell", text: "Track workouts with detailed set and rep logging")
                        FeatureRow(icon: "folder", text: "Organize workouts with templates and folders")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Progressive overload recommendations")
                        FeatureRow(icon: "timer", text: "Built-in rest timer with haptic feedback")
                        FeatureRow(icon: "chart.bar", text: "Comprehensive analytics and progress tracking")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}