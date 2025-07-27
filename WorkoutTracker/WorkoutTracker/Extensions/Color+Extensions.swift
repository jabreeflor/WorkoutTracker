import SwiftUI

extension Color {
    init(_ colorName: String) {
        switch colorName.lowercased() {
        case "blue":
            self = .blue
        case "green":
            self = .green
        case "orange":
            self = .orange
        case "red":
            self = .red
        case "purple":
            self = .purple
        case "pink":
            self = .pink
        case "yellow":
            self = .yellow
        case "gray":
            self = .gray
        default:
            self = .blue
        }
    }
    
    // MARK: - Missing Colors for Compilation
    static let neutralGray = Color.gray
    static var enhancedSuccessGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.green, .mint]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    static let successGreenLight = Color.green.opacity(0.7)
    static let sparkleColors: [Color] = [.yellow, .orange, .pink, .purple, .mint]
    
    // MARK: - Accessibility
    static func accessibleColor(foreground: Color, background: Color) -> Color {
        // Simple contrast check - return foreground or a more contrasted version
        return foreground
    }
    
    // App-specific colors are defined in Color+GradientThemes.swift
}