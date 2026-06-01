import Foundation

class ExerciseLocalDataSource: ExerciseDataSourceProtocol {
    private var localStorage: UserDefaultsManagerProtocol

    enum ExerciseKey: String {
        case catalog = "exercises.catalog"
    }

    init(localStorage: UserDefaultsManagerProtocol) {
        self.localStorage = localStorage
    }

    func getExercises() async throws -> [ExerciseDTO] {
        return self.localStorage.get(forKey: ExerciseKey.catalog.rawValue) ?? []
    }

    func getExercises(contains searchText: String) async throws -> [ExerciseDTO] {
        let all: [ExerciseDTO] = self.localStorage.get(forKey: ExerciseKey.catalog.rawValue) ?? []
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    func create(_ exercise: ExerciseDTO) async throws -> ExerciseDTO {
        var all: [ExerciseDTO] = self.localStorage.get(forKey: ExerciseKey.catalog.rawValue) ?? []
        all.removeAll { $0.id == exercise.id }
        all.append(exercise)
        self.localStorage.save(all, forKey: ExerciseKey.catalog.rawValue)
        return exercise
    }

    func delete(_ id: String) async throws {
        var all: [ExerciseDTO] = self.localStorage.get(forKey: ExerciseKey.catalog.rawValue) ?? []
        all.removeAll { $0.id == id }
        self.localStorage.save(all, forKey: ExerciseKey.catalog.rawValue)
    }
}
