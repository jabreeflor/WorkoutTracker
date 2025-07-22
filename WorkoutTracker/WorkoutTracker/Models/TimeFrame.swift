import Foundation

enum TimeFrame: CaseIterable {
    case week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .week: return "1W"
        case .month: return "1M"
        case .quarter: return "3M"
        case .year: return "1Y"
        }
    }
    
    var cutoffDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
    
    var daysBetween: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
}