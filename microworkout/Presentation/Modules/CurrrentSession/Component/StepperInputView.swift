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

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            controls
                .padding(4)
                .background(background)
                .overlay(border)
                .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .padding(4)
    }

    private var controls: some View {
        HStack {
            stepperButton(systemImage: "minus", action: decrement)
            field
            stepperButton(systemImage: "plus", action: increment)
        }
    }

    private var field: some View {
        TextField(label, value: $value, format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .focused($isFocused)
            .fontWeight(isFocused ? .bold : .regular)
    }

    private func stepperButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 44, height: 44)
                .foregroundColor(isFocused ? .green : .primary)
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(isFocused ? Color.green.opacity(0.08) : Color.clear)
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(isFocused ? Color.green : Color.gray.opacity(0.4),
                    lineWidth: isFocused ? 1.5 : 1)
    }

    private func decrement() {
        if let currentValue = value {
            value = max(0, currentValue - 1)
        } else {
            value = 0
        }
    }

    private func increment() {
        if let currentValue = value {
            value = currentValue + 1
        } else {
            value = 1
        }
    }
}
