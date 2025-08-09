import SwiftUI

struct LoggedExercisesView: View {
    @ObservedObject var viewModel: LoggedExercisesViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let grouped = viewModel.groupedByExercise()
        let ordered = viewModel.orderedExercises()

        ZStack {
            Color(.systemGroupedBackground)
            VStack {
                HStack(spacing: 20) {
                    StatView(title: "Ejercicios",
                             value: self.viewModel.uiState.loggedExercises.exercisesFormatted,
                             systemImage: "figure.strengthtraining.traditional")

                    StatView(title: "Series",
                             value: self.viewModel.uiState.loggedExercises.totalSeriesFormatted,
                             systemImage: "repeat")

                    StatView(title: "Peso total",
                             value: self.viewModel.uiState.loggedExercises.totalWeightFormatted,
                             systemImage: "scalemass")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )

                List {
                    ForEach(ordered, id: \.self) { exercise in
                        Section(header:
                                    HStack {
                            Text(exercise.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                            .padding(8)
                            .listRowInsets(EdgeInsets())
                        ) {
                            ForEach(grouped[exercise] ?? []) { e in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(e.reps) repeticiones · \(e.weight, specifier: "%.2f") kg")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Eliminar") {
                        viewModel.delete()
                    }
                } label: {
                    Label("Más", systemImage: "ellipsis.circle")
                }
            }
        }
    }
}

struct LoggedExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedExercisesBuilder().build(this: LoggedExerciseByDay(date: "", exercises: [], durationInSeconds: 0))
    }
}
