import Foundation

/// Implementación de los casos de uso para gestionar entradas de entrenamiento.
class WorkoutEntryUseCase: WorkoutEntryUseCaseProtocol {
    private let repository: WorkoutEntryRepositoryProtocol

    init(repository: WorkoutEntryRepositoryProtocol) {
        self.repository = repository
    }

    func getAll() async throws -> [WorkoutEntry] {
        try await repository.getAll()
    }

    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntry] {
        try await repository.getAll(for: exerciseID)
    }

    func add(_ entry: WorkoutEntry) async throws {
        try await repository.add(entry)
    }

    func update(_ entry: WorkoutEntry) async throws {
        try await repository.update(entry)
    }

    func delete(entryID: UUID) async throws {
        try await repository.delete(entryID: entryID)
    }

    func deleteEntries(for day: WorkoutEntryByDay) async throws {
        for entry in day.entries {
            try await delete(entryID: entry.id)
        }
    }

    func getAllByDay() async throws -> [WorkoutEntryByDay] {
        let all = try await getAll()
        let calendar = Calendar(identifier: .gregorian)
        let grouped = Dictionary(grouping: all) { entry -> String in
            let start = calendar.startOfDay(for: entry.date)
            return ISO8601DateFormatter().string(from: start)
        }
        return grouped.map { dateString, entries in
            let dates = entries.map { $0.date }.sorted()
            let duration: Int = {
                guard let first = dates.first, let last = dates.last, last > first else { return 0 }
                return Int(last.timeIntervalSince(first))
            }()
            return WorkoutEntryByDay(date: dateString, entries: entries, durationInSeconds: duration)
        }
        .sorted {
            guard let d0 = $0.parsedDate, let d1 = $1.parsedDate else {
                return $0.date > $1.date
            }
            return d0 > d1
        }
    }

    func groupByExercise(these entries: [WorkoutEntry]) -> [Exercise: [WorkoutEntry]] {
        Dictionary(grouping: entries, by: { $0.exercise })
            .mapValues { list in list.sorted { $0.date > $1.date } }
    }

    func order(these entries: [WorkoutEntry]) -> [Exercise] {
        entries
            .sorted { $0.date > $1.date }
            .map { $0.exercise }
            .reduce(into: [Exercise]()) { result, ex in if !result.contains(ex) { result.append(ex) } }
    }
}