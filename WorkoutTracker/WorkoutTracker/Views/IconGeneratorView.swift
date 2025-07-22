import SwiftUI

struct IconGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var generatedIcons: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("App Icon Generator")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Generate app icons for all required sizes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Generate Button
                Button(action: generateIcons) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "wand.and.rays")
                        }
                        Text(isGenerating ? "Generating..." : "Generate Icons")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                .disabled(isGenerating)
                .padding(.horizontal)
                
                // Generated Icons List
                if !generatedIcons.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Generated Icons:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(generatedIcons, id: \.self) { iconName in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(iconName)
                                            .font(.caption)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon Sizes Generated:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("• 20x20, 29x29, 40x40, 60x60, 76x76, 83.5x83.5, 1024x1024")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationTitle("Icon Generator")
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
    
    private func generateIcons() {
        isGenerating = true
        generatedIcons = []
        
        // Simulate icon generation process
        let iconSizes = [
            "AppIcon-20x20@1x.png",
            "AppIcon-20x20@2x.png", 
            "AppIcon-20x20@3x.png",
            "AppIcon-29x29@1x.png",
            "AppIcon-29x29@2x.png",
            "AppIcon-29x29@3x.png",
            "AppIcon-40x40@1x.png",
            "AppIcon-40x40@2x.png",
            "AppIcon-40x40@3x.png",
            "AppIcon-60x60@2x.png",
            "AppIcon-60x60@3x.png",
            "AppIcon-76x76@1x.png",
            "AppIcon-76x76@2x.png",
            "AppIcon-83.5x83.5@2x.png",
            "AppIcon-1024x1024@1x.png"
        ]
        
        DispatchQueue.global(qos: .background).async {
            for (index, iconName) in iconSizes.enumerated() {
                // Simulate processing time
                Thread.sleep(forTimeInterval: 0.1)
                
                DispatchQueue.main.async {
                    generatedIcons.append(iconName)
                    
                    if index == iconSizes.count - 1 {
                        isGenerating = false
                    }
                }
            }
        }
    }
}

#Preview {
    IconGeneratorView()
}