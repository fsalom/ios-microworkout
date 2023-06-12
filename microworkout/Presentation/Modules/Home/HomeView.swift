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
                Text("chat.name")
                    .fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .leading) {
                Image(systemName: "bell")
            }

        }.padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        NavigationView {
            List {
                Text("Entrenamientos")
                    .font(.subheadline)
                ScrollViewReader { value in
                    ForEach(viewModel.workouts, id: \.id) { workout in
                        HomeWorkoutPlanView(workout: workout)
                    }.onAppear {
                        viewModel.load()
                    }
                }
            }.listStyle(.plain)
                .cornerRadius(10)
                .padding(10)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let useCase = WorkoutUseCase()
        HomeView(viewModel: HomeViewModel(useCase: useCase))
    }
}
