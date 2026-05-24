import SwiftUI

extension SetTag {
    var label: String {
        switch self {
        case .topSet: return "Top set"
        case .backOff: return "Back off"
        case .warmUp: return "Calentamiento"
        case .failure: return "Fallo"
        }
    }

    var shortLabel: String {
        switch self {
        case .topSet: return "Top"
        case .backOff: return "Back off"
        case .warmUp: return "Warm-up"
        case .failure: return "Fallo"
        }
    }

    var symbol: String {
        switch self {
        case .topSet: return "flame.fill"
        case .backOff: return "arrow.down.right"
        case .warmUp: return "thermometer.sun"
        case .failure: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .topSet: return Color(red: 1.00, green: 0.55, blue: 0.10)
        case .backOff: return Color(red: 0.30, green: 0.65, blue: 0.95)
        case .warmUp: return Color(red: 0.60, green: 0.60, blue: 0.65)
        case .failure: return Color(red: 0.95, green: 0.30, blue: 0.30)
        }
    }
}
