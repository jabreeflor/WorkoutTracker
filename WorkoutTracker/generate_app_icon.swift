#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Create a simple barbell lifting icon using Core Graphics
func createBarbellLiftingIcon(size: CGFloat) -> CGImage? {
    let width = Int(size)
    let height = Int(size)
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    
    // Background gradient
    let gradient = CGGradient(colorsSpace: colorSpace,
                            colors: [
                                CGColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0),
                                CGColor(red: 0.05, green: 0.25, blue: 0.7, alpha: 1.0),
                                CGColor(red: 0.02, green: 0.2, blue: 0.6, alpha: 1.0)
                            ] as CFArray,
                            locations: [0.0, 0.5, 1.0])!
    
    context.drawLinearGradient(gradient,
                             start: CGPoint(x: 0, y: 0),
                             end: CGPoint(x: size, y: size),
                             options: [])
    
    // Apply corner radius (rounded rectangle)
    let cornerRadius = size * 0.22 // iOS standard
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    context.addPath(path)
    context.clip()
    
    // Draw stick figure with barbell
    drawStickFigureWithBarbell(context: context, size: size)
    
    return context.makeImage()
}

func drawStickFigureWithBarbell(context: CGContext, size: CGFloat) {
    let center = CGPoint(x: size / 2, y: size / 2)
    let scale = size / 1024
    
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1)) // White
    context.setLineWidth(12 * scale)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    
    // Head (circle)
    let headRadius = 40 * scale
    let headCenter = CGPoint(x: center.x, y: center.y - 140 * scale)
    context.strokeEllipse(in: CGRect(
        x: headCenter.x - headRadius,
        y: headCenter.y - headRadius,
        width: headRadius * 2,
        height: headRadius * 2
    ))
    
    // Body (vertical line)
    context.move(to: CGPoint(x: center.x, y: center.y - 100 * scale))
    context.addLine(to: CGPoint(x: center.x, y: center.y + 80 * scale))
    context.strokePath()
    
    // Arms holding barbell
    let armY = center.y - 50 * scale
    let armLength = 120 * scale
    
    // Left arm
    context.move(to: CGPoint(x: center.x, y: armY))
    context.addLine(to: CGPoint(x: center.x - armLength, y: armY - 40 * scale))
    context.strokePath()
    
    // Right arm
    context.move(to: CGPoint(x: center.x, y: armY))
    context.addLine(to: CGPoint(x: center.x + armLength, y: armY - 40 * scale))
    context.strokePath()
    
    // Legs
    let legY = center.y + 80 * scale
    let legLength = 100 * scale
    
    // Left leg
    context.move(to: CGPoint(x: center.x, y: legY))
    context.addLine(to: CGPoint(x: center.x - 60 * scale, y: legY + legLength))
    context.strokePath()
    
    // Right leg
    context.move(to: CGPoint(x: center.x, y: legY))
    context.addLine(to: CGPoint(x: center.x + 60 * scale, y: legY + legLength))
    context.strokePath()
    
    // Barbell
    let barbellY = armY - 40 * scale
    let barbellWidth = 240 * scale
    let plateWidth = 30 * scale
    let plateHeight = 60 * scale
    
    // Barbell bar
    context.setLineWidth(8 * scale)
    context.move(to: CGPoint(x: center.x - barbellWidth/2, y: barbellY))
    context.addLine(to: CGPoint(x: center.x + barbellWidth/2, y: barbellY))
    context.strokePath()
    
    // Weight plates
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    let platePositions: [CGFloat] = [
        center.x - barbellWidth/2,
        center.x - barbellWidth/2 + plateWidth,
        center.x + barbellWidth/2 - plateWidth,
        center.x + barbellWidth/2
    ]
    
    for plateX in platePositions {
        let plateRect = CGRect(
            x: plateX - plateWidth/2,
            y: barbellY - plateHeight/2,
            width: plateWidth,
            height: plateHeight
        )
        context.fillEllipse(in: plateRect)
    }
}

// Generate all required icon sizes
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
let assetPath = "./WorkoutTracker/Assets.xcassets/AppIcon.appiconset/"
let fileManager = FileManager.default

print("Generating barbell lifting app icons...")

for (filename, size) in iconSizes {
    if let cgImage = createBarbellLiftingIcon(size: size) {
        let outputURL = URL(fileURLWithPath: assetPath + filename)
        
        if let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(destination, cgImage, nil)
            if CGImageDestinationFinalize(destination) {
                print("✅ Generated: \(filename)")
            } else {
                print("❌ Failed to save: \(filename)")
            }
        }
    }
}

print("🎉 All icons generated successfully!")
print("Clean build your project to see the new icons.")