import SwiftUI

struct WorkoutSessionListView: View {
    @StateObject var viewModel: WorkoutSessionListViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if viewModel.uiState.sessions.isEmpty {
                    EmptyState()
                        .padding(.top, 60)
                } else {
                    ForEach(viewModel.uiState.sessions) { session in
                        Button(action: { viewModel.goToEditor(session) }) {
                            SessionRow(session: session)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive, action: { viewModel.delete(session) }) {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sesiones")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.createNew() }) {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                }
            }
        }
        .onAppear { viewModel.load() }
    }
}

private struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.headline)
                Text("\(session.exercises.count) " + (session.exercises.count == 1 ? "ejercicio" : "ejercicios"))
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
    }
}

private struct EmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Sin sesiones")
                .font(.headline)
            Text("Crea tu primera sesión con el botón +")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
