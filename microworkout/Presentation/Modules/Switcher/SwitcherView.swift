import SwiftUI

struct SwitcherView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.screen {
        case .home:
            TabView {
                HomeBuilder().build(appState: appState)
                    .navigationTitle("Inicio")
                    .tabItem {
                        Image(systemName: "house.circle.fill")
                    }
                CurrentSessionBuilder().build()
                    .navigationTitle("Entrenamiento")
                    .tabItem {
                        Image(systemName: "figure.strengthtraining.traditional.circle.fill")
                    }
                ProfileBuilder().build()
                    .navigationTitle("Perfil")
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                    }
            }
        case .workout, .loading:
            ProgressView()
        }
    }
}

#Preview {
    SwitcherView()
}
