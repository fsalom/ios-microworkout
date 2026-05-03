import Foundation

public struct WorkoutSession: Identifiable, Equatable, Codable {
    public let id: UUID
    public var name: String
    public var exercises: [Exercise]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        exercises: [Exercise] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
