import SwiftUI

/// A small indicator showing the rest time for a set
struct RestTimeIndicator: View {
    let restTime: Int?
    let restTimeSource: RestTimeSource?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 2) {
                Image(systemName: "timer")
                    .font(.caption)
                
                Text(restTimeText)
                    .font(.caption)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(backgroundColor)
                    .opacity(0.15)
            }
            .foregroundColor(textColor)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var restTimeText: String {
        guard let restTime = restTime else {
            return "Default"
        }
        
        return RestTimeResolver.formatRestTime(restTime)
    }
    
    private var backgroundColor: Color {
        guard let source = restTimeSource else {
            return .gray
        }
        
        return source.color
    }
    
    private var textColor: Color {
        guard restTime != nil else {
            return .secondary
        }
        
        return backgroundColor
    }
}

#Preview {
    VStack(spacing: 20) {
        RestTimeIndicator(restTime: nil, restTimeSource: .globalDefault) {}
        RestTimeIndicator(restTime: 60, restTimeSource: .exerciseSpecific) {}
        RestTimeIndicator(restTime: 90, restTimeSource: .setSpecific) {}
    }
    .padding()
}
