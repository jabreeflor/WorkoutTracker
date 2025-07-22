import SwiftUI
import UIKit

struct IconGeneratorUtility {
    static func generateAppIcons() -> [UIImage] {
        let sizes: [(String, CGFloat)] = [
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
        
        var generatedImages: [UIImage] = []
        
        for (filename, size) in sizes {
            let image = createIcon(size: size)
            saveImage(image, filename: filename)
            generatedImages.append(image)
        }
        
        return generatedImages
    }
    
    static func createIcon(size: CGFloat) -> UIImage {
        let view = AppIconGenerator(size: size)
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: size, height: size)
        hostingController.view.backgroundColor = UIColor.clear
        
        // Force the view to layout
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
    }
    
    private static func saveImage(_ image: UIImage, filename: String) {
        guard let data = image.pngData() else { 
            print("Failed to convert image to PNG data for \(filename)")
            return 
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ Saved: \(filename) to \(fileURL.path)")
        } catch {
            print("❌ Error saving \(filename): \(error)")
        }
    }
    
    static func getDocumentsPath() -> String {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
    }
}

// Note: IconGeneratorView is now in a separate file: IconGeneratorView.swift