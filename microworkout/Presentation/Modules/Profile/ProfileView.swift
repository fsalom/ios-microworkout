import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel

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
