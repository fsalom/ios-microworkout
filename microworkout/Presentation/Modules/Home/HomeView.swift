//
//  HomeView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/6/23.
//

import SwiftUI

struct HomeView<VM>: View where VM: HomeViewModelProtocol {
    @ObservedObject var viewModel: VM
    var body: some View {
        NavigationView {
            ScrollView {
                ScrollViewReader { value in
                    ForEach(viewModel.workouts, id: \.id) { workout in
                        HomeWorkoutPlanView(workout: workout)
                    }.onAppear {
                        viewModel.load()
                    }
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let useCase = WorkoutUseCase()
        HomeView(viewModel: HomeViewModel(useCase: useCase))
    }
}
