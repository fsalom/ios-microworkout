import Foundation
import SwiftUI


final class AppState: ObservableObject {
    enum Screen {
        case workout(training: Training)
        case home
        case loading

        var icon: String {
            switch self {
            case .workout: "🏋️‍♂️"
            case .home: "🏠"
            case .loading: "⏳"
            }
        }
    }

    @Published public var screen: Screen = .home {
        didSet {
            print("🏷️ \(screen.icon) App state: launched \(screen)")
        }
    }

    func changeScreen(to screen: Screen) {
        DispatchQueue.main.async {
            self.screen = screen
        }
    }
}
