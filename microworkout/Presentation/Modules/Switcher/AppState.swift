import Foundation
import SwiftUI


final class AppState: ObservableObject {
    enum Screen {
        case workout(training: Training)
        case home
        case loading
        case onboarding

        var icon: String {
            switch self {
            case .workout: "🏋️‍♂️"
            case .home: "🏠"
            case .loading: "⏳"
            case .onboarding: "👋"
            }
        }
    }

    @Published public var screen: Screen {
        didSet {
            print("🏷️ \(screen.icon) App state")
        }
    }

    init(initialScreen: Screen = .home) {
        self.screen = initialScreen
    }

    func changeScreen(to screen: Screen) {
        DispatchQueue.main.async {
            self.screen = screen
        }
    }
}

extension AppState {
    var isWorkoutScreen: Bool {
        if case .workout = screen { return true }
        return false
    }

    var currentTraining: Training? {
        if case let .workout(training) = screen { return training }
        return nil
    }
}

