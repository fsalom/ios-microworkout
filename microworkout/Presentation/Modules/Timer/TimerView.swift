//
//  TimerView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import SwiftUI

struct TimerView<VM>: View where VM: TimerViewModelProtocol {
    @ObservedObject var viewModel: VM

    var body: some View {
        CountDownView(seconds: viewModel.seconds)
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        let useCase = WorkoutUseCase()
        let workout = Workout(exercise: Exercise(name: "ejemplo",
                                                 type: .distance),
                              results: [],
                              serie: Serie(reps: 10, distance: 400.0)
        )
        TimerView(viewModel: TimerViewModel(useCase: useCase, workout: workout, seconds: 60))
    }
}
