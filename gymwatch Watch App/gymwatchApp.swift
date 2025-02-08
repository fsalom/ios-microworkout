import SwiftUI

@main
struct gymwatch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(root: MenuBuilder().build())
            //HeartBeatBuilder().build()
            //ListPlanBuilder().build()
            /*
            TimerBuilder().build(this: Workout(exercise: Exercise(name: "example",
                                                                  type: .distance),
                                               results: [], serie: Serie(reps: 10, distance: 10.0)))*/
        }
    }
}
