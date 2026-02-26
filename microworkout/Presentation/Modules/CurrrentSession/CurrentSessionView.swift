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

                    if viewModel.mirrorManager.isMirroringActive {
                        liveWorkoutBanner
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

                        if !viewModel.workoutEntries.isEmpty {
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
                                                    Text("\(e.reps ?? 0) repeticiones · \(e.weight ?? 0.0, specifier: "%.2f") kg")
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
                                            let idsToRemove = indexSet.map { grouped[exercise]?[$0].id }.compactMap { $0 }
                                            viewModel.deleteEntries(with: idsToRemove)
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
            .sheet(item: $viewModel.activeForm) { form in
                switch form {
                case .new(let exercise):
                    let defaultEntry = viewModel.getWorkoutEntry(for: exercise)
                    ExerciseInput(
                        exercise: exercise,
                        existing: defaultEntry
                    ) { entry in
                        viewModel.addWorkoutEntry(entry)
                    }
                    .padding()
                    .presentationDetents([.height(260)])
                    .presentationDragIndicator(.visible)

                case .edit(let existing):
                    ExerciseInput(
                        exercise: existing.exercise,
                        existing: existing
                    ) { entry in
                        viewModel.updateWorkoutEntry(entry)
                    }
                    .padding()
                    .presentationDetents([.height(260)])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(item: $viewModel.suggestedAWWorkout) { workout in
                LinkSuggestionSheet(
                    workout: workout,
                    trainings: viewModel.getAvailableTrainings(),
                    onLink: { training in
                        viewModel.linkAWWorkout(workout, to: training)
                    },
                    onDismiss: {
                        viewModel.dismissAWSuggestion()
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
}


// MARK: - Live Workout Banner
extension CurrentSessionView {
    var liveWorkoutBanner: some View {
        let data = viewModel.mirrorManager.liveData
        let total = Int(data.elapsedSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        return VStack(spacing: 10) {
            HStack {
                Image(systemName: "applewatch")
                    .foregroundColor(.green)
                Text("Entrenamiento en curso")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.top, 8)

            Text(String(format: "%02d:%02d:%02d", h, m, s))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)

            HStack(spacing: 20) {
                Label("\(Int(data.heartRate)) bpm", systemImage: "heart.fill")
                    .foregroundColor(.red)
                Label("\(Int(data.activeCalories)) kcal", systemImage: "flame.fill")
                    .foregroundColor(.orange)
            }
            .font(.subheadline)

            if data.distance > 0 {
                Label(
                    data.distance >= 1000
                        ? String(format: "%.2f km", data.distance / 1000)
                        : String(format: "%.0f m", data.distance),
                    systemImage: "figure.run"
                )
                .font(.subheadline)
                .foregroundColor(.cyan)
            }

            Button(role: .destructive) {
                viewModel.mirrorManager.stopMirroredSession()
            } label: {
                Label("Detener desde iPhone", systemImage: "stop.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)
        )
        .padding(.horizontal)
    }
}

#Preview {
    CurrentSessionBuilder().build()
}
