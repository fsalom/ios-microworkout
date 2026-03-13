import SwiftUI

struct SwitcherView: View {
    @EnvironmentObject var appState: AppState
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    var body: some View {
        switch appState.screen {
        case .home:
            TabView {
                HomeBuilder(component: component).build(appState: appState)
                    .navigationTitle("Inicio")
                    .tabItem {
                        Image(systemName: "house.circle.fill")
                    }
                CurrentSessionBuilder(component: component).build()
                    .navigationTitle("Entrenamiento")
                    .tabItem {
                        Image(systemName: "figure.strengthtraining.traditional.circle.fill")
                    }
                MealsBuilder(component: component).build()
                    .navigationTitle("Comidas")
                    .tabItem {
                        Image(systemName: "fork.knife.circle.fill")
                    }
                ProfileBuilder(component: component).build()
                    .navigationTitle("Perfil")
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                    }
            }
        case .onboarding:
            OnboardingBuilder(component: component).build(appState: appState)
        case .workout, .loading:
            ProgressView()
        }
    }
}

#Preview {
    SwitcherView(component: TestAppComponent())
}
