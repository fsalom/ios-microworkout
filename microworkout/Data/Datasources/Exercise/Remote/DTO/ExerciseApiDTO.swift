import Foundation

/// Shape returned by the Python backend at `/v1/exercises`.
struct ExerciseApiDTO: Codable {
    let id: UUID
    let name: String
    let type: String
}

extension ExerciseApiDTO {
    func toDomain() -> Exercise {
        Exercise(
            id: id,
            name: name,
            type: ExerciseType(rawValue: type) ?? .none
        )
    }
}
