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
            /*
            let workout = Workout(exercise: Exercise(name: "ejemplo",
                                                     type: .distance),
                                  results: [],
                                  serie: Serie(reps: 10, distance: 400.0)
            )
            TimerBuilder().build(this: workout)*/
            HomeBuilder().build()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
