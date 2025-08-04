import SwiftUI

struct LoggedExercisesView: View {
    @ObservedObject var viewModel: LoggedExercisesViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let grouped = viewModel.groupedByExercise()
        let ordered = viewModel.orderedExercises()

        ZStack {
            Color(.systemGroupedBackground)
            List {
                ForEach(ordered, id: \.self) { exercise in
                    Section(header:
                                HStack {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {

                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor( Color(.gray))
                                .padding(5)
                                .background(Circle().fill(.white))
                        }
                        .buttonStyle(.plain)
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
                                Button(action: {

                                }) {
                                    Image(systemName: e.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(e.isCompleted ? .green : .gray)
                                        .imageScale(.large)
                                }
                                .buttonStyle(.plain)
                            }
                            .onTapGesture {

                            }
                        }
                        .onDelete { indexSet in
                            if let group = grouped[exercise] {
                                let idsToRemove = indexSet.map { group[$0].id }

                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }

    }
}

struct LoggedExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedExercisesBuilder().build(this: LoggedExerciseByDay(date: "", exercises: [], durationInSeconds: 0))
    }
}
