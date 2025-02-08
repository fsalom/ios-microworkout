//
//  HomeWorkoutPlanView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 8/6/23.
//

import SwiftUI

struct HomeWorkoutPlanView: View {

    var plan: WorkoutPlan

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 8))
                    .foregroundStyle(.red).opacity(0.5)
                    .overlay {
                        Circle()
                            .trim(from: 0,
                                  to: CGFloat(plan.completed))
                            .stroke(plan.completed == 1.0 ? .green : .red,
                                    style: StrokeStyle(lineWidth: 8,
                                                       lineCap: .round))
                    }
                    .rotationEffect(.degrees(-90))

                Text("\(Int(plan.completed * 100))%").font(.system(size: 10)).bold()
            }.frame(width: 40)
            VStack(alignment: .leading, spacing: 10) {
                Text(plan.name)
                HStack {
                    Text("Nº de ejercicios").fontWeight(.bold)
                    Text("\(plan.workouts.count)")
                    Text("Nº de series").fontWeight(.bold)
                    Text("\(plan.totalNumberOfSeries)")
                }.font(.footnote)

            }
            Spacer()
        }.padding(10)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .foregroundColor(.black)
    }
}

struct HomeWorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        HomeWorkoutPlanView(plan: WorkoutPlan(id: "", name: "Ejemplo", workouts: []))
    }
}
