import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationView {
            Group {
                if viewModel.uiState.hasProfile && !viewModel.uiState.isEditing {
                    profileDetailView
                } else {
                    profileFormView
                }
            }
            .navigationTitle("Perfil")
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.loadHealthKitStatus()
                }
            }
        }
    }

    // MARK: - Detail View

    private var profileDetailView: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.uiState.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(Int(viewModel.uiState.dailyCalorieTarget)) kcal/dia objetivo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            Section("Datos fisicos") {
                ProfileRow(icon: "figure.stand", label: "Sexo", value: viewModel.uiState.gender.rawValue)
                ProfileRow(icon: "calendar", label: "Edad", value: "\(viewModel.uiState.age) anos")
                ProfileRow(icon: "scalemass", label: "Peso", value: String(format: "%.1f kg", viewModel.uiState.weight))
                ProfileRow(icon: "ruler", label: "Altura", value: String(format: "%.0f cm", viewModel.uiState.height))
            }

            Section("Actividad") {
                ProfileRow(icon: "flame", label: "Nivel", value: viewModel.uiState.activityLevel.rawValue)
            }

            Section("Objetivo") {
                ProfileRow(icon: "target", label: "Meta", value: viewModel.uiState.fitnessGoal.rawValue)
                ProfileRow(icon: "fork.knife", label: "Perfil macros", value: viewModel.uiState.macroProfile.rawValue)
                ProfileRow(icon: "p.circle", label: "Proteina", value: "\(Int(viewModel.uiState.macroTargets.proteins))g")
                ProfileRow(icon: "c.circle", label: "Carbos", value: "\(Int(viewModel.uiState.macroTargets.carbohydrates))g")
                ProfileRow(icon: "f.circle", label: "Grasa", value: "\(Int(viewModel.uiState.macroTargets.fats))g")
            }

            if viewModel.uiState.hasCycling {
                Section("Cycling semanal") {
                    HStack(spacing: 6) {
                        ForEach(cyclingDayLabels, id: \.weekday) { item in
                            Text(item.label)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .frame(width: 32, height: 32)
                                .background(viewModel.uiState.freeDays.contains(item.weekday) ? Color.green.opacity(0.2) : Color(.systemGray5))
                                .foregroundColor(viewModel.uiState.freeDays.contains(item.weekday) ? .green : .primary)
                                .cornerRadius(8)
                        }
                    }

                    ProfileRow(icon: "plus.circle", label: "Extra dia libre", value: "+\(Int(viewModel.uiState.freeDayExtraCalories)) kcal")
                    ProfileRow(icon: "flame", label: "Dia estricto", value: "\(Int(viewModel.uiState.strictDayCalorieTarget)) kcal")
                    ProfileRow(icon: "flame.fill", label: "Dia libre", value: "\(Int(viewModel.uiState.freeDayCalorieTarget)) kcal")
                }
            }

            if viewModel.uiState.isHealthDataAvailable {
                Section("Salud") {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(viewModel.uiState.healthKitStatus == .authorized ? .green : .secondary)
                            .frame(width: 24)
                        Text("HealthKit")
                        Spacer()
                        switch viewModel.uiState.healthKitStatus {
                        case .authorized:
                            Text("Activado")
                                .foregroundColor(.green)
                        case .notDetermined:
                            Button("Activar") {
                                viewModel.requestHealthKit()
                            }
                        case .denied:
                            Button("Abrir Salud") {
                                viewModel.openHealthApp()
                            }
                        }
                    }
                    if viewModel.uiState.healthKitStatus == .denied {
                        Text("Activa los permisos en Salud > Perfil > Apps y servicios > microworkout")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                Button(action: { viewModel.startEditing() }) {
                    HStack {
                        Spacer()
                        Text("Editar perfil")
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Form View

    private var profileFormView: some View {
        Form {
            Section("Nombre") {
                TextField("Tu nombre", text: $viewModel.uiState.name)
            }

            Section("Datos fisicos") {
                Picker("Sexo", selection: $viewModel.uiState.gender) {
                    ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .pickerStyle(.segmented)

                Stepper("Edad: \(viewModel.uiState.age) anos", value: $viewModel.uiState.age, in: 10...100)

                VStack(alignment: .leading) {
                    Text("Peso: \(String(format: "%.1f", viewModel.uiState.weight)) kg")
                    Slider(value: $viewModel.uiState.weight, in: 30...200, step: 0.5)
                }

                VStack(alignment: .leading) {
                    Text("Altura: \(String(format: "%.0f", viewModel.uiState.height)) cm")
                    Slider(value: $viewModel.uiState.height, in: 100...220, step: 1)
                }
            }

            Section("Nivel de actividad") {
                Picker("Actividad", selection: $viewModel.uiState.activityLevel) {
                    ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            }

            Section("Objetivo fisico") {
                Picker("Objetivo", selection: $viewModel.uiState.fitnessGoal) {
                    ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                        Text(goal.rawValue).tag(goal)
                    }
                }
            }

            Section("Perfil de macros") {
                Picker("Macros", selection: $viewModel.uiState.macroProfile) {
                    ForEach(UserProfile.MacroProfile.allCases, id: \.self) { profile in
                        Text(profile.rawValue).tag(profile)
                    }
                }
            }

            Section("Cycling semanal") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dias libres (max 3)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        ForEach(cyclingDayLabels, id: \.weekday) { item in
                            let isSelected = viewModel.uiState.freeDays.contains(item.weekday)
                            Button {
                                if isSelected {
                                    viewModel.uiState.freeDays.remove(item.weekday)
                                } else if viewModel.uiState.freeDays.count < 3 {
                                    viewModel.uiState.freeDays.insert(item.weekday)
                                }
                            } label: {
                                Text(item.label)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 36, height: 36)
                                    .background(isSelected ? Color.green.opacity(0.3) : Color(.systemGray5))
                                    .foregroundColor(isSelected ? .green : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !viewModel.uiState.freeDays.isEmpty {
                    Stepper("Extra: +\(Int(viewModel.uiState.freeDayExtraCalories)) kcal",
                            value: $viewModel.uiState.freeDayExtraCalories,
                            in: 200...1000,
                            step: 50)
                }
            }

            Section {
                Button(action: { viewModel.save() }) {
                    HStack {
                        Spacer()
                        Text("Guardar")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }

                if viewModel.uiState.hasProfile {
                    Button(action: { viewModel.cancelEditing() }) {
                        HStack {
                            Spacer()
                            Text("Cancelar")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

private let cyclingDayLabels: [(weekday: Int, label: String)] = [
    (2, "L"), (3, "M"), (4, "X"), (5, "J"), (6, "V"), (7, "S"), (1, "D")
]

private struct ProfileRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileBuilder().build()
}
