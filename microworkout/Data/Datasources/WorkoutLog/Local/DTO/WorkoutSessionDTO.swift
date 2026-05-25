import Foundation

struct WorkoutSessionDTO: Codable {
    var id: UUID
    var name: String
    var exerciseIds: [UUID]
    var exerciseNames: [String]
    var exerciseTypes: [String]
    var createdAt: Date
    var updatedAt: Date
}
