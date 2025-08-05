//
//  CustomButton.swift
//  Gula
//
//  Created by Jorge Planells Zamora on 4/7/24.
//

import SwiftUI

enum ButtonType {
    case primary
    case secondary
    case tertiary

    var background: Color {
        switch self {
        case .primary:
            Color.black
        case .secondary:
            Color.gray
        case .tertiary:
            Color.gray
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary:
            Color.white
        case .secondary:
            Color.black
        case .tertiary:
            Color.white
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .primary:
            0
        case .secondary:
            0
        case .tertiary:
            0
        }
    }
}

enum ButtonState {
    case loading
    case disabled
    case normal
    case hide

    var opacity: CGFloat {
        switch self {
        case .loading, .normal:
            1
        case .disabled:
            0.25
        case .hide:
            0
        }
    }
}

struct CustomButton: View {
    @Binding var buttonState: ButtonState
    let type: ButtonType
    let height: CGFloat = 48
    let buttonText: LocalizedStringKey
    var backgroundColor: Color?
    var foregroundColor: Color?
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            switch buttonState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            default:
                Text(buttonText)
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .background(
                        (backgroundColor ?? type.background)
                            .opacity(buttonState.opacity)
                    )
                    .foregroundColor(foregroundColor ?? type.foregroundColor.opacity(type == .primary ? 1 : buttonState.opacity))
                    .foregroundStyle(type.foregroundColor.opacity(type == .primary ? 1 : buttonState.opacity))
            }
        }
        .disabled(buttonState == .disabled)
        .cornerRadius(6)
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(buttonState.opacity), lineWidth: type.borderWidth)
        }
    }
}
