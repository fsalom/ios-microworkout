import SwiftUI

@main
struct gymwatch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(root: MenuBuilder().build())
                .onAppear {
                    WatchConnectivityManager.shared.activate()
                }
        }
    }
}
