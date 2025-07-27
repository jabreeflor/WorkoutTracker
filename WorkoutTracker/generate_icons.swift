#!/usr/bin/env swift

import Foundation
import SwiftUI
import UIKit

// Recreate our stick figure design for script use
struct StickFigureIcon {
    static func generateIcon(size: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            
            // Background gradient
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [
                                        UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0).cgColor,
                                        UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0).cgColor,
                                        UIColor(red: 0.05, green: 0.15, blue: 0.35, alpha: 1.0).cgColor
                                    ] as CFArray,
                                    locations: [0.0, 0.5, 1.0])!
            
            context.cgContext.drawLinearGradient(gradient,
                                               start: CGPoint(x: 0, y: 0),
                                               end: CGPoint(x: size, y: size),
                                               options: [])
            
            // Round corners
            let cornerRadius = size * 0.1
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.addClip()
            
            // Draw stick figure
            drawStickFigure(context: context.cgContext, size: size)
        }
    }
    
    static func drawStickFigure(context: CGContext, size: CGFloat) {
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

// Generate all icon sizes
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

// Create output directory
let outputPath = "./generated_icons/"
try? FileManager.default.createDirectory(atPath: outputPath, withIntermediateDirectories: true)

print("Generating stick figure app icons...")

for (filename, size) in iconSizes {
    if let image = StickFigureIcon.generateIcon(size: size),
       let data = image.pngData() {
        let filePath = outputPath + filename
        let fileURL = URL(fileURLWithPath: filePath)
        try? data.write(to: fileURL)
        print("Generated: \(filename)")
    }
}

print("✅ All icons generated in ./generated_icons/ folder")
print("Now copy these files to WorkoutTracker/Assets.xcassets/AppIcon.appiconset/")