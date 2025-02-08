//
//  TimerView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import SwiftUI

struct ChronoView<VM>: View where VM: ChronoViewModelProtocol {
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
            ChronoTimerView(seconds: viewModel.seconds, hasFinish: $hasTimerFinish)
        }
    }
}

struct ChronoView_Previews: PreviewProvider {
    static var previews: some View {
        let useCase = WorkoutUseCase()

        ChronoView(viewModel: ChronoViewModel(useCase: useCase, seconds: 60))
    }
}
