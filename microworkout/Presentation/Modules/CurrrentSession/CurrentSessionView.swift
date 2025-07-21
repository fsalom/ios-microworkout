import SwiftUI

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

struct CurrentSessionView: View {
    @StateObject private var viewModel = CurrentSessionViewModel()
    @FocusState private var isSearchFocused: Bool

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            ZStack {
                (viewModel.startTime != nil ? Color.blue : Color(.systemGroupedBackground))
                    .ignoresSafeArea()

                VStack {
                    if let start = viewModel.startTime {
                        let totalSeconds = Int(viewModel.now.timeIntervalSince(start))
                        let hours = totalSeconds / 3600
                        let minutes = (totalSeconds % 3600) / 60
                        let seconds = totalSeconds % 60
                        Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }

                    let grouped = viewModel.groupedByExercise()
                    let ordered = viewModel.orderedExercises()

                    if !viewModel.loggedExercises.isEmpty {
                        List {
                            ForEach(ordered, id: \.self) { exercise in
                                Section(header:
                                    HStack {
                                        Text(exercise.name)
                                            .font(.headline)
                                            .foregroundColor(viewModel.startTime != nil ? .white : .primary)
                                        Spacer()
                                        Button(action: {
                                            if let last = grouped[exercise]?.last {
                                                let new = LoggedExercise(
                                                    id: UUID(),
                                                    exercise: last.exercise,
                                                    reps: last.reps,
                                                    weight: last.weight
                                                )
                                                viewModel.activeForm = .new(new.exercise)
                                            } else {
                                                let new = LoggedExercise(
                                                    id: UUID(),
                                                    exercise: exercise,
                                                    reps: 0,
                                                    weight: 0
                                                )
                                                viewModel.activeForm = .edit(new)
                                            }
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .resizable()
                                                .frame(width: 24, height: 24)
                                                .foregroundColor(viewModel.startTime != nil ? .blue : Color(.gray))
                                                .padding(5)
                                                .background(Circle().fill(viewModel.startTime != nil ? Color(.systemGray5) : .white))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(8)
                                    .listRowInsets(EdgeInsets())
                                ) {
                                    ForEach(grouped[exercise] ?? []) { e in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("\(e.reps) repeticiones · \(e.weight, specifier: "%.1f") kg")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Button(action: {
                                                viewModel.toggleCompletion(for: e.id)
                                            }) {
                                                Image(systemName: e.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(e.isCompleted ? .green : .gray)
                                                    .imageScale(.large)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .onTapGesture {
                                            viewModel.activeForm = .edit(e)
                                        }
                                    }
                                    .onDelete { indexSet in
                                        if let group = grouped[exercise] {
                                            let idsToRemove = indexSet.map { group[$0].id }
                                            viewModel.deleteExercises(with: idsToRemove)
                                        }
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }

                    Spacer()

                    if viewModel.isRunning {
                        SliderView(
                            message: "Desliza para finalizar",
                            backgroundColor: .white,
                            frontColor: .blue,
                            successColor: .white,
                            onFinish: {
                                withAnimation { viewModel.stopSession() }
                            },
                            isWaitingResponse: false)
                    } else {
                        SliderView(
                            onFinish: {
                                withAnimation { viewModel.startSession() }
                            },
                            isWaitingResponse: false)
                    }
                }
                .padding(16)
                .searchable(text: $viewModel.searchText) // , isPresented: $isSearchFocused
                .focused($isSearchFocused)
                .onReceive(timer) { date in
                    viewModel.updateNow(to: date)
                }

                if !viewModel.filteredExercises.isEmpty && viewModel.activeForm == nil {
                    Color(.systemBackground).ignoresSafeArea()
                    List(viewModel.filteredExercises) { exercise in
                        Button {
                            viewModel.activeForm = .new(exercise)
                            viewModel.searchText = ""
                            isSearchFocused = false
                        } label: {
                            Text(exercise.name)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .sheet(item: $viewModel.activeForm) { form in
            switch form {
            case .new(let exercise):
                let last = viewModel.loggedExercises.last(where: { $0.exercise == exercise })
                ExerciseInput(
                    exercise: exercise,
                    existing: last.map { LoggedExercise(id: UUID(), exercise: $0.exercise, reps: $0.reps, weight: $0.weight) }
                ) { new in
                    viewModel.addLoggedExercise(new)
                    viewModel.activeForm = nil
                }
                .padding()
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)

            case .edit(let existing):
                ExerciseInput(exercise: existing.exercise, existing: existing) { updated in
                    viewModel.updateLoggedExercise(updated)
                    viewModel.activeForm = nil
                }
                .padding()
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    CurrentSessionView()
}
