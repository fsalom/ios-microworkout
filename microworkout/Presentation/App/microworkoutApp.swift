//
//  microworkoutApp.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 2/6/23.
//

import SwiftUI

@main
struct microworkoutApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
