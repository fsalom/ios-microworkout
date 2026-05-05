import SwiftUI

struct AIChatView: View {
    @StateObject var viewModel: AIChatViewModel
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messagesList

            InputBar(
                text: Binding(
                    get: { viewModel.uiState.input },
                    set: { viewModel.uiState.input = $0 }
                ),
                isFocused: $inputFocused,
                onSend: { viewModel.send() }
            )
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Asistente IA")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.openContextSheet() }) {
                    Image(systemName: "doc.text.magnifyingglass")
                }
            }
        }
        .onAppear { viewModel.prepareContext() }
        .sheet(isPresented: contextSheetBinding) {
            ContextSheet(
                summary: viewModel.uiState.contextSummary,
                json: viewModel.uiState.contextJSON
            )
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.uiState.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.uiState.messages.count) { _, _ in
                if let last = viewModel.uiState.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var contextSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.uiState.isContextSheetVisible },
            set: { if !$0 { viewModel.closeContextSheet() } }
        )
    }
}

private struct MessageBubble: View {
    let message: AIChatMessage

    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .user { Spacer(minLength: 40) }

            Text(message.text)
                .font(.subheadline)
                .foregroundColor(textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(bubbleColor)
                )

            if message.role != .user { Spacer(minLength: 40) }
        }
    }

    private var bubbleColor: Color {
        switch message.role {
        case .user: return .orange
        case .assistant: return Color(.secondarySystemGroupedBackground)
        case .system: return Color(.systemGray5)
        }
    }

    private var textColor: Color {
        message.role == .user ? .white : .primary
    }
}

private struct InputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Escribe un mensaje…", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemGray6))
                    )
                    .focused(isFocused)

                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(canSend ? .orange : Color(.systemGray3))
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct ContextSheet: View {
    let summary: String
    let json: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Resumen")
                                .font(.headline)
                            Text(summary)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("JSON completo")
                                .font(.headline)
                            Spacer()
                            Button(action: { UIPasteboard.general.string = json }) {
                                Label("Copiar", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                        }
                        Text(json.isEmpty ? "(vacío)" : json)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                            .textSelection(.enabled)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Datos para la IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
