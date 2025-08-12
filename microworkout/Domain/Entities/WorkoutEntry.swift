import Foundation

/// Registra una sesión o serie de un ejercicio tomado del catálogo.
/// Registra el ejercicio completo en la propiedad `exercise` para relacionarse con la fuente maestra.
public struct WorkoutEntry: Identifiable, Equatable, Hashable, Codable {
    public let id: UUID
    /// Ejercicio del catálogo maestro al que pertenece esta entrada.
    public let exercise: Exercise
    public var date: Date

    /// Datos variables según el tipo de ejercicio.
    public var reps: Int?
    public var weight: Double?
    public var distanceMeters: Double?
    public var calories: Double?

    public var isCompleted: Bool

    public init(
        id: UUID = UUID(),
        exercise: Exercise,
        date: Date = Date(),
        reps: Int? = nil,
        weight: Double? = nil,
        distanceMeters: Double? = nil,
        calories: Double? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.exercise = exercise
        self.date = date
        self.reps = reps
        self.weight = weight
        self.distanceMeters = distanceMeters
        self.calories = calories
        self.isCompleted = isCompleted
    }
}