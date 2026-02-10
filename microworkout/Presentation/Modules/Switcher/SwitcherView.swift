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
                MealsBuilder().build()
                    .navigationTitle("Comidas")
                    .tabItem {
                        Image(systemName: "fork.knife.circle.fill")
                    }
                ProfileBuilder().build()
                    .navigationTitle("Perfil")
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                    }
            }
        case .onboarding:
            OnboardingBuilder().build(appState: appState)
        case .workout, .loading:
            ProgressView()
        }
    }
}

#Preview {
    SwitcherView()
}
