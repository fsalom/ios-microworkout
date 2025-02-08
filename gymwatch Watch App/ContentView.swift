import SwiftUI

struct ContentView: View {
    @State var navigator: NavigatorProtocol
    let rootTransition: AnyTransition = .opacity

    public init(navigator: NavigatorProtocol = Navigator.shared, root: any View) {
        self.navigator = navigator
        navigator.initialize(root: root)
    }

    public var body: some View {
        ZStack {
            if let root = navigator.root {
                root
            }
        }
    }
}

