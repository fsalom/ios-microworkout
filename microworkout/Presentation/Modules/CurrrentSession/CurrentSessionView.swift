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
}

struct ExerciseInput: View {
    let exercise: Exercise_
    var existing: LoggedExercise? = nil
    var onSave: (LoggedExercise) -> Void

    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?
    enum Field { case reps, weight }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(existing == nil ? "Nueva serie" : "Editar serie")
                .font(.headline)
            Text(exercise.name)
                .font(.title2)
                .bold()

            TextField("Repeticiones", text: $reps)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .reps)
                .submitLabel(.next)
                .onSubmit { focusedField = .weight }

            TextField("Peso (kg)", text: $weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .weight)
                .submitLabel(.done)
                .onSubmit { save() }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Guardar") {
                save()
            }
        }
        .padding()
        .onAppear {
            reps = existing.map { "\($0.reps)" } ?? ""
            weight = existing.map { "\($0.weight)" } ?? ""
            focusedField = .reps
        }
    }

    private func save() {
        guard let r = Int(reps), let w = Double(weight) else {
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
                VStack {

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
                                        Spacer()
                                        Button(action: {
                                            if let last = groupedByExercise[exercise]?.last {
                                                let new = LoggedExercise(id: UUID(), exercise: last.exercise, reps: last.reps, weight: last.weight)
                                                activeForm = .new(new.exercise)
                                            } else {
                                                activeForm = .new(exercise)
                                            }
                                        }) {
                                            Image(systemName: "plus.circle")
                                                .imageScale(.large)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                ) {
                                    ForEach(groupedByExercise[exercise] ?? []) { e in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("\(e.reps) repeticiones · \(e.weight, specifier: "%.1f") kg")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
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
                    }

                    Spacer()
                    SliderView(
                        onFinish: {
                            withAnimation {

                            }
                        },
                        isWaitingResponse: false)
                }
                .searchable(text: $searchText)
                .focused($isSearchFocused)

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
                ExerciseInput(exercise: exercise) { new in
                    loggedExercises.append(new)
                    activeForm = nil
                }
                .padding()
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)

            case .edit(let existing):
                ExerciseInput(exercise: existing.exercise, existing: existing) { updated in
                    if let index = loggedExercises.firstIndex(where: { $0.id == updated.id }) {
                        loggedExercises[index] = updated
                    }
                    activeForm = nil
                }
                .padding()
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    CurrentSessionView()
}
