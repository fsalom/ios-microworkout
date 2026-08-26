import SwiftUI

/// Card oscura con acento naranja que muestra un insight del coach IA dentro de
/// las pestañas de la app. Incluye un botón "Abrir en chat" que pasa el `prompt`
/// del insight como mensaje inicial.
struct CoachInsightCard: View {
    let insight: CoachInsight?
    let isLoading: Bool
    let onOpenChat: (String) -> Void
    /// Se invoca al confirmar una acción propuesta. `nil` en las pantallas que aún
    /// no saben ejecutarlas: entonces la tarjeta no las pinta.
    var onApplyAction: ((CoachAction) -> Void)? = nil
    /// Pulgar arriba/abajo del usuario sobre la tarjeta (`helpful`, `motivo?`).
    /// `nil` = la pantalla no recoge valoraciones y los pulgares no se pintan.
    var onFeedback: ((Bool, String?) -> Void)? = nil

    /// Acción pendiente de confirmar. El coach propone, el usuario decide: aplicar
    /// algo de un solo toque, con macros que ha estimado un modelo, sería registrar
    /// comida en su nombre sin que lo haya visto.
    @State private var pendingAction: CoachAction?
    @State private var appliedActionIds: Set<String> = []
    /// Ya valoró esta tarjeta: los pulgares se sustituyen por un "gracias".
    @State private var feedbackSent = false
    @State private var isAskingReason = false
    @State private var reasonText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let insight = insight {
                Text(insight.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !insight.body.isEmpty {
                    Text(insight.body)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !insight.bullets.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(insight.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundColor(.orange)
                                    .padding(.top, 7)
                                Text(bullet)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }

                if !insight.isFromModel {
                    Text("Cálculo local — inicia sesión o revisa la conexión para el análisis completo")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let onApplyAction, !insight.actions.isEmpty {
                    actionButtons(insight.actions, onApply: onApplyAction)
                }

                HStack(alignment: .center) {
                    openChatButton(prompt: insight.prompt)
                    // Solo se valora lo que dijo el modelo: el cálculo local no
                    // tiene a quién enseñar.
                    if onFeedback != nil, insight.isFromModel {
                        Spacer()
                        feedbackButtons
                    }
                }
            } else if isLoading {
                Text("Preparando análisis…")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Text("Sin datos suficientes todavía")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var feedbackButtons: some View {
        if feedbackSent {
            Text("Gracias")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        } else {
            HStack(spacing: 14) {
                Button {
                    feedbackSent = true
                    onFeedback?(true, nil)
                } label: {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.55))
                }
                Button {
                    reasonText = ""
                    isAskingReason = true
                } label: {
                    Image(systemName: "hand.thumbsdown")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .buttonStyle(.plain)
            .alert("¿Qué no te ha servido?", isPresented: $isAskingReason) {
                TextField("Opcional", text: $reasonText)
                Button("Enviar") {
                    feedbackSent = true
                    let reason = reasonText.trimmingCharacters(in: .whitespacesAndNewlines)
                    onFeedback?(false, reason.isEmpty ? nil : reason)
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Ayuda al coach a afinar los próximos consejos.")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            Text("Coach IA")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .tracking(0.5)
            Spacer()
            if let insight = insight {
                Text(insight.topic.shortLabel)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    /// Los botones de acción van ANTES del de chat y con menos peso visual: son un
    /// atajo, no la salida principal de la tarjeta.
    private func actionButtons(
        _ actions: [CoachAction],
        onApply: @escaping (CoachAction) -> Void
    ) -> some View {
        VStack(spacing: 8) {
            ForEach(actions) { action in
                let isApplied = appliedActionIds.contains(action.id)
                Button {
                    pendingAction = action
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isApplied ? "checkmark" : "plus.circle.fill")
                            .font(.caption)
                        Text(isApplied ? "Añadido" : action.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(isApplied ? 0.06 : 0.12))
                    .foregroundColor(isApplied ? .white.opacity(0.5) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(isApplied)
            }
        }
        // Confirmación explícita: los macros los ha estimado un modelo y esto escribe
        // en el diario del usuario.
        .confirmationDialog(
            pendingAction?.label ?? "",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingAction {
                Button("Añadir a mi diario") {
                    appliedActionIds.insert(action.id)
                    onApply(action)
                    pendingAction = nil
                }
                Button("Cancelar", role: .cancel) { pendingAction = nil }
            }
        } message: {
            Text("Lo estima el coach a partir de tus datos; revísalo si no te cuadra.")
        }
    }

    private func openChatButton(prompt: String) -> some View {
        Button(action: { onOpenChat(prompt) }) {
            HStack(spacing: 6) {
                Text("Continuar en chat")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Image(systemName: "arrow.up.right")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.orange)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
