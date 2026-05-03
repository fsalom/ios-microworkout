import Foundation

public struct LoggedSet: Identifiable, Equatable, Codable {
    public let id: UUID
    public var weight: Double?
    public var reps: Int?
    public var rir: Float?

    public init(
        id: UUID = UUID(),
        weight: Double? = nil,
        reps: Int? = nil,
        rir: Float? = nil
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.rir = rir
    }
}
