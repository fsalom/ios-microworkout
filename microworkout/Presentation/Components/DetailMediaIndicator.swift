import SwiftUI

/// Indicador compacto del tipo de media asociado a un set: icono play/foto y badge
/// con el número total si hay más de un elemento. El color de acento se pasa por
/// parámetro para que el componente sea independiente del módulo que lo monta.
struct DetailMediaIndicator: View {
    let media: [SetMedia]
    var accentColor: Color = Color(red: 0.30, green: 0.65, blue: 0.95)

    var body: some View {
        if media.isEmpty {
            Color.clear.frame(height: 18)
        } else {
            HStack(spacing: 3) {
                let hasVideo = media.contains { $0.type == .video }
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(accentColor)
                        .frame(width: 16, height: 16)
                    Image(systemName: hasVideo ? "play.fill" : "photo.fill")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                }
                if media.count > 1 {
                    Text("\(media.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)
                        .monospacedDigit()
                }
            }
            .frame(height: 18)
        }
    }
}
