protocol LoggedExerciseDataSourceProtocol {
    func add(this exercise: LoggedExerciseDTO) async throws -> [LoggedExerciseDTO]
    func update(this exercise: LoggedExerciseDTO) async throws -> [LoggedExerciseDTO]
    func delete(with id: String) async throws -> [LoggedExerciseDTO]
    func delete(this loggedExercisesByDay: LoggedExerciseByDay) async throws
    func save(these exercises: [LoggedExerciseDTO], with duration: Int) async throws
    func getAll() async throws -> [LoggedExerciseByDayDTO]
}
