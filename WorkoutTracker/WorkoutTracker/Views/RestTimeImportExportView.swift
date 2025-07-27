import SwiftUI

struct RestTimeImportExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var restTimeResolver = RestTimeResolver.shared
    @EnvironmentObject private var hapticService: HapticService
    
    @State private var exportData: String = ""
    @State private var importData: String = ""
    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    @State private var showingImportError = false
    @State private var isExporting = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Segmented control for Import/Export
                Picker("Mode", selection: $isExporting) {
                    Text("Export").tag(true)
                    Text("Import").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if isExporting {
                    // Export view
                    exportView
                } else {
                    // Import view
                    importView
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Rest Time Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isExporting {
                        Button("Copy") {
                            UIPasteboard.general.string = exportData
                            hapticService.provideFeedback(for: .success)
                            showingExportSuccess = true
                        }
                        .disabled(exportData.isEmpty)
                    } else {
                        Button("Import") {
                            importRestTimeData()
                        }
                        .disabled(importData.isEmpty)
                    }
                }
            }
            .alert("Copied to clipboard", isPresented: $showingExportSuccess) {
                Button("OK", role: .cancel) {}
            }
            .alert("Import successful", isPresented: $showingImportSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            }
            .alert("Import failed", isPresented: $showingImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The data format is invalid. Please make sure you're pasting valid rest time settings data.")
            }
            .onAppear {
                if isExporting {
                    generateExportData()
                }
            }
        }
    }
    
    // MARK: - Export View
    
    private var exportView: some View {
        VStack(spacing: 16) {
            Text("Export Rest Time Settings")
                .font(.headline)
            
            Text("Copy the data below to back up your rest time settings. You can import this data later to restore your settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            ScrollView {
                Text(exportData)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 300)
            
            Button("Copy to Clipboard") {
                UIPasteboard.general.string = exportData
                hapticService.provideFeedback(for: .success)
                showingExportSuccess = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
    
    // MARK: - Import View
    
    private var importView: some View {
        VStack(spacing: 16) {
            Text("Import Rest Time Settings")
                .font(.headline)
            
            Text("Paste the rest time settings data below to restore your settings. This will override any existing settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextEditor(text: $importData)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .frame(maxHeight: 300)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            
            Button("Import Data") {
                importRestTimeData()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(importData.isEmpty)
        }
    }
    
    // MARK: - Data Methods
    
    private func generateExportData() {
        let settings = restTimeResolver.exportRestTimeSettings()
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            exportData = jsonString
        } else {
            exportData = "Error generating export data"
        }
    }
    
    private func importRestTimeData() {
        guard !importData.isEmpty else { return }
        
        if let jsonData = importData.data(using: .utf8),
           let settings = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            
            let success = restTimeResolver.importRestTimeSettings(from: settings)
            
            if success {
                hapticService.provideFeedback(for: .success)
                showingImportSuccess = true
            } else {
                hapticService.provideFeedback(for: .error)
                showingImportError = true
            }
        } else {
            hapticService.provideFeedback(for: .error)
            showingImportError = true
        }
    }
}

// MARK: - Button Style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct RestTimeImportExportView_Previews: PreviewProvider {
    static var previews: some View {
        RestTimeImportExportView()
            .environmentObject(HapticService.shared)
    }
}
