import Foundation

public struct LoggedSet: Identifiable, Equatable, Codable {
    public let id: UUID
    public var weight: Double?
    public var reps: Int?
    public var rir: Float?
    public var tags: [SetTag]

    public init(
        id: UUID = UUID(),
        weight: Double? = nil,
        reps: Int? = nil,
        rir: Float? = nil,
        tags: [SetTag] = []
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.rir = rir
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id, weight, reps, rir, tags
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.weight = try c.decodeIfPresent(Double.self, forKey: .weight)
        self.reps = try c.decodeIfPresent(Int.self, forKey: .reps)
        self.rir = try c.decodeIfPresent(Float.self, forKey: .rir)
        // Tolerate older payloads without `tags`.
        self.tags = (try? c.decodeIfPresent([SetTag].self, forKey: .tags)) ?? []
    }
}
