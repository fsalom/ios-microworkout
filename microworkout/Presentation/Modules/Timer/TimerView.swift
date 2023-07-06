//
//  TimerView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import SwiftUI

struct TimerView<VM>: View where VM: TimerViewModelProtocol {
    @ObservedObject var viewModel: VM
    @State var isStarted: Bool = false
    @State var hasTimerFinish: Bool = false
    var body: some View {
        if hasTimerFinish {
            Button {
                isStarted = false
                hasTimerFinish = false
            } label: {
                Label {
                    Text("Restart")
                } icon: {
                    Image(systemName: "play")
                }
            }
        }
        if !isStarted {
            Button {
                isStarted = true
            } label: {
                Label {
                    Text("Empezar")
                } icon: {
                    Image(systemName: "play")
                }
            }
        } else {
            CountDownView(seconds: viewModel.seconds, hasFinish: $hasTimerFinish)
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        let useCase = WorkoutUseCase()
        let workout = Workout(exercise: Exercise(name: "ejemplo",
                                                 type: .distance),
                              numberOfSeries: 4,
                              results: [],
                              serie: Serie(reps: 10, distance: 400.0)
        )
        TimerView(viewModel: TimerViewModel(useCase: useCase, workout: workout, seconds: 60))
    }
}
