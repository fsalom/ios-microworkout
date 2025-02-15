//
//  HomeView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/6/23.
//

import SwiftUI

struct HomeTrainingView: View {
    @ObservedObject var viewModel: HomeTrainingViewModel
    var body: some View {
        NavigationView {
            ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            Image("splash")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Welcome back")
                                    .font(.footnote)
                                    .lineLimit(2)
                                Text("Fernando!")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Image(systemName: "bell")
                            }
                        }


                        Text("Progresión de la semana")
                            .font(.footnote)
                        ProgressView(value: 0.4).progressViewStyle(.linear)
                        ForEach($viewModel.workouts, id: \.id) { $workout in
                            NavigationLink(destination:  DetailWorkoutBuilder().build(with: $workout)) {
                                HomeWorkoutPlanView(plan: workout)
                            }
                        }
                    }.padding(16)
            }.navigationTitle("Entrenamientos")
                .navigationBarTitleDisplayMode(.inline)
        }
            .onAppear {
                viewModel.load()
            }
            .edgesIgnoringSafeArea(.all)
        //.scrollBounceBehavior(.basedOnSize)
    }
}

struct HomeTrainingView_Previews: PreviewProvider {
    static var previews: some View {
        let useCase = WorkoutUseCase()
        HomeTrainingView(viewModel: HomeTrainingViewModel(useCase: useCase))
    }
}
