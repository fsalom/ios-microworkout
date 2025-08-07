import SwiftUI

struct DateBadge: View {
    let day: Int
    let monthName: String

    var body: some View {
        VStack(spacing: 2) {
            Text(monthName.prefix(3).capitalized) // "Ago"
                .font(.caption)
                .fontWeight(.semibold)
            Text("\(day)")
                .font(.system(size: 30, weight: .bold))
                .minimumScaleFactor(0.7)
        }
        .padding(6)
        .frame(width: 60, height: 60)
        .background(Color(.white))                       // fondo
        .clipShape(RoundedRectangle(cornerRadius: 8))          // recorte
        .overlay(                                              // borde opcional
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}
