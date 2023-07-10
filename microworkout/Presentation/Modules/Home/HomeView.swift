//
//  HomeView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/6/23.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    var body: some View {
        NavigationView {
            ScrollView {
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            ZStack {
                                Circle()
                                    .frame(width: 60, height: 60, alignment: .top)
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
                        ForEach(viewModel.workouts, id: \.id) { workout in
                            NavigationLink(destination:  DetailWorkoutBuilder().build(with: workout)) {
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let useCase = WorkoutUseCase()
        HomeView(viewModel: HomeViewModel(useCase: useCase))
    }
}
