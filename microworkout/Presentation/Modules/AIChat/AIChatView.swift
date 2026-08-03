import SwiftUI

struct AIChatView: View {
    @StateObject var viewModel: AIChatViewModel
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messagesList

            if let error = viewModel.uiState.error {
                errorBanner(error)
            }

            InputBar(
                text: Binding(
                    get: { viewModel.uiState.input },
                    set: { viewModel.uiState.input = $0 }
                ),
                isFocused: $inputFocused,
                canSend: viewModel.uiState.canSend,
                isStreaming: viewModel.uiState.isStreaming,
                onSend: { viewModel.send() },
                onStop: { viewModel.stopStreaming() }
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
                    ForEach(viewModel.uiState.messages) { message in
                        MessageBubble(
                            message: message,
                            isStreaming: viewModel.uiState.isStreaming
                                && message.id == viewModel.uiState.messages.last?.id
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            // El contador de mensajes no cambia mientras llega el streaming, así que
            // hay que seguir también el texto del último para no dejar de bajar.
            .onChange(of: viewModel.uiState.messages.last?.text) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.uiState.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = viewModel.uiState.messages.last else { return }
        withAnimation(.easeOut(duration: 0.15)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Reintentar") { viewModel.retryLast() }
                .font(.footnote.weight(.semibold))
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
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
    let isStreaming: Bool

    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .user { Spacer(minLength: 40) }

            Group {
                if message.text.isEmpty && isStreaming {
                    TypingIndicator()
                } else {
                    // El coach responde en markdown (títulos `##`, viñetas), así que
                    // `Text` a secas dejaría los `##` a la vista.
                    MarkdownText(raw: message.text)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(bubbleColor)
            )
            .foregroundColor(textColor)

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

/// Render mínimo del markdown que produce el coach: encabezados `##`, viñetas y
/// el resto como párrafo (con el markdown en línea que ya entiende `Text`).
private struct MarkdownText: View {
    let raw: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                switch line.kind {
                case .heading:
                    Text(line.text)
                        .font(.subheadline.weight(.bold))
                        .padding(.top, 2)
                case .bullet:
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                        Text(inline(line.text))
                    }
                    .font(.subheadline)
                case .paragraph:
                    Text(inline(line.text))
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    private func inline(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }

    private struct Line {
        enum Kind { case heading, bullet, paragraph }
        let kind: Kind
        let text: String
    }

    private var lines: [Line] {
        raw.components(separatedBy: .newlines).compactMap { rawLine in
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            if trimmed.hasPrefix("#") {
                let title = trimmed.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
                return Line(kind: .heading, text: title)
            }
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                return Line(kind: .bullet, text: String(trimmed.dropFirst(2)))
            }
            return Line(kind: .paragraph, text: trimmed)
        }
    }
}

private struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary.opacity(phase == index ? 0.9 : 0.3))
                    .frame(width: 6, height: 6)
            }
        }
        .task {
            // Sin `Timer`: la vista desaparece en cuanto llega el primer chunk.
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 350_000_000)
                phase = (phase + 1) % 3
            }
        }
    }
}

private struct InputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let canSend: Bool
    let isStreaming: Bool
    let onSend: () -> Void
    let onStop: () -> Void

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
                    .disabled(isStreaming)

                if isStreaming {
                    Button(action: onStop) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.orange)
                    }
                    .accessibilityLabel("Detener respuesta")
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(canSend ? .orange : Color(.systemGray3))
                    }
                    .disabled(!canSend)
                    .accessibilityLabel("Enviar")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
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
