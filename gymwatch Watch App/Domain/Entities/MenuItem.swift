import Foundation

enum MenuDestination {
    case home
    case squatDataCollector
    case microworkout
}

struct MenuItem: Identifiable {
    var id: UUID = UUID()
    var title: String
    var destination: MenuDestination
}
