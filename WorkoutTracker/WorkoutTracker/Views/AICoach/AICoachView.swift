import SwiftUI
import AVFoundation
import PhotosUI
import Photos
import UniformTypeIdentifiers

struct AICoachView: View {
    @StateObject private var analysisService = AICoachVideoAnalysisService()
    @State private var selectedExerciseType: ExerciseType = .squat
    @State private var showingVideoPicker = false
    @State private var showingResults = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                
                if analysisService.isAnalyzing {
                    analysisProgressSection
                } else {
                    exerciseSelectionSection
                    actionButtonsSection
                }
                
                if let result = analysisService.lastAnalysisResult {
                    lastResultSection(result)
                }
                
                if let error = analysisService.lastError {
                    errorSection(error)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("AI Form Coach")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerView { url in
                Task {
                    do {
                        _ = try await analysisService.analyzeImportedVideo(url: url, exerciseType: selectedExerciseType)
                        showingResults = true
                    } catch {
                        print("Error analyzing imported video: \(error)")
                    }
                }
            }
        }
        .sheet(isPresented: $showingResults) {
            if let result = analysisService.lastAnalysisResult {
                FormAnalysisResultView(result: result)
            }
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("WorkoutTracker needs camera and photo library access to provide AI-powered form analysis. Please enable these permissions in Settings.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("AI Form Analysis")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Record or import a video to get instant feedback on your exercise form")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var exerciseSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Exercise")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExerciseType.allCases.filter { $0 != .unknown }, id: \.self) { exercise in
                        ExerciseTypeCard(
                            exerciseType: exercise,
                            isSelected: selectedExerciseType == exercise
                        ) {
                            selectedExerciseType = exercise
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if analysisService.isRecording {
                recordingSection
            } else {
                startRecordingButton
            }
            
            importVideoButton
        }
    }
    
    private var startRecordingButton: some View {
        Button(action: {
            Task {
                await checkCameraPermissionAndRecord()
            }
        }) {
            HStack {
                Image(systemName: "video.circle.fill")
                    .font(.title2)
                Text("Record \(selectedExerciseType.displayName)")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    private var recordingSection: some View {
        VStack(spacing: 16) {
            // Camera preview
            if let videoInputManager = analysisService.videoInputManager as? VideoInputManager,
               analysisService.isRecording {
                CameraPreviewView(previewLayer: videoInputManager.previewLayer)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        // Recording indicator overlay
                        VStack {
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                    .opacity(0.8)
                                
                                Text("RECORDING")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .shadow(color: .black, radius: 2)
                                
                                Spacer()
                            }
                            .padding()
                            
                            Spacer()
                            
                            Text(formatDuration(analysisService.recordingDuration))
                                .font(.system(size: 32, weight: .light, design: .monospaced))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2)
                                .padding()
                        }
                    )
            } else {
                // Fallback if preview not available
                VStack(spacing: 16) {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .opacity(0.8)
                        
                        Text("RECORDING")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    Text(formatDuration(analysisService.recordingDuration))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(.red)
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .cornerRadius(12)
            }
            
            Button(action: {
                Task {
                    do {
                        _ = try await analysisService.stopVideoRecordingAndAnalyze()
                        showingResults = true
                    } catch {
                        print("Error stopping video recording and analyzing: \(error)")
                    }
                }
            }) {
                HStack {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                    Text("Stop & Analyze")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var importVideoButton: some View {
        Button(action: {
            Task {
                await checkPhotoLibraryPermissionAndImport()
            }
        }) {
            HStack {
                Image(systemName: "folder.circle")
                    .font(.title2)
                Text("Import Video")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(12)
        }
    }
    
    private var analysisProgressSection: some View {
        VStack(spacing: 16) {
            Text("Analyzing Your Form...")
                .font(.headline)
            
            ProgressView(value: analysisService.analysisProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(y: 2.0)
            
            Text("\(Int(analysisService.analysisProgress * 100))% Complete")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func lastResultSection(_ result: VideoFormAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last Analysis")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(result.exerciseType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Score: \(Int(result.overallScore * 100))/100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("View Details") {
                    showingResults = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func errorSection(_ error: AICoachError) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func checkCameraPermissionAndRecord() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            await analysisService.startVideoRecording(exerciseType: selectedExerciseType)
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await analysisService.startVideoRecording(exerciseType: selectedExerciseType)
            } else {
                showingPermissionAlert = true
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        @unknown default:
            showingPermissionAlert = true
        }
    }
    
    private func checkPhotoLibraryPermissionAndImport() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            await MainActor.run {
                showingVideoPicker = true
            }
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if newStatus == .authorized || newStatus == .limited {
                await MainActor.run {
                    showingVideoPicker = true
                }
            } else {
                await MainActor.run {
                    showingPermissionAlert = true
                }
            }
        case .denied, .restricted:
            await MainActor.run {
                showingPermissionAlert = true
            }
        @unknown default:
            await MainActor.run {
                showingPermissionAlert = true
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ExerciseTypeCard: View {
    let exerciseType: ExerciseType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: exerciseIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(exerciseType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 100, height: 80)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var exerciseIcon: String {
        switch exerciseType {
        case .squat: return "figure.strengthtraining.traditional"
        case .deadlift: return "figure.strengthtraining.functional"
        case .benchPress: return "figure.strengthtraining.traditional"
        case .shoulderPress: return "figure.arms.open"
        case .pullUp: return "figure.strengthtraining.functional"
        case .unknown: return "questionmark"
        }
    }
}

struct VideoPickerView: UIViewControllerRepresentable {
    let onVideoSelected: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPickerView
        
        init(_ parent: VideoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let result = results.first else { return }
            
            // Check if the result can provide a video URL
            if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    if let error = error {
                        print("Error loading video: \(error)")
                        return
                    }
                    
                    guard let url = url else {
                        print("No URL provided for video")
                        return
                    }
                    
                    // Copy the file to a temporary location since the original will be cleaned up
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                    
                    do {
                        try FileManager.default.copyItem(at: url, to: tempURL)
                        DispatchQueue.main.async {
                            self.parent.onVideoSelected(tempURL)
                        }
                    } catch {
                        print("Error copying video file: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    AICoachView()
}
