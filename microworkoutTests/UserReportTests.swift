import XCTest
@testable import microworkout

/// El informe es el contexto que el coach recibe en cada conversación, así que lo
/// que importa aquí es que el texto del usuario y las notas de la IA no se mezclen
/// y que el límite del backend se respete antes de enviar (o serían 422).
final class UserReportTests: XCTestCase {

    private final class FakeRepository: UserReportRepositoryProtocol {
        var report = UserReport()
        var savedContent: String?
        var deletedIds: [Int] = []
        var updatedNotes: [(id: Int, content: String)] = []
        var errorToThrow: Error?

        func getReport() async throws -> UserReport {
            if let errorToThrow { throw errorToThrow }
            return report
        }

        func updateNote(id: Int, content: String) async throws {
            if let errorToThrow { throw errorToThrow }
            updatedNotes.append((id: id, content: content))
        }

        func setContent(_ content: String) async throws -> UserReport {
            if let errorToThrow { throw errorToThrow }
            savedContent = content
            report.content = content
            return report
        }

        func deleteNote(id: Int) async throws {
            if let errorToThrow { throw errorToThrow }
            deletedIds.append(id)
            report.notes.removeAll { $0.id == id }
        }
    }

    private func note(_ id: Int, _ content: String, _ source: UserReportNote.Source) -> UserReportNote {
        UserReportNote(id: id, content: content, source: source, createdAt: Date())
    }

    // MARK: - Dominio

    func testCoachNotesExcludeTheUsersOwn() {
        let report = UserReport(
            content: "Lesión de hombro",
            notes: [note(1, "del coach", .coach), note(2, "mía", .user)]
        )
        XCTAssertEqual(report.coachNotes.map(\.id), [1], "solo las del coach van aparte")
        XCTAssertFalse(report.isEmpty)
    }

    func testEmptyReportIgnoresWhitespace() {
        XCTAssertTrue(UserReport(content: "   \n  ").isEmpty)
        XCTAssertFalse(UserReport(content: "", notes: [note(1, "x", .coach)]).isEmpty)
    }

    // MARK: - Use case

    func testContentIsTrimmedAndCappedToTheBackendLimit() async throws {
        let repository = FakeRepository()
        let useCase = UserReportUseCase(repository: repository)

        _ = try await useCase.save(content: "  con espacios  ")
        XCTAssertEqual(repository.savedContent, "con espacios")

        let long = String(repeating: "a", count: UserReportUseCase.maxContentLength + 500)
        _ = try await useCase.save(content: long)
        XCTAssertEqual(
            repository.savedContent?.count, UserReportUseCase.maxContentLength,
            "recortar aquí evita el 422 del backend"
        )
    }

    func testDeleteNoteReachesTheRepository() async throws {
        let repository = FakeRepository()
        repository.report = UserReport(notes: [note(7, "borrable", .coach)])
        let useCase = UserReportUseCase(repository: repository)

        try await useCase.deleteNote(id: 7)
        XCTAssertEqual(repository.deletedIds, [7])
    }

    // MARK: - ViewModel

    @MainActor
    func testUnsavedChangesTrackTheServerCopy() async throws {
        let repository = FakeRepository()
        repository.report = UserReport(content: "original")
        let viewModel = UserReportViewModel(useCase: UserReportUseCase(repository: repository))

        viewModel.load()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(viewModel.uiState.content, "original")
        XCTAssertFalse(viewModel.uiState.hasUnsavedChanges)

        viewModel.uiState.content = "editado"
        XCTAssertTrue(viewModel.uiState.hasUnsavedChanges, "el botón de guardar debe aparecer")

        viewModel.save()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(viewModel.uiState.hasUnsavedChanges, "tras guardar ya no hay cambios")
        XCTAssertNotNil(viewModel.uiState.savedMessage)
    }

    @MainActor
    func testGuestSeesTheAccountMessageInsteadOfAnError() async throws {
        let repository = FakeRepository()
        repository.errorToThrow = DomainError.notAuthorized
        let viewModel = UserReportViewModel(useCase: UserReportUseCase(repository: repository))

        viewModel.load()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(viewModel.uiState.requiresAccount)
        XCTAssertNil(viewModel.uiState.error, "no es un error que haya que enseñar como fallo")
    }

    @MainActor
    func testAFailedNoteDeletionIsRolledBack() async throws {
        let repository = FakeRepository()
        repository.report = UserReport(notes: [note(1, "una", .coach), note(2, "otra", .coach)])
        let viewModel = UserReportViewModel(useCase: UserReportUseCase(repository: repository))
        viewModel.load()
        try await Task.sleep(nanoseconds: 200_000_000)

        repository.errorToThrow = DomainError.network(underlying: URLError(.timedOut))
        viewModel.deleteNote(note(1, "una", .coach))
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(
            viewModel.uiState.coachNotes.count, 2,
            "si el servidor falla, la nota vuelve a la lista"
        )
        XCTAssertNotNil(viewModel.uiState.error)
    }

    // MARK: - Contrato de red

    func testDTOMapsTheBackendPayload() throws {
        let json = """
        {
          "content": "Entreno a las 6:00",
          "updated_at": "2026-08-06T09:15:30.123456+00:00",
          "notes": [
            {"id": 3, "content": "Le cuesta la proteína", "source": "coach",
             "topic": "nutricion", "created_at": "2026-08-01T10:00:00+00:00"},
            {"id": 5, "content": "Le molesta el hombro", "source": "coach",
             "topic": "entreno", "created_at": "2026-08-03T10:00:00+00:00"},
            {"id": 4, "content": "Suya", "source": "user",
             "topic": null, "created_at": "2026-08-02T10:00:00+00:00"}
          ]
        }
        """.data(using: .utf8)!

        let dto = try UserReportRemoteDataSource.decoder.decode(UserReportApiDTO.self, from: json)
        let report = dto.toDomain()

        XCTAssertEqual(report.content, "Entreno a las 6:00")
        XCTAssertNotNil(report.updatedAt, "el backend manda microsegundos y hay que aceptarlos")
        XCTAssertEqual(report.notes.count, 3)
        XCTAssertEqual(report.coachNotes.map(\.id), [3, 5])
        // El backend escribe ÁREAS (`nutricion`, `entreno`), no temas del coach.
        // Este test decía `"topic": "nutrition"` y lo leía como `AICoachTopic`, que es
        // justo la suposición equivocada que dejó pasar el bug: de las seis áreas solo
        // `plan` coincidía por casualidad, y las otras cinco llegaban a `nil`, así que
        // la nota salía sin etiqueta en el perfil.
        XCTAssertEqual(report.coachNotes.map(\.area), [.nutricion, .entreno])
    }

    /// Un área que iOS no conozca no puede tumbar el informe entero: se pierde la
    /// etiqueta, se conserva la nota.
    func testAnUnknownAreaLeavesTheNoteWithoutALabel() throws {
        let json = """
        {
          "content": "",
          "updated_at": null,
          "notes": [
            {"id": 9, "content": "Algo nuevo", "source": "coach",
             "topic": "area_que_no_existe", "created_at": "2026-08-01T10:00:00+00:00"}
          ]
        }
        """.data(using: .utf8)!

        let report = try UserReportRemoteDataSource.decoder
            .decode(UserReportApiDTO.self, from: json).toDomain()

        XCTAssertEqual(report.coachNotes.count, 1, "la nota se conserva")
        XCTAssertNil(report.coachNotes.first?.area)
    }
}
