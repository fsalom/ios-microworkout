//
//  RirView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 16/7/23.
//

import SwiftUI

struct RpeView: View {
    var rpe: Float
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(getColor(of: rpe))
                .opacity(0.5)

            RoundedRectangle(cornerRadius: 10)
                .fill(getColor(of: rpe))
                .frame(width: CGFloat(rpe) * 10)
            Text(rpe.formatted)
                .font(.footnote)
                .fontWeight(.bold)
                .frame(width: 28)
                .contentMargins(10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(10)
        }.frame(width: 100, height: 30)
            .cornerRadius(10)

    }

    func getColor(of rpe: Float) -> Color {
        switch rpe {
        case 0...4: return .white
        case 4...6: return .green
        case 6...8.5: return .orange
        case 8.5...10: return .red
        default:
            return .gray
        }
    }
}

#Preview {
    RpeView(rpe: 6.5)
}
