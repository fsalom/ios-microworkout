import SwiftUI

struct Exercise_: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct LoggedExercise: Identifiable {
    let id = UUID()
    let exercise: Exercise_
    let reps: Int
    let weight: Double
}

struct ExerciseInput: View {
    let exercise: Exercise_
    var onSave: (LoggedExercise) -> Void

    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?

    enum Field {
        case reps, weight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ejercicio seleccionado:")
                .font(.headline)
            Text(exercise.name)
                .font(.title2)
                .bold()

            TextField("Repeticiones", text: $reps)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: .reps)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .weight
                }

            TextField("Peso (kg)", text: $weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: .weight)
                .submitLabel(.done)
                .onSubmit {
                    submitExercise()
                }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Divider()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .onAppear {
            // Enfocar al cargar
            focusedField = .reps
        }
    }

    private func submitExercise() {
        if let repsInt = Int(reps), let weightDouble = Double(weight) {
            onSave(LoggedExercise(exercise: exercise, reps: repsInt, weight: weightDouble))
            self.reps = ""
            self.weight = ""
            self.errorMessage = nil
            focusedField = .reps // volver a reps
        } else {
            errorMessage = "Introduce números válidos en repeticiones y peso"
        }
    }
}

struct CurrentSessionView: View {
    @State private var searchText: String = ""
    @State private var selectedExercise: Exercise_? = nil
    @State private var loggedExercises: [LoggedExercise] = []
    @FocusState private var isSearchFocused: Bool

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
                    if let exercise = selectedExercise {
                        ExerciseInput(exercise: exercise) { logged in
                            loggedExercises.append(logged)
                            selectedExercise = nil
                        }
                        .padding(.horizontal)
                    }

                    if !loggedExercises.isEmpty {
                        List {
                            Section(header: Text("Ejercicios añadidos")) {
                                ForEach(loggedExercises) { e in
                                    VStack(alignment: .leading) {
                                        Text(e.exercise.name)
                                            .fontWeight(.semibold)
                                        Text("\(e.reps) repeticiones · \(e.weight, specifier: "%.1f") kg")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .searchable(text: $searchText)
                .focused($isSearchFocused)

                // Capa superior que ocupa toda la pantalla con los resultados
                if !filteredExercises.isEmpty && selectedExercise == nil {
                    Color(.systemBackground)
                        .ignoresSafeArea()

                    List(filteredExercises) { exercise in
                        Button {
                            selectedExercise = exercise
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
    }
}

#Preview {
    CurrentSessionView()
}
