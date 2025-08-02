//
//  ExerciseLocalDataSource.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//


class LoggedExerciseMockDataSource: LoggedExerciseDataSourceProtocol {
    func save(these exercises: [LoggedExerciseDTO], with duration: Int) async throws {
        
    }
    
    func getAll() async throws -> [LoggedExerciseByDayDTO] {
        []
    }
    
    func save(these exercises: [LoggedExerciseDTO]) async throws {

    }
    
    func add(this exercise: LoggedExerciseDTO) async throws -> [LoggedExerciseDTO] {
        []
    }
    
    func update(this exercise: LoggedExerciseDTO) async throws -> [LoggedExerciseDTO] {
        []
    }
    
    func delete(with id: String) async throws -> [LoggedExerciseDTO] {
        []
    }
}
