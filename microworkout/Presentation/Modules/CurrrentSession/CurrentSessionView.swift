import SwiftUI

struct Exercise_: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct LoggedExercise: Identifiable, Equatable {
    let id: UUID
    let exercise: Exercise_
    var reps: Int
    var weight: Double
    var isCompleted: Bool = false
}

struct StepperInputView: View {
    var label: String
    @Binding var value: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button(action: {
                    if let currentValue = value {
                        value = max(0, currentValue - 1)
                    } else {
                        value = 0
                    }
                }) {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                }

                TextField(label, value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Button(action: {
                    if let currentValue = value {
                        value = currentValue + 1
                    } else {
                        value = 1
                    }
                }) {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                }
            }
            .padding(4)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(4)
    }
}

struct ExerciseInput: View {
    let exercise: Exercise_
    var existing: LoggedExercise? = nil
    var onSave: (LoggedExercise) -> Void

    @State private var repsValue: Double? = nil
    @State private var weight: Double? = nil
    @State private var errorMessage: String?

    var isFormValid: Bool {
        repsValue != nil && weight != nil
    }

    @FocusState private var focusedField: Field?
    enum Field { case reps, weight }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(existing == nil ? "Nueva serie" : "Editar serie")
                .font(.headline)
            Text(exercise.name)
                .font(.title2)
                .bold()

            StepperInputView(label: "Peso", value: $weight)

            StepperInputView(label: "Repeticiones", value: $repsValue)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button(action: {
                save()
            }) {
                Text("Guardar")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.black : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!isFormValid)

        }
        .onAppear {
            repsValue = existing.map { Double($0.reps) }
            weight = existing?.weight
            focusedField = .reps
        }
    }

    private func save() {
        guard let r = repsValue.flatMap(Int.init), let w = weight else {
            errorMessage = "Valores no válidos"
            return
        }

        onSave(LoggedExercise(
            id: existing?.id ?? UUID(),
            exercise: exercise,
            reps: r,
            weight: w
        ))
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}


import SwiftUI

struct CurrentSessionView: View {
    @State private var searchText: String = ""
    @State private var activeForm: ActiveExerciseForm? = nil
    @State private var loggedExercises: [LoggedExercise] = []

    @State private var isRunning: Bool = false
    @State private var startTime: Date? = nil
    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @FocusState private var isSearchFocused: Bool

    enum ActiveExerciseForm: Identifiable {
        case new(Exercise_)
        case edit(LoggedExercise)

        var id: UUID {
            switch self {
            case .new(let exercise): return exercise.id
            case .edit(let logged): return logged.id
            }
        }
    }

    let exercises: [Exercise_] = [
        Exercise_(name: "Press de banca"),
        Exercise_(name: "Sentadilla"),
        Exercise_(name: "Peso muerto"),
        Exercise_(name: "Dominadas"),
        Exercise_(name: "Press militar"),
        Exercise_(name: "Curl de bíceps"),
        Exercise_(name: "Remo con barra")
    ]

    var filteredExercises: [Exercise_] {
        if searchText.isEmpty {
            return []
        } else {
            return exercises.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                (startTime != nil ? Color.blue : Color(.systemGroupedBackground))
                    .ignoresSafeArea()

                VStack {

                    if let startTime = startTime {
                        let totalSeconds = Int(now.timeIntervalSince(startTime))
                        let hours = totalSeconds / 3600
                        let minutes = (totalSeconds % 3600) / 60
                        let seconds = totalSeconds % 60
                        Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(startTime != nil ? .white : .secondary)
                            .padding(.top, 8)
                    }

                    // Agrupación por ejercicio
                    let groupedByExercise = Dictionary(grouping: loggedExercises, by: { $0.exercise })
                    let orderedExercises = loggedExercises.map { $0.exercise }.uniqued()

                    if !loggedExercises.isEmpty {
                        List {
                            ForEach(orderedExercises, id: \.self) { exercise in
                                Section(header:
                                    HStack {
                                        Text(exercise.name)
                                            .font(.headline)
                                            .foregroundColor(startTime != nil ? .white : .primary)
                                        Spacer()
                                    Button(action: {
                                        if let last = groupedByExercise[exercise]?.last {
                                            let new = LoggedExercise(
                                                id: UUID(),
                                                exercise: last.exercise,
                                                reps: last.reps,
                                                weight: last.weight
                                            )
                                            activeForm = .new(new.exercise)
                                        } else {
                                            let new = LoggedExercise(
                                                id: UUID(),
                                                exercise: exercise,
                                                reps: 0,
                                                weight: 0
                                            )
                                            activeForm = .edit(new)
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(startTime != nil ? .blue : .blue)
                                            .padding(5)
                                            .background(Circle().fill(startTime != nil ? Color(.systemGray5) : .white ))
                                    }
                                    .buttonStyle(.plain)

                                    }
                                    .padding(8)
                                    .listRowInsets(EdgeInsets())
                                ) {
                                    ForEach(groupedByExercise[exercise] ?? []) { e in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("\(e.reps) repeticiones · \(e.weight, specifier: "%.1f") kg")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Button(action: {
                                                if let index = loggedExercises.firstIndex(where: { $0.id == e.id }) {
                                                    loggedExercises[index].isCompleted.toggle()
                                                }
                                            }) {
                                                Image(systemName: e.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(e.isCompleted ? .green : .gray)
                                                    .imageScale(.large)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .onTapGesture {
                                            activeForm = .edit(e)
                                        }
                                    }
                                    .onDelete { indexSet in
                                        if let group = groupedByExercise[exercise] {
                                            let idsToRemove = indexSet.map { group[$0].id }
                                            loggedExercises.removeAll { idsToRemove.contains($0.id) }
                                        }
                                    }
                                }
                            }
                        }
                        //.listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }

                    Spacer()
                    if self.isRunning {
                        SliderView(
                            message: "Desliza para finalizar",
                            backgroundColor: .white,
                            frontColor: .blue,
                            successColor: .white,
                            onFinish: {
                                withAnimation {
                                    startTime = nil
                                    self.isRunning = false
                                }
                            },
                            isWaitingResponse: false)
                    } else {
                        SliderView(
                            onFinish: {
                                withAnimation {
                                    startTime = Date()
                                    self.isRunning = true
                                }
                            },
                            isWaitingResponse: false)
                    }
                }
                .padding(16)
                .searchable(text: $searchText)
                .focused($isSearchFocused)
                .onReceive(timer) { input in
                    now = input
                }

                // Lista de búsqueda en overlay
                if !filteredExercises.isEmpty && activeForm == nil {
                    Color(.systemBackground)
                        .ignoresSafeArea()

                    List(filteredExercises) { exercise in
                        Button {
                            activeForm = .new(exercise)
                            searchText = ""
                            isSearchFocused = false
                        } label: {
                            Text(exercise.name)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .sheet(item: $activeForm) { form in
            switch form {
            case .new(let exercise):
                let last = loggedExercises.last(where: { $0.exercise == exercise })
                ExerciseInput(
                    exercise: exercise,
                    existing: last.map { LoggedExercise(id: UUID(), exercise: $0.exercise, reps: $0.reps, weight: $0.weight) }
                ) { new in
                    loggedExercises.append(new)
                    activeForm = nil
                }
                .padding()
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)

            case .edit(let existing):
                ExerciseInput(exercise: existing.exercise, existing: existing) { updated in
                    if let index = loggedExercises.firstIndex(where: { $0.id == updated.id }) {
                        loggedExercises[index] = updated
                    }
                    activeForm = nil
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
