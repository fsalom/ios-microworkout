//
//  ExerciseRepository.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

class LoggedExerciseRepository: LoggedExerciseRepositoryProtocol {

    
    private var memory: LoggedExerciseDataSourceProtocol
    private var local: LoggedExerciseDataSourceProtocol

    init(memory: LoggedExerciseDataSourceProtocol, local: LoggedExerciseDataSourceProtocol){
        self.memory = memory
        self.local = local
    }

    func add(this exercise: LoggedExercise) async throws -> [LoggedExercise] {
        try await self.memory.add(this: exercise.toDTO()).map({$0.toDomain()})
    }

    func update(this exercise: LoggedExercise) async throws -> [LoggedExercise] {
        try await self.memory.update(this: exercise.toDTO()).map({$0.toDomain()})
    }
    
    func delete(with id: String) async throws -> [LoggedExercise] {
        try await self.memory.delete(with: id).map({$0.toDomain()})
    }

    func delete(this loggedExercisesByDay: LoggedExerciseByDay) async throws {
        try await self.local.delete(this: loggedExercisesByDay)
    }

    func save(these exercises: [LoggedExercise], with duration: Int) async throws {
        try await self.local.save(these: exercises.map({$0.toDTO()}), with: duration)
    }

    func getAll() async throws -> [LoggedExerciseByDay] {
        try await self.local.getAll().map({$0.toDomain()})
    }
}

fileprivate extension ExerciseDTO {
    func toDomain() -> Exercise {
        return Exercise(id: self.id, name: self.name)
    }
}

fileprivate extension Exercise {
    func toDTO(type: String = "") -> ExerciseDTO {
        return ExerciseDTO(id: self.id, name: self.name, type: type)
    }
}

fileprivate extension LoggedExerciseDTO {
    func toDomain() -> LoggedExercise {
        return LoggedExercise(
            id: self.id,
            exercise: self.exercise.toDomain(),
            reps: self.reps,
            weight: self.weight,
            isCompleted: self.isCompleted
        )
    }
}

fileprivate extension LoggedExercise {
    func toDTO() -> LoggedExerciseDTO {
        return LoggedExerciseDTO(
            id: self.id,
            exercise: self.exercise.toDTO(),
            reps: self.reps,
            weight: self.weight,
            isCompleted: self.isCompleted
        )
    }
}

fileprivate extension LoggedExerciseByDayDTO {
    func toDomain() -> LoggedExerciseByDay {
        return LoggedExerciseByDay(
            date: self.date,
            exercises: self.exercises.map({$0.toDomain()}),
            durationInSeconds: self.durationInSeconds
        )
    }
}
