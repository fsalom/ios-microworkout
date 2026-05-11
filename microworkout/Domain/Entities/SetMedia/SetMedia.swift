import Foundation

public struct SetMedia: Identifiable, Codable, Equatable {
    public let id: UUID
    public let setId: UUID
    public let type: SetMediaType
    public let filename: String
    public let createdAt: Date
    public let durationSeconds: Double?
    public var thumbnailFilename: String?

    public init(
        id: UUID = UUID(),
        setId: UUID,
        type: SetMediaType,
        filename: String,
        createdAt: Date = Date(),
        durationSeconds: Double? = nil,
        thumbnailFilename: String? = nil
    ) {
        self.id = id
        self.setId = setId
        self.type = type
        self.filename = filename
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.thumbnailFilename = thumbnailFilename
    }
}
