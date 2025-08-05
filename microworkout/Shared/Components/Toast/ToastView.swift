//
//  ToastView.swift
//  Gula
//
//  Created by María on 28/8/24.
//

import SwiftUI

struct ToastView: View {
    @Binding var isVisible: Bool
    var message: LocalizedStringKey
    var isButtonActive = false
    var isCloseButtonActive = false
    var textAlingment: Alignment = .center
    var textHorizontalPadding: CGFloat = 16
    var textVerticalPadding: CGFloat = 16
    var componentHorizontalPadding: CGFloat = 12
    var componentVerticalPadding: CGFloat = 12
    var closeAction: () -> Void = {}
    var undo: () -> Void = {}

    var body: some View {
        if isVisible {
            VStack(alignment: .leading) {
                HStack {
                    Text(message)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: textAlingment)

                    if isButtonActive {
                        Button(action: {
                            undo()
                            withAnimation {
                                isVisible = false
                            }
                        }, label: {
                            Text("common_undo")
                                .underline()
                                .foregroundColor(.white)
                                .font(.system(size: 13))
                        })
                    }
                    if isCloseButtonActive {
                        Button(action: {
                                   withAnimation {
                                       isVisible = false
                                   }
                               },
                               label: {
                                   Image(systemName: "xmark")
                                       .foregroundColor(.white)
                               })
                    }
                }
                .padding(.horizontal, textHorizontalPadding)
                .padding(.vertical, textVerticalPadding)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.95)))
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding(.horizontal, componentHorizontalPadding)
            .padding(.vertical, componentVerticalPadding)
        }
    }
}
