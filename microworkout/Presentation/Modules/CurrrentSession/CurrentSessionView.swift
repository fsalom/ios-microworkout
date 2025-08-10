import SwiftUI

struct CurrentSessionView: View {
    @StateObject var viewModel: CurrentSessionViewModel
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

                    if viewModel.isSaved {
                        Spacer()
                        CenteredSquareOverlay(size: 180) {
                            VStack {
                                Image(systemName: "tray.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                                Text("Entrenamiento guardado")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                            .padding()
                        }
                        .transition(.scale)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation(.easeInOut) {
                                    self.viewModel.isSaved = false
                                }
                            }
                        }
                        Spacer()
                    } else {

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
                                            viewModel.action(for: grouped, and: exercise)
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
                                                    Text("\(e.reps) repeticiones · \(e.weight, specifier: "%.2f") kg")
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
                        } else {
                            VStack {
                                Image(systemName: "arrow.up")
                                    .font(.largeTitle)
                                    .foregroundColor(viewModel.startTime != nil ? .white : .primary)
                                Text("Busca ejecicios para tu rutina...")
                                    .font(.caption)
                                    .foregroundColor(viewModel.startTime != nil ? .white : .primary)
                            }
                            .padding(16)
                        }
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

                if !viewModel.searchText.isEmpty && viewModel.activeForm == nil {
                    Color(.systemBackground).ignoresSafeArea()
                    if viewModel.exercises.count == 0 {
                        List {
                            Button {
                                viewModel.addExercise(with: viewModel.searchText)
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Añadir \"\(viewModel.searchText)\" como nuevo ejercicio")
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    } else {
                        List(viewModel.exercises) { exercise in
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
        }
        .sheet(item: $viewModel.activeForm) { form in
            switch form {
            case .new(let exercise):
                let last = viewModel.loggedExercises.last(where: { $0.exercise == exercise })
                ExerciseInput(
                    exercise: exercise,
                    existing: last.map { viewModel.createLoggedExercise(from: $0) }
                ) { new in
                    viewModel.addLoggedExercise(new)
                }
                .padding()
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)

            case .edit(let existing):
                ExerciseInput(exercise: existing.exercise, existing: existing) { updated in
                    viewModel.updateLoggedExercise(updated)
                }
                .padding()
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    CurrentSessionBuilder().build()
}
