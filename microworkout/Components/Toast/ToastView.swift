//
//  ToastView.swift
//  CucharaDePlata
//
//  Created by Adrián Prieto Villena on 21/1/25.
//

import SwiftUI

struct ToastView: View {
    var message: LocalizedStringKey
    var isUndoButtonActive = false
    var isCloseButtonActive = false
    var textAlingment: Alignment = .leading
    var textHorizontalPadding: CGFloat = 16
    var textVerticalPadding: CGFloat = 16
    var componentHorizontalPadding: CGFloat = 12
    var componentVerticalPadding: CGFloat = 12
    var color: Color = .black
    var closeAction: () -> Void = {}
    var undo: () -> Void = {}
    var heigth: Double = 54
    var paddingButton: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(message)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: textAlingment)

                if isUndoButtonActive {
                    Button(action: {
                        undo()
                    }) {
                        Text("undo")
                            .underline()
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                    }
                }

                if isCloseButtonActive {
                    Button(action: {
                        closeAction()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, textHorizontalPadding)
            .padding(.vertical, textVerticalPadding)
        }
        .frame(maxWidth: .infinity)
        .frame(height: heigth)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.95))
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .padding(.horizontal, componentHorizontalPadding)
        .padding(.vertical, componentVerticalPadding)
        .padding(.bottom, paddingButton)
    }
}
