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
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(10)
        }.frame(width: 100, height: 30)
            .cornerRadius(10)

    }

    func getColor(of rpe: Float) -> Color {
        switch rpe {
        case 0...4: return .gray
        case 4...6.5: return .green
        case 6.5...8: return .orange
        case 8...10: return .red
        default:
            return .gray
        }
    }
}


