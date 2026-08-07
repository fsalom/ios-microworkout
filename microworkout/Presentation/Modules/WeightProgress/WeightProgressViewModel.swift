import Foundation
import SwiftUI

struct WeightProgressUiState {
    var measurements: [DailyMetrics] = []
    var isLoading: Bool = false
    var isSaving: Bool = false
    var error: String?
    /// Rango visible, en días.
    var windowDays: Int = BodyMetricsUseCase.defaultWindowDays

    /// Texto del campo al anotar peso. Se rellena con el último conocido: es lo
    /// que hace que anotar sea un gesto y no volver a teclear 78 desde cero.
    var weightInput: String = ""
    var entryDate: Date = Date()

    var latest: DailyMetrics? { measurements.last(where: { $0.weightKg != nil }) }
    var trend: WeightTrend? { WeightTrend.from(measurements) }
    var hasData: Bool { measurements.contains { $0.weightKg != nil } }

    /// Rango del eje Y con un margen: si va de mínimo a máximo exactos, la línea
    /// toca los bordes y una variación de 300 g parece un desplome.
    var weightRange: ClosedRange<Double>? {
        let weights = measurements.compactMap { $0.weightKg }
        guard let min = weights.min(), let max = weights.max() else { return nil }
        let padding = Swift.max((max - min) * 0.2, 0.5)
        return (min - padding)...(max + padding)
    }
}

final class WeightProgressViewModel: ObservableObject {
    @Published var uiState: WeightProgressUiState = .init()

    private let useCase: BodyMetricsUseCaseProtocol

    init(useCase: BodyMetricsUseCaseProtocol) {
        self.useCase = useCase
    }

    func load() {
        guard !uiState.isLoading else { return }
        uiState.isLoading = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let measurements = try await self.useCase.getRecent(days: self.uiState.windowDays)
                self.uiState.measurements = measurements
                self.uiState.error = nil
                if self.uiState.weightInput.isEmpty, let last = self.uiState.latest?.weightKg {
                    self.uiState.weightInput = Self.format(last)
                }
            } catch {
                self.uiState.error = "No se pudieron cargar los pesos"
            }
            self.uiState.isLoading = false
        }
    }

    func changeWindow(days: Int) {
        uiState.windowDays = days
        load()
    }

    func save() {
        // La coma es lo que teclea cualquiera aquí, y `Double("78,4")` es nil.
        let normalized = uiState.weightInput.replacingOccurrences(of: ",", with: ".")
        guard let kilograms = Double(normalized) else {
            uiState.error = "Escribe un peso válido"
            return
        }
        guard !uiState.isSaving else { return }
        uiState.isSaving = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.saveWeight(kilograms, on: self.uiState.entryDate)
                self.uiState.error = nil
                self.uiState.isSaving = false
                self.load()
            } catch {
                self.uiState.error = "No se pudo guardar (¿está entre 20 y 400 kg?)"
                self.uiState.isSaving = false
            }
        }
    }

    func delete(_ measurement: DailyMetrics) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            // Optimista: la fila desaparece al instante y se restaura si falla.
            let previous = self.uiState.measurements
            self.uiState.measurements.removeAll { $0.date == measurement.date }
            do {
                try await self.useCase.delete(date: measurement.date)
            } catch {
                self.uiState.measurements = previous
                self.uiState.error = "No se pudo borrar"
            }
        }
    }

    static func format(_ kilograms: Double) -> String {
        String(format: "%.1f", kilograms)
    }
}
