import SwiftUI
import UIKit

/// Utility to export SwiftUI views as PNG files for app icons
struct IconExporter {
    
    /// Generate all required app icon sizes from our stick figure design and save to Downloads
    @MainActor
    static func generateAppIcons() -> String {
        let iconSizes: [(String, CGFloat)] = [
            ("AppIcon-20x20@1x.png", 20),
            ("AppIcon-20x20@2x.png", 40),
            ("AppIcon-20x20@3x.png", 60),
            ("AppIcon-29x29@1x.png", 29),
            ("AppIcon-29x29@2x.png", 58),
            ("AppIcon-29x29@3x.png", 87),
            ("AppIcon-40x40@1x.png", 40),
            ("AppIcon-40x40@2x.png", 80),
            ("AppIcon-40x40@3x.png", 120),
            ("AppIcon-60x60@2x.png", 120),
            ("AppIcon-60x60@3x.png", 180),
            ("AppIcon-76x76@1x.png", 76),
            ("AppIcon-76x76@2x.png", 152),
            ("AppIcon-83.5x83.5@2x.png", 167),
            ("AppIcon-1024x1024@1x.png", 1024)
        ]
        
        // Save to Downloads folder for easy access
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let appIconsPath = downloadsPath.appendingPathComponent("WorkoutTracker_AppIcons")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appIconsPath, withIntermediateDirectories: true)
        
        var generatedCount = 0
        
        for (filename, size) in iconSizes {
            let renderer = ImageRenderer(content: AppIconGeneratorStickFigure(size: size))
            renderer.scale = 1.0
            
            if let uiImage = renderer.uiImage {
                let fileURL = appIconsPath.appendingPathComponent(filename)
                
                if let data = uiImage.pngData() {
                    try? data.write(to: fileURL)
                    generatedCount += 1
                }
            }
        }
        
        return appIconsPath.path
    }
    
    /// Generate core graphics version for better quality
    static func generateCoreGraphicsIcon(size: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            let cgContext = context.cgContext
            
            // Background gradient
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0).cgColor,
                UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0).cgColor,
                UIColor(red: 0.05, green: 0.15, blue: 0.35, alpha: 1.0).cgColor
            ]
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 0.5, 1.0]) {
                cgContext.drawLinearGradient(gradient,
                                           start: CGPoint(x: 0, y: 0),
                                           end: CGPoint(x: size, y: size),
                                           options: [])
            }
            
            // Round corners
            let cornerRadius = size * 0.1
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.addClip()
            
            // Draw stick figure
            drawStickFigure(context: cgContext, size: size)
        }
    }
    
    static private func drawStickFigure(context: CGContext, size: CGFloat) {
        let center = CGPoint(x: size / 2, y: size / 2)
        let scale = size / 1024
        
        // Define positions
        let armY = center.y - 40 * scale
        let armLength = 80 * scale
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(8 * scale)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Head (circle)
        let headRadius = 30 * scale
        let headCenter = CGPoint(x: center.x, y: center.y - 120 * scale)
        let headRect = CGRect(x: headCenter.x - headRadius,
                             y: headCenter.y - headRadius,
                             width: headRadius * 2,
                             height: headRadius * 2)
        context.strokeEllipse(in: headRect)
        
        // Body (vertical line)
        context.move(to: CGPoint(x: center.x, y: center.y - 90 * scale))
        context.addLine(to: CGPoint(x: center.x, y: center.y + 60 * scale))
        context.strokePath()
        
        // Arms holding barbell
        context.move(to: CGPoint(x: center.x, y: armY))
        context.addLine(to: CGPoint(x: center.x - armLength, y: armY - 30 * scale))
        context.strokePath()
        
        context.move(to: CGPoint(x: center.x, y: armY))
        context.addLine(to: CGPoint(x: center.x + armLength, y: armY - 30 * scale))
        context.strokePath()
        
        // Legs
        let legY = center.y + 60 * scale
        let legLength = 70 * scale
        
        context.move(to: CGPoint(x: center.x, y: legY))
        context.addLine(to: CGPoint(x: center.x - 40 * scale, y: legY + legLength))
        context.strokePath()
        
        context.move(to: CGPoint(x: center.x, y: legY))
        context.addLine(to: CGPoint(x: center.x + 40 * scale, y: legY + legLength))
        context.strokePath()
        
        // Barbell
        let barbellY = armY - 30 * scale  
        let barbellWidth = 180 * scale
        let plateWidth = 20 * scale
        let plateHeight = 40 * scale
        
        // Barbell bar
        context.setLineWidth(6 * scale)
        context.move(to: CGPoint(x: center.x - barbellWidth/2, y: barbellY))
        context.addLine(to: CGPoint(x: center.x + barbellWidth/2, y: barbellY))
        context.strokePath()
        
        // Weight plates
        context.setFillColor(UIColor.white.cgColor)
        let platePositions: [CGFloat] = [
            center.x - barbellWidth/2,
            center.x - barbellWidth/2 + plateWidth,
            center.x + barbellWidth/2 - plateWidth,
            center.x + barbellWidth/2
        ]
        
        for plateX in platePositions {
            let plateRect = CGRect(x: plateX - plateWidth/2,
                                 y: barbellY - plateHeight/2,
                                 width: plateWidth,
                                 height: plateHeight)
            let platePath = UIBezierPath(roundedRect: plateRect, cornerRadius: 4 * scale)
            context.addPath(platePath.cgPath)
            context.fillPath()
        }
    }
}

/// View to trigger icon generation (for development use)
struct IconGeneratorDeveloperView: View {
    @State private var isGenerating = false
    @State private var generationComplete = false
    @State private var generatedPath: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Generator")
                .font(.title)
                .fontWeight(.bold)
            
            // Preview of the icon
            AppIconGeneratorStickFigure(size: 200)
                .cornerRadius(40)
                .shadow(radius: 10)
            
            Text("Preview: Stick Figure with Barbell")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: generateIcons) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text(isGenerating ? "Generating..." : "Generate All Icon Sizes")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(isGenerating)
            
            if generationComplete {
                VStack(spacing: 8) {
                    Text("✅ Icons generated successfully!")
                        .foregroundColor(.green)
                        .font(.headline)
                    
                    Text("Location: \(generatedPath)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Text("Instructions:\n1. Run this generator\n2. Find files in Downloads/WorkoutTracker_AppIcons/\n3. Copy all PNG files to Assets.xcassets/AppIcon.appiconset/\n4. Clean build in Xcode")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private func generateIcons() {
        isGenerating = true
        
        Task {
            let path = await IconExporter.generateAppIcons()
            
            await MainActor.run {
                isGenerating = false
                generationComplete = true
                generatedPath = path
            }
        }
    }
}

#Preview {
    IconGeneratorDeveloperView()
}