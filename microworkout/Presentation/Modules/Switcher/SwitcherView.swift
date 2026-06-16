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
            tabs
        case .onboarding:
            OnboardingBuilder(component: component).build(appState: appState)
        case .workout, .loading:
            ProgressView()
        }
    }

    @ViewBuilder
    private var tabs: some View {
        let tabView = TabView(selection: $appState.selectedTab) {
            Tab("Inicio", systemImage: "house.fill", value: 0) {
                HomeBuilder(component: component).build(appState: appState)
            }
            Tab("Ejercicios", systemImage: "dumbbell.fill", value: 1) {
                ExerciseTabBuilder(component: component).build()
            }
            Tab("Entrenos", systemImage: "figure.strengthtraining.traditional", value: 2) {
                WorkoutHistoryBuilder(component: component).build()
            }
            Tab("Comidas", systemImage: "fork.knife", value: 3) {
                MealsBuilder(component: component).build()
            }
            Tab("Perfil", systemImage: "person.crop.circle.fill", value: 4) {
                ProfileBuilder(component: component).build()
            }
        }

        if #available(iOS 26.0, *) {
            tabView.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            tabView
        }
    }
}

#Preview {
    SwitcherView(component: DefaultAppComponent.preview)
}
