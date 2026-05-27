import Foundation

/// Espejo on-disk de `WorkoutEntry`. Mantiene la misma forma JSON que la
/// entidad de Domain (incluido el `Exercise` anidado) para que la introducción
/// de este DTO no rompa datos ya guardados por usuarios. `ExerciseType` se
/// serializa como `String` para desacoplar el formato del enum.
struct WorkoutEntryDTO: Codable, Equatable {
    let id: UUID
    let exercise: ExerciseEmbeddedDTO
    var date: Date
    var reps: Int?
    var weight: Double?
    var distanceMeters: Double?
    var calories: Double?
    var isCompleted: Bool
}

/// Subobjeto de `WorkoutEntryDTO`. Separado de `ExerciseDTO` (que vive en
/// `Exercise/Local/DTO`) porque aquél usa `id: String` (slug del catálogo
/// mock), mientras que aquí necesitamos `UUID` para casar con `Exercise.id`.
struct ExerciseEmbeddedDTO: Codable, Equatable {
    let id: UUID
    var name: String
    var type: String
}

// MARK: - DTO ↔ Domain

extension WorkoutEntryDTO {
    func toDomain() -> WorkoutEntry {
        WorkoutEntry(
            id: id,
            exercise: exercise.toDomain(),
            date: date,
            reps: reps,
            weight: weight,
            distanceMeters: distanceMeters,
            calories: calories,
            isCompleted: isCompleted
        )
    }
}

extension ExerciseEmbeddedDTO {
    func toDomain() -> Exercise {
        Exercise(
            id: id,
            name: name,
            type: ExerciseType(rawValue: type) ?? .none
        )
    }
}

extension WorkoutEntry {
    func toDTO() -> WorkoutEntryDTO {
        WorkoutEntryDTO(
            id: id,
            exercise: exercise.toEmbeddedDTO(),
            date: date,
            reps: reps,
            weight: weight,
            distanceMeters: distanceMeters,
            calories: calories,
            isCompleted: isCompleted
        )
    }
}

extension Exercise {
    func toEmbeddedDTO() -> ExerciseEmbeddedDTO {
        ExerciseEmbeddedDTO(id: id, name: name, type: type.rawValue)
    }
}
