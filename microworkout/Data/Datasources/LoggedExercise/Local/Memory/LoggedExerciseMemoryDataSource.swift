//
//  TicketsMemoryDataSource.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 29/7/25.
//


import Foundation

class LoggedExerciseInMemory: MemoryDataSource<[LoggedExerciseDTO]> {}

class LoggedExerciseMemoryDataSource: LoggedExerciseDataSourceProtocol {
    var memory: LoggedExerciseInMemory

    init(memory: LoggedExerciseInMemory) {
        self.memory = memory
    }

    func add(this exercise: LoggedExerciseDTO) async throws -> [LoggedExerciseDTO] {
        do {
            var exercises: [LoggedExerciseDTO] = try memory.get()
            exercises.append(exercise)
            memory.save(value: exercises)
            return exercises
        } catch {
            if case MemoryDataSourceError.notInitialized = error {
                memory.save(value: [exercise])
            }
            return [exercise]
        }
    }

    func delete(with id: String) async throws -> [LoggedExerciseDTO] {
        var exercises: [LoggedExerciseDTO] = try memory.get()
        exercises.removeAll(where: {$0.id == id})
        memory.save(value: exercises)
        return exercises
    }

    func update(this exercise: LoggedExerciseDTO) async throws -> [LoggedExerciseDTO] {
        var exercises: [LoggedExerciseDTO] = try memory.get()
        guard let index = exercises.firstIndex(of: exercises.first(where: {$0.id == exercise.id})!) else {
            return exercises
        }
        exercises[index] = exercise
        memory.save(value: exercises)
        return exercises
    }

    func save(these exercises: [LoggedExerciseDTO], with duration: Int) async throws {
        fatalError("THIS IS NOT IMPLEMENTED")
    }

    func getAll() async throws -> [LoggedExerciseByDayDTO] {
        fatalError("THIS IS NOT IMPLEMENTED")
    }

}
