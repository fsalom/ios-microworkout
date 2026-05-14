import SwiftUI

/// Cabecera unificada para las tabs principales.
/// Subtítulo en mayúsculas + título grande + acción opcional a la derecha.
struct TabHeader: View {
    let subtitle: String
    let title: String
    var action: Action? = nil

    struct Action {
        let icon: String
        let color: Color
        let perform: () -> Void

        init(icon: String, color: Color = .accentColor, perform: @escaping () -> Void) {
            self.icon = icon
            self.color = color
            self.perform = perform
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            Spacer(minLength: 0)
            if let action {
                Button(action: action.perform) {
                    Image(systemName: action.icon)
                        .font(.title)
                        .foregroundColor(action.color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.icon)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

extension View {
    /// Pins a `TabHeader` to the top of the view as a translucent safe-area inset.
    /// The header stays in place when the underlying scroll moves, and the material
    /// covers the status bar area so content blurs behind it.
    func pinnedTabHeader(
        subtitle: String,
        title: String,
        action: TabHeader.Action? = nil
    ) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            TabHeader(subtitle: subtitle, title: title, action: action)
                .background(.bar)
        }
    }
}
