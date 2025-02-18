//
//  RootView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 11/2/25.
//

import SwiftUI

struct RootView: View {
    @State var navigator: NavigatorProtocol
    let rootTransition: AnyTransition = .opacity

    public init(navigator: NavigatorProtocol = Navigator.shared, root: any View) {
        self.navigator = navigator
        navigator.initialize(root: root)
    }

    public var body: some View {
        ZStack {
            if let root = navigator.root {
                StackView(root: {
                    root
                })
                .navigationBarBackButtonHidden(false)
                .tint(.black)
            }
        }
    }
}

#Preview {
    RootView(root: EmptyView())
}
