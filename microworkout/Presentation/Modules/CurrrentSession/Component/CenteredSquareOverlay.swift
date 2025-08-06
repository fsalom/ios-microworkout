//
//  CenteredSquareOverlay.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/8/25.
//

import SwiftUI

struct CenteredSquareOverlay<Content: View>: View {
    let size: CGFloat
    let content: Content

    init(size: CGFloat = 200, @ViewBuilder content: () -> Content) {
        self.size = size
        self.content = content()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.gray))
                .frame(width: size, height: size)
                .overlay(
                    content
                )
    }
}
