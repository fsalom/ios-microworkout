//
//  LoggedExercise.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 27/7/25.
//

import Foundation


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


struct LoggedExerciseByDayDTO: Codable, Equatable {
    static func == (lhs: LoggedExerciseByDayDTO, rhs: LoggedExerciseByDayDTO) -> Bool {
        lhs.date == rhs.date
    }

    var date: String
    var exercises: [LoggedExerciseDTO]
    var durationInSeconds: Int

    static func getDateFormat(for date: Date) -> String {
        let iso = ISO8601DateFormatter()
        let dateString = iso.string(from: Date())  // e.g. "2025-08-01T17:45:12Z"
        return dateString
    }
}
