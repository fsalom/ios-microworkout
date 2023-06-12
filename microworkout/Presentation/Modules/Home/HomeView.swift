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
            List {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .frame(width: 50, height: 50, alignment: .top)
                            .foregroundColor(.gray)
                        Image(systemName: "photo")
                            .foregroundColor(.white)
                            .imageScale(.small)
                            .frame(width: 44, height: 40)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome back")
                            .font(.footnote)
                            .lineLimit(2)
                        Text("Fernando!")
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Image(systemName: "bell")
                    }

                }
                VStack(alignment: .leading) {
                    Text("Entrenamientos")
                        .font(.headline)
                    ForEach(viewModel.workouts, id: \.id) { workout in
                        HomeWorkoutPlanView(workout: workout)
                    }
                }.onAppear {
                    viewModel.load()
                }
            }
        }.listStyle(.automatic)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let useCase = WorkoutUseCase()
        HomeView(viewModel: HomeViewModel(useCase: useCase))
    }
}
