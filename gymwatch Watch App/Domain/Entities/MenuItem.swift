import Foundation

enum MenuDestination {
    case home
    case squatDataCollector
}

struct MenuItem: Identifiable {
    var id: UUID = UUID()
    var title: String
    var destination: MenuDestination
}
