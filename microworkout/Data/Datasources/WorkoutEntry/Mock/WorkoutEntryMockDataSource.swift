import Foundation

/// Mock data source para WorkoutEntry.
class WorkoutEntryMockDataSource: WorkoutEntryDataSourceProtocol {
    func getAll() async throws -> [WorkoutEntryDTO] { [] }
    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntryDTO] { [] }
    func add(_ entry: WorkoutEntryDTO) async throws {}
    func update(_ entry: WorkoutEntryDTO) async throws {}
    func delete(entryID: UUID) async throws {}
}
