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
    private let component: AppComponentProtocol
    let rootTransition: AnyTransition = .opacity

    public init(navigator: NavigatorProtocol = Navigator.shared, root: any View, component: AppComponentProtocol) {
        self._navigator = State(initialValue: navigator)
        self.component = component
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
            if let _ = appState.currentTraining {
                CurrentTrainingBuilder(component: component).build(appState: appState)
            }
        }
    }
}


#Preview {
    RootView(root: EmptyView())
}
