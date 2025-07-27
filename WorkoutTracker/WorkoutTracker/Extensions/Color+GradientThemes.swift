import SwiftUI

extension Color {
    // MARK: - Primary Colors
    static let primaryBlue = Color(red: 0.0, green: 0.478, blue: 1.0) // #007AFF
    static let successGreen = Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759
    static let celebrationGold = Color(red: 1.0, green: 0.839, blue: 0.039) // #FFD60A
    static let warningOrange = Color(red: 1.0, green: 0.584, blue: 0.0) // #FF9500
    static let errorRed = Color(red: 1.0, green: 0.231, blue: 0.188) // #FF3B30
    
    // MARK: - Gradient Themes
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [primaryBlue, primaryBlue.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        gradient: Gradient(colors: [successGreen, Color.mint]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let celebrationGradient = LinearGradient(
        gradient: Gradient(colors: [celebrationGold, warningOrange]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let neutralGradient = LinearGradient(
        gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let errorGradient = LinearGradient(
        gradient: Gradient(colors: [errorRed, Color.pink]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Dynamic Colors
    static let cardBackground = Color(.systemBackground)
    static let cardBorder = Color(.separator)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    
    // MARK: - State Colors
    static func stateColor(for state: ViewState) -> Color {
        switch state {
        case .inactive:
            return .gray
        case .active:
            return .primaryBlue
        case .editing:
            return .primaryBlue
        case .completed:
            return .successGreen
        case .error:
            return .errorRed
        }
    }
    
    static func stateGradient(for state: ViewState) -> LinearGradient {
        switch state {
        case .inactive:
            return neutralGradient
        case .active:
            return primaryGradient
        case .editing:
            return primaryGradient
        case .completed:
            return successGradient
        case .error:
            return errorGradient
        }
    }
}

// MARK: - View State Enum
enum ViewState {
    case inactive
    case active
    case editing
    case completed
    case error
}