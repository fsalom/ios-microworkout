//
//  ExerciseUseCase.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

import Foundation

class LoggedExerciseUseCase: LoggedExerciseUseCaseProtocol {

    private var repository: LoggedExerciseRepositoryProtocol

    init(repository: LoggedExerciseRepositoryProtocol) {
        self.repository = repository
    }

    func add(new exercise: LoggedExercise) async throws -> [LoggedExercise] {
        try await self.repository.add(this: exercise)
    }

    func update(this exercise: LoggedExercise) async throws -> [LoggedExercise] {
        try await self.repository.update(this: exercise)
    }

    func delete(this id: String) async throws -> [LoggedExercise] {
        try await self.repository.delete(with: id)
    }

    func delete(this loggedExerciseByDay: LoggedExerciseByDay) async throws {
        try await self.repository.delete(this: loggedExerciseByDay)
    }

    func groupByExercise(these exercises: [LoggedExercise]) -> [Exercise: [LoggedExercise]] {
        Dictionary(
                grouping: exercises,
                by: { $0.exercise }
            )
            .mapValues { group in
                group.sorted { $0.date > $1.date }
            }
    }

    func order(these exercises: [LoggedExercise]) -> [Exercise] {
        exercises
            .sorted { $0.date > $1.date }
            .map { $0.exercise }.uniqued()
    }

    func getAll() async throws -> [LoggedExerciseByDay] {
        try await self.repository.getAll().sorted {
            guard
                let d0 = $0.parsedDate,
                let d1 = $1.parsedDate
            else {
                return $0.date > $1.date
            }
            return d0 > d1
        }
    }

    func save(these exercises: [LoggedExercise], with duration: Int) async throws {
        try await repository.save(these: exercises, with: duration)
    }
}

fileprivate extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
