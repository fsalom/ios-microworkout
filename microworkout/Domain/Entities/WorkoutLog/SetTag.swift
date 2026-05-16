import Foundation
import SwiftUI

public enum SetTag: String, Codable, CaseIterable, Equatable, Hashable {
    case topSet
    case backOff
    case warmUp
    case failure

    public var label: String {
        switch self {
        case .topSet: return "Top set"
        case .backOff: return "Back off"
        case .warmUp: return "Calentamiento"
        case .failure: return "Fallo"
        }
    }

    public var shortLabel: String {
        switch self {
        case .topSet: return "Top"
        case .backOff: return "Back off"
        case .warmUp: return "Warm-up"
        case .failure: return "Fallo"
        }
    }

    public var symbol: String {
        switch self {
        case .topSet: return "flame.fill"
        case .backOff: return "arrow.down.right"
        case .warmUp: return "thermometer.sun"
        case .failure: return "xmark.circle.fill"
        }
    }

    public var color: Color {
        switch self {
        case .topSet: return Color(red: 1.00, green: 0.55, blue: 0.10)    // amber/orange
        case .backOff: return Color(red: 0.30, green: 0.65, blue: 0.95)   // blue
        case .warmUp: return Color(red: 0.60, green: 0.60, blue: 0.65)    // gray
        case .failure: return Color(red: 0.95, green: 0.30, blue: 0.30)   // red
        }
    }
}
