import SwiftUI

struct WorkoutHistoryView: View {
    @StateObject var viewModel: WorkoutHistoryViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Header(onCreate: { viewModel.goToNewSession() })
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                content
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.hidden)
        .onAppear { viewModel.load() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { viewModel.load() }
        }
        .onChange(of: appState.selectedTab) { _, newTab in
            if newTab == 2 { viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            CurrentSessionAccessCard(onTap: { viewModel.goToCurrentSession() })

            sessionsSection
        }
    }

    @ViewBuilder
    private var sessionsSection: some View {
        Text("Sesiones")
            .font(.headline)
            .padding(.top, 4)

        if viewModel.uiState.sessions.isEmpty {
            EmptySessionsState(onCreate: { viewModel.goToNewSession() })
        } else {
            ForEach(viewModel.uiState.sessions) { session in
                Button(action: { viewModel.startNewLog(from: session) }) {
                    SessionCard(session: session)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(action: { viewModel.startNewLog(from: session) }) {
                        Label("Empezar entrenamiento", systemImage: "play.fill")
                    }
                    Button(action: { viewModel.editSession(session) }) {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { viewModel.deleteSession(session) }) {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
        }
    }

}

private struct Header: View {
    let onCreate: () -> Void

    private var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date()).uppercased()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1)
                Text("Entrenamientos")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            Spacer()
            Button(action: onCreate) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CurrentSessionAccessCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.orange)
                    .frame(width: 44, height: 44)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Registro rápido")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Buscar ejercicios y registrar sin sesión")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SessionCard: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 40, height: 40)
                .background(Color.green.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(exercisesLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .contentShape(Rectangle())
    }

    private var exercisesLabel: String {
        let count = session.exercises.count
        return "\(count) " + (count == 1 ? "ejercicio" : "ejercicios")
    }
}

private struct EmptySessionsState: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("No tienes sesiones creadas")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button(action: onCreate) {
                Label("Crear sesión", systemImage: "plus.circle.fill")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

