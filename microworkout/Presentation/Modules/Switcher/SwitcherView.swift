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
            TabView(selection: $appState.selectedTab) {
                HomeBuilder(component: component).build(appState: appState)
                    .tabItem {
                        Image(systemName: "house.circle.fill")
                    }
                    .tag(0)
                ExerciseTabBuilder(component: component).build()
                    .tabItem {
                        Image(systemName: "dumbbell.fill")
                    }
                    .tag(1)
                WorkoutHistoryBuilder(component: component).build()
                    .tabItem {
                        Image(systemName: "figure.strengthtraining.traditional.circle.fill")
                    }
                    .tag(2)
                MealsBuilder(component: component).build()
                    .tabItem {
                        Image(systemName: "fork.knife.circle.fill")
                    }
                    .tag(3)
                ProfileBuilder(component: component).build()
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                    }
                    .tag(4)
            }
        case .onboarding:
            OnboardingBuilder(component: component).build(appState: appState)
        case .workout, .loading:
            ProgressView()
        }
    }
}

#Preview {
    SwitcherView(component: DefaultAppComponent.preview)
}
