//
//  HealthKitView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 5/8/23.
//

import SwiftUI

struct HealthKitView: View {
    @ObservedObject var viewModel: HealthKitViewModel

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    let useCase = WorkoutUseCase()
    HealthKitView(viewModel: HealthKitViewModel(useCase: useCase))
}
