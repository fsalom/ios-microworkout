//
//  StepperInputView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 19/7/25.
//

import SwiftUI

struct StepperInputView: View {
    var label: String
    @Binding var value: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button(action: {
                    if let currentValue = value {
                        value = max(0, currentValue - 1)
                    } else {
                        value = 0
                    }
                }) {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                }

                TextField(label, value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Button(action: {
                    if let currentValue = value {
                        value = currentValue + 1
                    } else {
                        value = 1
                    }
                }) {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                }
            }
            .padding(4)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(4)
    }
}
