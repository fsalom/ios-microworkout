//
//  RootView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 11/2/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var authSession = AuthSession.shared
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
                .tint(.green)   // color de marca; legible en claro y oscuro (antes .black, invisible en oscuro)
            }
        }
        .fullScreenCover(isPresented: .constant(appState.isWorkoutScreen)) {
            if let _ = appState.currentTraining {
                CurrentTrainingBuilder(component: component).build(appState: appState)
            }
        }
        .overlay(MediaProcessingBanner())
        .overlay(SyncBanner())
        .onChange(of: authSession.state) { previous, current in
            // Solo un login de verdad (invitado → autenticado) sube los datos
            // locales. Un arranque en frío con sesión guardada pasa de `.unknown`
            // a `.authenticated`, y ahí no toca subir nada: no ha cambiado nada
            // desde la última vez.
            guard case .guest = previous, current.isAuthenticated else { return }
            SyncTracker.shared.syncAfterLogin(using: component.syncLocalDataUseCase)
        }
    }
}


#Preview {
    RootView(root: EmptyView(), component: DefaultAppComponent.preview)
}
