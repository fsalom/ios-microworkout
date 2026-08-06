import SwiftUI

/// Pantalla del informe: lo que el usuario quiere que el coach sepa, y lo que el
/// coach ha ido anotando por su cuenta (separado y borrable, porque son
/// conclusiones de la IA, no hechos que haya dicho el usuario).
struct UserReportView: View {
    @StateObject var viewModel: UserReportViewModel
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        Form {
            if viewModel.uiState.requiresAccount {
                accountRequiredSection
            } else {
                yourContextSection
                if !viewModel.uiState.coachNotes.isEmpty { coachNotesSection }
            }

            if let error = viewModel.uiState.error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundColor(.orange)
                }
            }
        }
        .navigationTitle("Informe para el coach")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.uiState.isSaving {
                    ProgressView()
                } else if viewModel.uiState.hasUnsavedChanges {
                    Button("Guardar") {
                        isEditorFocused = false
                        viewModel.save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear { viewModel.load() }
    }

    // MARK: - Secciones

    private var yourContextSection: some View {
        Section {
            ZStack(alignment: .topLeading) {
                if viewModel.uiState.content.isEmpty {
                    Text(Self.placeholder)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(
                    text: Binding(
                        get: { viewModel.uiState.content },
                        set: { viewModel.uiState.content = $0 }
                    )
                )
                .frame(minHeight: 160)
                .focused($isEditorFocused)
                .scrollContentBackground(.hidden)
            }
        } header: {
            Text("Lo que quieres que sepa")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lesiones, horarios, viajes, alimentos que no tomas, lo que te motiva… Va en todas las conversaciones con el coach.")
                if viewModel.uiState.remainingCharacters < 400 {
                    Text("\(max(0, viewModel.uiState.remainingCharacters)) caracteres restantes")
                        .foregroundColor(viewModel.uiState.remainingCharacters <= 0 ? .orange : .secondary)
                }
                if let saved = viewModel.uiState.savedMessage {
                    Label(saved, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .font(.footnote)
        }
    }

    private var coachNotesSection: some View {
        Section {
            ForEach(viewModel.uiState.coachNotes) { note in
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.content)
                        .font(.subheadline)
                    HStack(spacing: 6) {
                        if let topic = note.topic {
                            Text(topic.shortLabel)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        Text(note.createdAt, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        viewModel.deleteNote(note)
                    } label: {
                        Label("Borrar", systemImage: "trash")
                    }
                }
            }
        } header: {
            Text("Lo que ha anotado el coach")
        } footer: {
            Text("Conclusiones que ha sacado de vuestras conversaciones, no cosas que hayas dicho tú. Desliza para borrar la que no te encaje.")
                .font(.footnote)
        }
    }

    private var accountRequiredSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Necesitas iniciar sesión", systemImage: "person.crop.circle.badge.exclamationmark")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("El informe se guarda en tu cuenta porque es el coach quien lo usa, y el coach se ejecuta en el servidor.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private static let placeholder = """
    Ej.: Lesión de hombro derecho desde marzo, evito press militar.
    Entreno a las 6:00 antes de trabajar.
    No como pescado.
    """
}
