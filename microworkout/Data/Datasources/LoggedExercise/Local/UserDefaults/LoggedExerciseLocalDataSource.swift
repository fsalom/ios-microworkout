//
//  TrainingLocalDataSource.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

import Foundation


enum LocalError: Error {
    case notFound
}

class LoggedExerciseLocalDataSource: LoggedExerciseDataSourceProtocol {

    
    private var localStorage: UserDefaultsManagerProtocol

    enum ExerciseKey: String {
        case current
        case all
    }

    init(localStorage: UserDefaultsManagerProtocol) {
        self.localStorage = localStorage
    }

    func add(this exercise: LoggedExerciseDTO) async throws -> [LoggedExerciseDTO] {
        var exercises: [LoggedExerciseDTO] = self.localStorage.get(forKey: ExerciseKey.current.rawValue) ?? []
        exercises.append(exercise)
        self.localStorage.save(exercises, forKey: ExerciseKey.current.rawValue)
        return exercises
    }
    
    func update(this exercise: LoggedExerciseDTO) async throws -> [LoggedExerciseDTO] {
        var exercises: [LoggedExerciseDTO] = self.localStorage.get(forKey: ExerciseKey.current.rawValue) ?? []
        guard let index = exercises.firstIndex(where: {$0.id == exercise.id}) else {
            throw LocalError.notFound
        }
        exercises[index] = exercise
        self.localStorage.save(exercises, forKey: ExerciseKey.current.rawValue)
        return exercises
    }
    
    func delete(with id: String) async throws -> [LoggedExerciseDTO] {
        var exercises: [LoggedExerciseDTO] = self.localStorage.get(forKey: ExerciseKey.current.rawValue) ?? []
        exercises.removeAll(where: {$0.id == id})
        self.localStorage.save(exercises, forKey: ExerciseKey.current.rawValue)
        return exercises
    }

    func delete(this loggedExercisesByDay: LoggedExerciseByDay) async throws {
        var allDaysWithExercises = try await self.getAll()
        allDaysWithExercises.removeAll(where: {$0.date == loggedExercisesByDay.date})
        self.localStorage.save(allDaysWithExercises, forKey: ExerciseKey.all.rawValue)
    }

    func save(these exercises: [LoggedExerciseDTO], with duration: Int) async throws {        
        let newDayWithExercises = LoggedExerciseByDayDTO(
            date: LoggedExerciseByDayDTO.getDateFormat(for: Date()),
            exercises: exercises,
            durationInSeconds: duration
        )
        var allDaysWithExercises: [LoggedExerciseByDayDTO] = self.localStorage.get(forKey: ExerciseKey.all.rawValue) ?? []
        allDaysWithExercises.append(newDayWithExercises)
        self.localStorage.save(allDaysWithExercises, forKey: ExerciseKey.all.rawValue)
    }

    func getAll() async throws -> [LoggedExerciseByDayDTO] {
        let allDaysWithExercises: [LoggedExerciseByDayDTO] = self.localStorage.get(forKey: ExerciseKey.all.rawValue) ?? []
        return allDaysWithExercises
    }
}
