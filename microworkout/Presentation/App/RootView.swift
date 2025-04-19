//
//  RootView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 11/2/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State var navigator: NavigatorProtocol
    let rootTransition: AnyTransition = .opacity

    public init(navigator: NavigatorProtocol = Navigator.shared, root: any View) {
        self._navigator = State(initialValue: navigator)
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
        .fullScreenCover(isPresented: .constant(appState.isWorkoutScreen)) {
            if let training = appState.currentTraining {
                CurrentTrainingBuilder().build(appState: appState)
            }
        }
    }
}


#Preview {
    RootView(root: EmptyView())
}
