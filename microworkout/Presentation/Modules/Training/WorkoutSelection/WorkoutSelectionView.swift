//
//  WorkoutSelectionView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 21/11/23.
//

import SwiftUI

struct WorkoutSelectionView: View {
    @ObservedObject var viewModel: WorkoutSelectionViewModel

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct WorkoutSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutSelectionView(viewModel: WorkoutSelectionViewModel(useCase: WorkoutUseCase()))
    }
}
