import SwiftUI

/// A picker component for selecting rest times with preset options
struct RestTimePickerView: View {
    @Binding var restTime: Int?
    @Environment(\.dismiss) private var dismiss
    
    // Preset rest time options in seconds
    private let presetOptions: [(label: String, seconds: Int?)] = [
        ("Default", nil),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("1.5 minutes", 90),
        ("2 minutes", 120),
        ("3 minutes", 180),
        ("5 minutes", 300)
    ]
    
    @State private var selectedRestTime: Int?
    @State private var customTime: Int = 60
    @State private var showingCustomPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Set Rest Time")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose how long to rest after completing this set")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Preset options
                List {
                    Section("Quick Options") {
                        ForEach(presetOptions, id: \.seconds) { option in
                            RestTimeOptionRow(
                                label: option.label,
                                seconds: option.seconds,
                                isSelected: selectedRestTime == option.seconds
                            ) {
                                selectedRestTime = option.seconds
                                HapticService.shared.provideFeedback(for: .selection)
                            }
                        }
                    }
                    
                    Section("Custom Time") {
                        Button(action: {
                            showingCustomPicker = true
                        }) {
                            HStack {
                                Image(systemName: "clock.badge.plus")
                                    .foregroundColor(.blue)
                                
                                Text("Custom Time")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if let customSeconds = selectedRestTime,
                                   !presetOptions.contains(where: { $0.seconds == customSeconds }) {
                                    Text(formatTime(customSeconds))
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        restTime = selectedRestTime
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCustomPicker) {
                CustomRestTimePickerView(
                    customTime: $customTime,
                    onSave: { time in
                        selectedRestTime = time
                        showingCustomPicker = false
                    }
                )
            }
        }
        .onAppear {
            selectedRestTime = restTime
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds % 60 == 0 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds / 60)m \(seconds % 60)s"
        }
    }
}

// MARK: - Rest Time Option Row
struct RestTimeOptionRow: View {
    let label: String
    let seconds: Int?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let seconds = seconds {
                        Text(formatTime(seconds))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Uses exercise or global default")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else if seconds % 60 == 0 {
            return "\(seconds / 60) minute\(seconds == 60 ? "" : "s")"
        } else {
            return "\(seconds / 60)m \(seconds % 60)s"
        }
    }
}

// MARK: - Custom Rest Time Picker
struct CustomRestTimePickerView: View {
    @Binding var customTime: Int
    let onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var minutes: Int = 1
    @State private var seconds: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Custom Rest Time")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Time picker
                HStack(spacing: 20) {
                    // Minutes picker
                    VStack {
                        Text("Minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0...10, id: \.self) { minute in
                                Text("\(minute)")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)
                    }
                    
                    Text(":")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Seconds picker
                    VStack {
                        Text("Seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Seconds", selection: $seconds) {
                            ForEach(Array(stride(from: 0, to: 60, by: 15)), id: \.self) { second in
                                Text("\(second)")
                                    .tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)
                    }
                }
                
                // Preview
                VStack(spacing: 8) {
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatTotalTime())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let totalSeconds = minutes * 60 + seconds
                        onSave(totalSeconds)
                    }
                    .fontWeight(.semibold)
                    .disabled(minutes == 0 && seconds == 0)
                }
            }
        }
        .onAppear {
            minutes = customTime / 60
            seconds = customTime % 60
        }
    }
    
    private func formatTotalTime() -> String {
        let totalSeconds = minutes * 60 + seconds
        
        if totalSeconds == 0 {
            return "No rest time"
        } else if totalSeconds < 60 {
            return "\(totalSeconds) seconds"
        } else if totalSeconds % 60 == 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "\(minutes)m \(seconds)s"
        }
    }
}

// MARK: - Preview
struct RestTimePickerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RestTimePickerView(restTime: .constant(nil))
                .previewDisplayName("Default Selection")
            
            RestTimePickerView(restTime: .constant(90))
                .previewDisplayName("90 Seconds Selected")
            
            CustomRestTimePickerView(customTime: .constant(120)) { _ in }
                .previewDisplayName("Custom Picker")
        }
    }
}