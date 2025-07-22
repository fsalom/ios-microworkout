//
//  TrainingLocalDataSource.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//


class ExerciseLocalDataSource: ExerciseDataSourceProtocol {
    private var localStorage: UserDefaultsManagerProtocol

    enum ExerciseKey: String {
        case current
        case finish
    }

    init(localStorage: UserDefaultsManagerProtocol) {
        self.localStorage = localStorage
    }

    func getExercises(contains searchText: String) -> [ExerciseDTO] {
        return self.localStorage.get(forKey: ExerciseKey.current.rawValue) ?? []
    }

    func getExercises() -> [ExerciseDTO] {
        return self.localStorage.get(forKey: ExerciseKey.current.rawValue) ?? []
    }
}
