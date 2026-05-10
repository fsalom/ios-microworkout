import SwiftUI

/// Card oscura con acento naranja que muestra un insight del coach IA dentro de
/// las pestañas de la app. Incluye un botón "Abrir en chat" que pasa el `prompt`
/// del insight como mensaje inicial.
struct CoachInsightCard: View {
    let insight: CoachInsight?
    let isLoading: Bool
    let onOpenChat: (String) -> Void

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

                openChatButton(prompt: insight.prompt)
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
                Text(kindLabel(insight.kind))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
            }
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

    private func kindLabel(_ kind: CoachInsight.Kind) -> String {
        switch kind {
        case .workout: return "PROGRESIÓN"
        case .nutrition: return "NUTRICIÓN"
        case .home: return "RESUMEN"
        }
    }
}
