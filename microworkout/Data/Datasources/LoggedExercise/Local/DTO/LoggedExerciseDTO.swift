//
//  LoggedExercise.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 27/7/25.
//


struct LoggedExerciseDTO: Codable, Equatable {
    static func == (lhs: LoggedExerciseDTO, rhs: LoggedExerciseDTO) -> Bool {
        lhs.id == rhs.id
    }

    var id: String
    let exercise: ExerciseDTO
    var reps: Int
    var weight: Double
    var isCompleted: Bool = false
}
