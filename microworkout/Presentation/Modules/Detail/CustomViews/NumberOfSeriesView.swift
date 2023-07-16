//
//  NumberOfSeriesView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 16/7/23.
//

import SwiftUI

struct NumberOfSeriesView: View {
    @Binding var workout: Workout
    var body: some View {
        Text("\(workout.results.count) de \(workout.numberOfSeries)")
            .fontWeight(.heavy)
            .frame(width: 80)
            .padding(10)
            .foregroundColor(.white)
            .background(getColor(of: workout))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func getColor(of workout: Workout) -> Color {
        if workout.results.count >= workout.numberOfSeries {
            return .green
        } else {
            return .gray
        }
    }
}
