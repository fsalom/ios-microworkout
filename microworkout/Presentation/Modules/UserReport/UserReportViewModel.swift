import Foundation
import SwiftUI

struct UserReportUiState {
    var content: String = ""
    var coachNotes: [UserReportNote] = []
    var isLoading: Bool = false
    var isSaving: Bool = false
    var error: String?
    var savedMessage: String?
    var requiresAccount: Bool = false
    /// Texto tal y como está en el servidor, para saber si hay cambios sin guardar.
    private var persistedContent: String = ""

    var hasUnsavedChanges: Bool { content != persistedContent }
    var remainingCharacters: Int { UserReportUseCase.maxContentLength - content.count }

    mutating func apply(_ report: UserReport) {
        content = report.content
        persistedContent = report.content
        coachNotes = report.coachNotes
    }
}

final class UserReportViewModel: ObservableObject {
    @Published var uiState: UserReportUiState = .init()

    private let useCase: UserReportUseCaseProtocol

    init(useCase: UserReportUseCaseProtocol) {
        self.useCase = useCase
    }

    func load() {
        guard !uiState.isLoading else { return }
        uiState.isLoading = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let report = try await self.useCase.getReport()
                self.uiState.apply(report)
                self.uiState.error = nil
                self.uiState.requiresAccount = false
            } catch {
                self.handle(error)
            }
            self.uiState.isLoading = false
        }
    }

    func save() {
        guard !uiState.isSaving else { return }
        uiState.isSaving = true
        uiState.savedMessage = nil
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let report = try await self.useCase.save(content: self.uiState.content)
                self.uiState.apply(report)
                self.uiState.error = nil
                self.uiState.savedMessage = "Guardado. El coach lo tendrá en cuenta."
            } catch {
                self.handle(error)
            }
            self.uiState.isSaving = false
        }
    }

    func deleteNote(_ note: UserReportNote) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            // Se quita ya de la lista: el borrado es local a su informe y esperar al
            // servidor para reflejarlo hace que parezca que el botón no responde.
            let previous = self.uiState.coachNotes
            self.uiState.coachNotes.removeAll { $0.id == note.id }
            do {
                try await self.useCase.deleteNote(id: note.id)
            } catch {
                self.uiState.coachNotes = previous
                self.handle(error)
            }
        }
    }

    @MainActor
    private func handle(_ error: Error) {
        if case DomainError.notAuthorized = error {
            uiState.requiresAccount = true
            uiState.error = nil
            return
        }
        uiState.error = (error as? LocalizedError)?.errorDescription
            ?? "No se pudo cargar el informe."
    }
}
