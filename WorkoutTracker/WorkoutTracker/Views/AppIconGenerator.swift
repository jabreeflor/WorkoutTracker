import SwiftUI

struct AppIconGenerator: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.blue.opacity(0.6),
                    Color.blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Main icon - person with barbell
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundColor(.white)
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

// Preview for testing different sizes
struct AppIconGeneratorPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Designs")
                .font(.title)
                .bold()
            
            HStack(spacing: 20) {
                VStack {
                    AppIconGenerator(size: 180)
                    Text("Gradient Design")
                        .font(.caption)
                }
                
                VStack {
                    AppIconGeneratorAlternative(size: 180)
                    Text("Alternative Design")
                        .font(.caption)
                }
                
                VStack {
                    AppIconGeneratorMinimal(size: 180)
                    Text("Minimal Design")
                        .font(.caption)
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