import SwiftUI
import CloudKit
import Combine

struct CloudSyncView: View {
    @StateObject private var cloudService = CloudKitService.shared
    @StateObject private var syncManager = CloudSyncManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPermissionAlert = false
    @State private var showingMigrationAlert = false
    @State private var migrationInProgress = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Account Status Section
                    accountStatusSection
                    
                    // Sync Status Section
                    syncStatusSection
                    
                    // Sync Actions Section
                    if cloudService.isAvailable {
                        syncActionsSection
                    }
                    
                    // Migration Section
                    migrationSection
                    
                    // Information Section
                    informationSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("iCloud Sync")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("iCloud Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    openSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("To sync your workout data across devices, please enable iCloud for this app in Settings.")
            }
            .alert("Migrate to iCloud", isPresented: $showingMigrationAlert) {
                Button("Migrate") {
                    performMigration()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will upload all your local workout data to iCloud. Your data will be synced across all your devices. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.and.arrow.up.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("iCloud Sync")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Keep your workout data synchronized across all your Apple devices")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Account Status Section
    
    private var accountStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("iCloud Account")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                Image(systemName: accountStatusIcon)
                    .foregroundColor(accountStatusColor)
                    .font(.title2)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(accountStatusTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(accountStatusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if cloudService.accountStatus != .available {
                    Button("Fix") {
                        handleAccountIssue()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Sync Status Section
    
    private var syncStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sync Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Current sync status
                HStack(spacing: 16) {
                    Image(systemName: syncStatusIcon)
                        .foregroundColor(syncStatusColor)
                        .font(.title3)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(syncStatusTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(syncStatusDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if syncManager.syncInProgress {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                // Last sync date
                if let lastSync = cloudService.lastSyncDate {
                    HStack {
                        Text("Last sync:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(lastSync, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                // Sync errors
                if let error = syncManager.lastSyncError {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Sync Actions Section
    
    private var syncActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sync Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Manual sync button
                Button(action: {
                    Task {
                        await syncManager.performManualSync()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        
                        Text("Sync Now")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if syncManager.syncInProgress {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(syncManager.syncInProgress)
                
                // Enable automatic sync
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Automatic Sync")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Sync changes automatically when they occur")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                        .disabled(true) // TODO: Implement automatic sync toggle
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Migration Section
    
    private var migrationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Migration")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "arrow.up.to.line.compact")
                        .foregroundColor(.green)
                        .font(.title3)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upload Local Data")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Upload all your existing workout data to iCloud for the first time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if migrationInProgress {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Migrate") {
                            showingMigrationAlert = true
                        }
                        .buttonStyle(.bordered)
                        .disabled(!cloudService.isAvailable)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Information Section
    
    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About iCloud Sync")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "shield.fill",
                    title: "Private & Secure",
                    description: "Your data is encrypted and stored securely in your personal iCloud account"
                )
                
                InfoRow(
                    icon: "devices",
                    title: "All Your Devices",
                    description: "Access your workouts on iPhone, iPad, and other Apple devices"
                )
                
                InfoRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Real-time Sync",
                    description: "Changes sync automatically across all your devices"
                )
                
                InfoRow(
                    icon: "internaldrive.fill",
                    title: "Local Backup",
                    description: "Your data is always available locally, even without internet"
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    
    private var accountStatusIcon: String {
        switch cloudService.accountStatus {
        case .available:
            return "checkmark.circle.fill"
        case .noAccount:
            return "person.badge.plus"
        case .restricted:
            return "lock.fill"
        case .couldNotDetermine:
            return "questionmark.circle.fill"
        case .temporarilyUnavailable:
            return "exclamationmark.triangle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }
    
    private var accountStatusColor: Color {
        switch cloudService.accountStatus {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .red
        case .couldNotDetermine, .temporarilyUnavailable:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var accountStatusTitle: String {
        switch cloudService.accountStatus {
        case .available:
            return "iCloud Available"
        case .noAccount:
            return "No iCloud Account"
        case .restricted:
            return "iCloud Restricted"
        case .couldNotDetermine:
            return "Checking iCloud..."
        case .temporarilyUnavailable:
            return "iCloud Unavailable"
        @unknown default:
            return "Unknown Status"
        }
    }
    
    private var accountStatusDescription: String {
        switch cloudService.accountStatus {
        case .available:
            return "Ready to sync your workout data"
        case .noAccount:
            return "Sign in to iCloud in Settings to enable sync"
        case .restricted:
            return "iCloud access is restricted on this device"
        case .couldNotDetermine:
            return "Checking your iCloud account status"
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable"
        @unknown default:
            return "Unable to determine iCloud status"
        }
    }
    
    private var syncStatusIcon: String {
        switch cloudService.syncStatus {
        case .idle:
            return "checkmark.circle.fill"
        case .syncing:
            return "arrow.clockwise"
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var syncStatusColor: Color {
        switch cloudService.syncStatus {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .success:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var syncStatusTitle: String {
        switch cloudService.syncStatus {
        case .idle:
            return "Ready to Sync"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Sync Successful"
        case .failed:
            return "Sync Failed"
        }
    }
    
    private var syncStatusDescription: String {
        switch cloudService.syncStatus {
        case .idle:
            return "Your data is up to date"
        case .syncing:
            return "Syncing your workout data with iCloud"
        case .success:
            return "All your data is synced with iCloud"
        case .failed(let error):
            return cloudService.handleCloudKitError(error)
        }
    }
    
    // MARK: - Actions
    
    private func handleAccountIssue() {
        switch cloudService.accountStatus {
        case .noAccount, .restricted:
            showingPermissionAlert = true
        case .couldNotDetermine, .temporarilyUnavailable:
            cloudService.checkAccountStatus()
        default:
            break
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func performMigration() {
        migrationInProgress = true
        
        Task {
            // Mark all existing data for cloud sync
            CoreDataManager.shared.markAllForCloudSync()
            
            // Perform initial sync
            await syncManager.performManualSync()
            
            DispatchQueue.main.async {
                migrationInProgress = false
            }
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    CloudSyncView()
}