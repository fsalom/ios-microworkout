import SwiftUI

/// El plan semanal: qué sesión toca cada día, de lunes a domingo.
///
/// Cada día distingue tres estados que al coach le cuentan cosas distintas:
/// una sesión asignada (entrenas), "descanso" (decidiste no entrenar) y sin
/// decidir (no hay plan). Por eso hay opción explícita de descanso en vez de
/// tratar la ausencia como tal.
struct WeeklyPlanView: View {
    @StateObject var viewModel: WeeklyPlanViewModel

    var body: some View {
        Form {
            if !viewModel.uiState.hasSessions && !viewModel.uiState.isLoading {
                noSessionsSection
            }

            daysSection
            nameSection

            if let error = viewModel.uiState.error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundColor(.orange)
                }
            }
        }
        .navigationTitle("Plan semanal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }

    // MARK: - Secciones

    private var daysSection: some View {
        Section {
            ForEach(viewModel.uiState.days) { day in
                dayRow(day)
            }
        } footer: {
            if viewModel.uiState.trainingDayCount > 0 {
                Text("\(viewModel.uiState.trainingDayCount) días de entreno a la semana. El coach lo tiene en cuenta al valorar tu semana.")
            } else {
                Text("Asigna una sesión a los días que entrenas y marca como descanso los que no. El coach lo usa para saber qué te toca cada día.")
            }
        }
    }

    private func dayRow(_ day: WeeklyPlanDayRow) -> some View {
        Menu {
            ForEach(viewModel.uiState.sessions) { session in
                Button(session.name) {
                    viewModel.assign(sessionId: session.id, to: day.weekday)
                }
            }
            Button("Descanso") {
                viewModel.assign(sessionId: nil, to: day.weekday)
            }
            if day.sessionId != nil || day.isRest {
                Button("Sin decidir", role: .destructive) {
                    viewModel.clear(weekday: day.weekday)
                }
            }
        } label: {
            HStack {
                Text(day.weekdayName)
                    .foregroundColor(.primary)
                Spacer()
                statusLabel(day)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func statusLabel(_ day: WeeklyPlanDayRow) -> some View {
        if day.isMissingSession {
            Label("Sesión eliminada", systemImage: "exclamationmark.triangle")
                .font(.subheadline)
                .foregroundColor(.orange)
        } else if let name = day.sessionName {
            Text(name)
                .font(.subheadline)
                .foregroundColor(.accentColor)
        } else if day.isRest {
            Text("Descanso")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else {
            Text("Sin decidir")
                .font(.subheadline)
                .foregroundColor(Color(.tertiaryLabel))
        }
    }

    private var noSessionsSection: some View {
        Section {
            Label(
                "Todavía no tienes sesiones creadas. Crea una en Sesiones y podrás asignarla a los días de la semana.",
                systemImage: "info.circle"
            )
            .font(.footnote)
            .foregroundColor(.secondary)
        }
    }

    private var nameSection: some View {
        Section("Nombre del plan (opcional)") {
            TextField(
                "Fuerza 4 días",
                text: Binding(
                    get: { viewModel.uiState.planName },
                    set: { viewModel.uiState.planName = $0 }
                )
            )
            .onSubmit { viewModel.setPlanName(viewModel.uiState.planName) }
            .submitLabel(.done)
        }
    }
}
