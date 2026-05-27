import SwiftUI

struct SetTagBadge: View {
    let tag: SetTag

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: tag.symbol)
                .font(.system(size: 9, weight: .bold))
            Text(tag.shortLabel)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(tag.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(tag.color.opacity(0.18)))
        .overlay(Capsule().strokeBorder(tag.color.opacity(0.5), lineWidth: 0.8))
    }
}
