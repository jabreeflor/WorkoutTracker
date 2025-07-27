import SwiftUI

struct AppIconGenerator: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Modern gradient background - gym theme
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.3, blue: 0.8),  // Deep blue
                    Color(red: 0.05, green: 0.25, blue: 0.7), // Darker blue
                    Color(red: 0.02, green: 0.2, blue: 0.6)   // Even darker
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Main icon - person lifting barbell
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: size * 0.015, x: 0, y: size * 0.008)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22)) // iOS standard corner radius
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.003
                )
        )
    }
}

// Alternative design with dumbbell
struct AppIconGeneratorAlternative: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.9),
                    Color.blue.opacity(0.7),
                    Color.blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Dumbbell icon with person silhouette
            VStack(spacing: size * 0.05) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: size * 0.3, weight: .medium))
                    .foregroundColor(.white)
                
                Image(systemName: "dumbbell")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .shadow(color: .black.opacity(0.3), radius: size * 0.02, x: 0, y: size * 0.01)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.1))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.1)
                .stroke(Color.white.opacity(0.1), lineWidth: size * 0.002)
        )
    }
}

// Simple clean design
struct AppIconGeneratorMinimal: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Solid blue background
            Color.blue
            
            // White figure
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: size * 0.6, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: size * 0.01, x: 0, y: size * 0.005)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.1))
    }
}

// Stick figure lifting barbell design
struct AppIconGeneratorStickFigure: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Gradient background with modern gym colors
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.3, blue: 0.5),
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.05, green: 0.15, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Custom stick figure with barbell
            StickFigureWithBarbell(size: size)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.1))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.1)
                .stroke(Color.white.opacity(0.1), lineWidth: size * 0.002)
        )
    }
}

// Custom stick figure drawing
struct StickFigureWithBarbell: View {
    let size: CGFloat
    
    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let scale = size / 1024
            
            // Define positions used in multiple places
            let armY = center.y - 40 * scale
            let armLength = 80 * scale
            let legY = center.y + 60 * scale
            let legLength = 70 * scale
            
            // Set drawing properties
            context.stroke(
                Path { path in
                    // Head (circle)
                    let headRadius = 30 * scale
                    let headCenter = CGPoint(x: center.x, y: center.y - 120 * scale)
                    path.addEllipse(in: CGRect(
                        x: headCenter.x - headRadius,
                        y: headCenter.y - headRadius,
                        width: headRadius * 2,
                        height: headRadius * 2
                    ))
                    
                    // Body (vertical line)
                    path.move(to: CGPoint(x: center.x, y: center.y - 90 * scale))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + 60 * scale))
                    
                    // Arms holding barbell
                    // Left arm
                    path.move(to: CGPoint(x: center.x, y: armY))
                    path.addLine(to: CGPoint(x: center.x - armLength, y: armY - 30 * scale))
                    
                    // Right arm  
                    path.move(to: CGPoint(x: center.x, y: armY))
                    path.addLine(to: CGPoint(x: center.x + armLength, y: armY - 30 * scale))
                    
                    // Legs
                    // Left leg
                    path.move(to: CGPoint(x: center.x, y: legY))
                    path.addLine(to: CGPoint(x: center.x - 40 * scale, y: legY + legLength))
                    
                    // Right leg
                    path.move(to: CGPoint(x: center.x, y: legY))
                    path.addLine(to: CGPoint(x: center.x + 40 * scale, y: legY + legLength))
                },
                with: .color(.white),
                style: StrokeStyle(lineWidth: 8 * scale, lineCap: .round, lineJoin: .round)
            )
            
            // Barbell
            let barbellY = armY - 30 * scale
            let barbellWidth = 180 * scale
            let plateWidth = 20 * scale
            let plateHeight = 40 * scale
            
            // Barbell bar
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: center.x - barbellWidth/2, y: barbellY))
                    path.addLine(to: CGPoint(x: center.x + barbellWidth/2, y: barbellY))
                },
                with: .color(.white),
                style: StrokeStyle(lineWidth: 6 * scale, lineCap: .round)
            )
            
            // Weight plates
            let platePositions = [
                center.x - barbellWidth/2,  // Left outer
                center.x - barbellWidth/2 + plateWidth, // Left inner
                center.x + barbellWidth/2 - plateWidth, // Right inner
                center.x + barbellWidth/2   // Right outer
            ]
            
            for plateX in platePositions {
                context.fill(
                    Path { path in
                        path.addRoundedRect(
                            in: CGRect(
                                x: plateX - plateWidth/2,
                                y: barbellY - plateHeight/2,
                                width: plateWidth,
                                height: plateHeight
                            ),
                            cornerSize: CGSize(width: 4 * scale, height: 4 * scale)
                        )
                    },
                    with: .color(.white)
                )
            }
        }
        .frame(width: size, height: size)
    }
}

// Preview for testing different sizes
struct AppIconGeneratorPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Designs")
                .font(.title)
                .bold()
            
            // First row
            HStack(spacing: 20) {
                VStack {
                    AppIconGenerator(size: 120)
                    Text("Gradient Design")
                        .font(.caption)
                }
                
                VStack {
                    AppIconGeneratorAlternative(size: 120)
                    Text("Alternative Design")
                        .font(.caption)
                }
                
                VStack {
                    AppIconGeneratorMinimal(size: 120)
                    Text("Minimal Design")
                        .font(.caption)
                }
            }
            
            // Second row - featuring the new stick figure design
            HStack(spacing: 20) {
                VStack {
                    AppIconGeneratorStickFigure(size: 180)
                    Text("Stick Figure with Barbell")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            Text("Tap and hold to save as image")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    AppIconGeneratorPreview()
}