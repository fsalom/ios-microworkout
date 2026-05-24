import Foundation

public enum SetTag: String, Codable, CaseIterable, Equatable, Hashable {
    case topSet
    case backOff
    case warmUp
    case failure
}
