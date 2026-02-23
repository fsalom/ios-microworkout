import SwiftUI

struct ListPlanView: View {
    @ObservedObject var viewModel: ListPlanViewModel

    var body: some View {
        List {
            ForEach(viewModel.trainings) { training in
                NavigationLink {
                    DetailWorkoutBuilder().build(with: training)
                } label: {
                    HStack {
                        Image(systemName: training.type == .cardio ? "figure.run" : "dumbbell.fill")
                            .foregroundColor(.accentColor)
                        Text(training.name)
                    }
                }
            }
        }
    }
}
