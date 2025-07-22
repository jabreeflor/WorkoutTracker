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
}