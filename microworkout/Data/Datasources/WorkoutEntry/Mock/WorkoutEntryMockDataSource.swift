import Foundation

/// Mock data source para WorkoutEntry.
class WorkoutEntryMockDataSource: WorkoutEntryDataSourceProtocol {
    func getAll() async throws -> [WorkoutEntry] {
        []
    }

    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntry] {
        []
    }

    func add(_ entry: WorkoutEntry) async throws {
        // no-op
    }

    func update(_ entry: WorkoutEntry) async throws {
        // no-op
    }

    func delete(entryID: UUID) async throws {
        // no-op
    }
}