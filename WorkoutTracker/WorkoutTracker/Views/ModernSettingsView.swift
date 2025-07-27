import SwiftUI
import CoreData
import UIKit

struct ModernSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Settings storage
    @AppStorage("defaultRestTime") private var defaultRestTime: Int = 60
    @AppStorage("enableHapticFeedback") private var enableHapticFeedback: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("autoStartRestTimer") private var autoStartRestTimer: Bool = false
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @AppStorage("enableProgressiveOverload") private var enableProgressiveOverload: Bool = true
    @AppStorage("progressiveOverloadIncrement") private var progressiveOverloadIncrement: Double = 2.5
    @AppStorage("enableVolumeWarnings") private var enableVolumeWarnings: Bool = true
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @AppStorage("enableSetReminders") private var enableSetReminders: Bool = true
    @AppStorage("reminderInterval") private var reminderInterval: Int = 5
    @AppStorage("enableAIInsights") private var enableAIInsights: Bool = true
    @AppStorage("enableFormAnalysis") private var enableFormAnalysis: Bool = false
    @AppStorage("dataRetentionDays") private var dataRetentionDays: Int = 365
    
    // State variables
    @State private var showingDataManagement = false
    @State private var showingAbout = false
    @State private var showingResetAlert = false
    @State private var showingSubscriptionInfo = false
    @State private var showingCloudSync = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Workout Settings
                    workoutSettingsSection
                    
                    // AI & Smart Features
                    aiSettingsSection
                    
                    // Notifications & Feedback
                    notificationsSection
                    
                    // Appearance
                    appearanceSection
                    
                    // Cloud & Sync
                    cloudSyncSection
                    
                    // Data & Privacy
                    dataPrivacySection
                    
                    // About & Support
                    aboutSection
                    
                    // Developer Tools (Debug only)
                    #if DEBUG
                    developerSection
                    #endif
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showingDataManagement) {
                ModernDataManagementView()
            }
            .sheet(isPresented: $showingAbout) {
                ModernAboutView()
            }
            .sheet(isPresented: $showingSubscriptionInfo) {
                SubscriptionInfoView()
            }
            .sheet(isPresented: $showingCloudSync) {
                CloudSyncView()
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Customize Your Experience")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Adjust settings to match your workout style")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingSubscriptionInfo = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                        Text("Premium")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(16)
                }
            }
        }
        .padding(.top)
    }
    
    // MARK: - Workout Settings Section
    
    private var workoutSettingsSection: some View {
        SettingsSection(title: "Workout Settings", icon: "dumbbell.fill", color: .blue) {
            VStack(spacing: 16) {
                // Rest Timer Settings
                SettingsRow(
                    icon: "timer",
                    title: "Default Rest Time",
                    subtitle: "\(formatTime(defaultRestTime)) between sets",
                    color: .blue
                ) {
                    Stepper("", value: $defaultRestTime, in: 30...600, step: 15)
                        .labelsHidden()
                        .onChange(of: defaultRestTime) { _, _ in
                            HapticService.shared.provideFeedback(for: .selection)
                        }
                }
                
                SettingsToggle(
                    icon: "play.circle.fill",
                    title: "Auto-start Rest Timer",
                    subtitle: "Automatically start timer after completing a set",
                    isOn: $autoStartRestTimer,
                    color: .green
                )
                
                // Weight Unit
                SettingsRow(
                    icon: "scalemass.fill",
                    title: "Weight Unit",
                    subtitle: weightUnit == "lbs" ? "Pounds (lbs)" : "Kilograms (kg)",
                    color: .orange
                ) {
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("Pounds").tag("lbs")
                        Text("Kilograms").tag("kg")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                    .onChange(of: weightUnit) { _, _ in
                        HapticService.shared.provideFeedback(for: .selection)
                    }
                }
                
                // Progressive Overload
                SettingsToggle(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progressive Overload",
                    subtitle: "Smart weight progression suggestions",
                    isOn: $enableProgressiveOverload,
                    color: .purple
                )
                
                if enableProgressiveOverload {
                    SettingsRow(
                        icon: "plus.circle.fill",
                        title: "Weight Increment",
                        subtitle: "\(String(format: "%.1f", progressiveOverloadIncrement)) \(weightUnit) per progression",
                        color: .purple
                    ) {
                        Stepper("", value: $progressiveOverloadIncrement, in: 0.5...10.0, step: 0.5)
                            .labelsHidden()
                    }
                }
            }
        }
    }
    
    // MARK: - AI Settings Section
    
    private var aiSettingsSection: some View {
        SettingsSection(title: "AI & Smart Features", icon: "brain.head.profile", color: .indigo) {
            VStack(spacing: 16) {
                SettingsToggle(
                    icon: "brain.head.profile",
                    title: "AI Workout Insights",
                    subtitle: "Performance predictions and recommendations",
                    isOn: $enableAIInsights,
                    color: .indigo
                )
                
                SettingsToggle(
                    icon: "camera.fill",
                    title: "Form Analysis",
                    subtitle: "AI-powered exercise form feedback",
                    isOn: $enableFormAnalysis,
                    color: .green,
                    isPremium: true
                )
                
                SettingsToggle(
                    icon: "exclamationmark.triangle.fill",
                    title: "Volume Warnings",
                    subtitle: "Alerts when workout volume is unusually high",
                    isOn: $enableVolumeWarnings,
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications & Feedback", icon: "bell.fill", color: .red) {
            VStack(spacing: 16) {
                SettingsToggle(
                    icon: "bell.fill",
                    title: "Push Notifications",
                    subtitle: "Workout reminders and achievements",
                    isOn: $enableNotifications,
                    color: .red
                )
                
                SettingsToggle(
                    icon: "hand.tap.fill",
                    title: "Haptic Feedback",
                    subtitle: "Vibration feedback for interactions",
                    isOn: $enableHapticFeedback,
                    color: .blue
                )
                
                SettingsToggle(
                    icon: "clock.badge.exclamationmark.fill",
                    title: "Set Reminders",
                    subtitle: "Reminders to start your next set",
                    isOn: $enableSetReminders,
                    color: .orange
                )
                
                if enableSetReminders {
                    SettingsRow(
                        icon: "clock.fill",
                        title: "Reminder Interval",
                        subtitle: "Every \(reminderInterval) minute\(reminderInterval == 1 ? "" : "s")",
                        color: .orange
                    ) {
                        Stepper("", value: $reminderInterval, in: 1...30, step: 1)
                            .labelsHidden()
                    }
                }
            }
        }
    }
    
    // MARK: - Cloud & Sync Section
    
    private var cloudSyncSection: some View {
        SettingsSection(title: "Cloud & Sync", icon: "icloud.fill", color: .blue) {
            VStack(spacing: 16) {
                SettingsButton(
                    icon: "icloud.and.arrow.up.fill",
                    title: "iCloud Sync",
                    subtitle: "Sync your workout data across all devices",
                    color: .blue
                ) {
                    showingCloudSync = true
                }
                
                SettingsToggle(
                    icon: "wifi",
                    title: "Sync on Wi-Fi Only",
                    subtitle: "Only sync when connected to Wi-Fi to save data",
                    isOn: .constant(true),
                    color: .green
                )
                
                SettingsButton(
                    icon: "square.and.arrow.down.fill",
                    title: "Backup & Restore",
                    subtitle: "Create local backups of your workout data",
                    color: .orange
                ) {
                    // TODO: Implement backup functionality
                }
            }
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush.fill", color: .cyan) {
            VStack(spacing: 16) {
                SettingsRow(
                    icon: appearanceIcon,
                    title: "Theme",
                    subtitle: themeDescription,
                    color: .cyan
                ) {
                    Picker("Theme", selection: $preferredColorScheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 140)
                }
            }
        }
    }
    
    // MARK: - Data & Privacy Section
    
    private var dataPrivacySection: some View {
        SettingsSection(title: "Data & Privacy", icon: "lock.shield.fill", color: .green) {
            VStack(spacing: 16) {
                SettingsRow(
                    icon: "calendar.badge.clock",
                    title: "Data Retention",
                    subtitle: "Keep workout data for \(dataRetentionDays) days",
                    color: .blue
                ) {
                    Picker("Retention", selection: $dataRetentionDays) {
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                        Text("1 year").tag(365)
                        Text("Forever").tag(9999)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                SettingsButton(
                    icon: "square.and.arrow.up.fill",
                    title: "Export Data",
                    subtitle: "Download your workout history",
                    color: .blue
                ) {
                    showingDataManagement = true
                }
                
                SettingsButton(
                    icon: "trash.fill",
                    title: "Reset All Data",
                    subtitle: "Permanently delete all workout data",
                    color: .red,
                    isDestructive: true
                ) {
                    showingResetAlert = true
                }
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        SettingsSection(title: "About & Support", icon: "info.circle.fill", color: .gray) {
            VStack(spacing: 16) {
                SettingsButton(
                    icon: "info.circle.fill",
                    title: "About WorkoutTracker",
                    subtitle: "Version 1.0.0 • Learn more about the app",
                    color: .blue
                ) {
                    showingAbout = true
                }
                
                SettingsButton(
                    icon: "envelope.fill",
                    title: "Contact Support",
                    subtitle: "Get help with issues or questions",
                    color: .green
                ) {
                    // Contact support functionality
                    contactSupport()
                }
                
                SettingsButton(
                    icon: "star.fill",
                    title: "Rate WorkoutTracker",
                    subtitle: "Share your feedback on the App Store",
                    color: .yellow
                ) {
                    // Rate app functionality
                    rateApp()
                }
            }
        }
    }
    
    // MARK: - Developer Section
    
    #if DEBUG
    private var developerSection: some View {
        SettingsSection(title: "Developer Tools", icon: "hammer.fill", color: .purple) {
            VStack(spacing: 16) {
                SettingsButton(
                    icon: "doc.text.fill",
                    title: "Seed Test Data",
                    subtitle: "Add sample workouts for testing",
                    color: .orange
                ) {
                    seedTestData()
                }
            }
        }
    }
    #endif
    
    // MARK: - Helper Properties
    
    private var appearanceIcon: String {
        switch preferredColorScheme {
        case "light": return "sun.max.fill"
        case "dark": return "moon.fill"
        default: return "circle.lefthalf.striped.horizontal"
        }
    }
    
    private var themeDescription: String {
        switch preferredColorScheme {
        case "light": return "Always light mode"
        case "dark": return "Always dark mode"
        default: return "Follow system setting"
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes)m \(remainingSeconds)s"
            }
        }
    }
    
    private func resetAllData() {
        isLoading = true
        
        DispatchQueue.global(qos: .background).async {
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
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
            
            DispatchQueue.main.async {
                isLoading = false
                HapticService.shared.provideFeedback(for: .success)
                dismiss()
            }
        }
    }
    
    private func contactSupport() {
        if let url = URL(string: "mailto:support@workouttracker.app?subject=WorkoutTracker Support") {
            UIApplication.shared.open(url)
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    #if DEBUG
    private func seedTestData() {
        // Add sample data for testing
        DataSeedingService.shared.checkAndSeedDatabase()
        HapticService.shared.provideFeedback(for: .success)
    }
    #endif
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let content: Content
    
    init(icon: String, title: String, subtitle: String, color: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
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
            
            content
        }
    }
}

struct SettingsToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color
    let isPremium: Bool
    
    init(icon: String, title: String, subtitle: String, isOn: Binding<Bool>, color: Color, isPremium: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.color = color
        self.isPremium = isPremium
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if isPremium {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                    }
                }
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(isPremium) // Disable if premium feature
                .onChange(of: isOn) { _, _ in
                    HapticService.shared.provideFeedback(for: .selection)
                }
        }
    }
}

struct SettingsButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String, color: Color, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? .red : color)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

struct SubscriptionInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("WorkoutTracker Premium")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Unlock advanced AI features and insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "brain.head.profile", text: "Advanced AI workout insights")
                    FeatureRow(icon: "camera.fill", text: "Real-time form analysis")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Detailed progression analytics")
                    FeatureRow(icon: "cloud.fill", text: "Cloud sync & backup")
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                Spacer()
                
                Button("Learn More") {
                    // Navigate to subscription flow
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Premium")
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

// Note: FeatureRow is already defined in SettingsView.swift

#Preview {
    ModernSettingsView()
}