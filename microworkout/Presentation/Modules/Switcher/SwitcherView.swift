import SwiftUI

struct SwitcherView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.screen {
        case .home:
            HomeBuilder().build(appState: appState)
        case .workout:
            CurrentTrainingBuilder().build(appState: appState)
        case .loading:
            ProgressView()
        }
    }
}

#Preview {
    SwitcherView()
}
