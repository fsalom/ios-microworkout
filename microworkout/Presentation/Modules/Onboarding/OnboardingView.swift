//
//  OnboardingView.swift
//  microworkout
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= viewModel.currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Skip button
            HStack {
                Spacer()
                Button("Saltar") {
                    viewModel.skip()
                }
                .foregroundColor(.gray)
                .padding(.trailing, 24)
                .padding(.top, 8)
            }

            // Content
            TabView(selection: $viewModel.currentStep) {
                WelcomeStep(viewModel: viewModel)
                    .tag(0)
                PhysicalDataStep(viewModel: viewModel)
                    .tag(1)
                FitnessGoalStep(viewModel: viewModel)
                    .tag(2)
                ActivityLevelStep(viewModel: viewModel)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)

            // Navigation buttons
            HStack(spacing: 16) {
                if viewModel.currentStep > 0 {
                    Button(action: { viewModel.previousStep() }) {
                        Text("Anterior")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }

                Button(action: {
                    if viewModel.currentStep == viewModel.totalSteps - 1 {
                        viewModel.finish()
                    } else {
                        viewModel.nextStep()
                    }
                }) {
                    Text(viewModel.currentStep == viewModel.totalSteps - 1 ? "Finalizar" : "Siguiente")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.white)
    }
}

// MARK: - Step 1: Welcome + Name

private struct WelcomeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Bienvenido")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Configura tu perfil para calcular tus objetivos de calorias diarias.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            TextField("Tu nombre", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// MARK: - Step 2: Physical Data

private struct PhysicalDataStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Datos fisicos")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 24)

                // Gender
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sexo")
                        .font(.headline)
                    Picker("Sexo", selection: $viewModel.gender) {
                        ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 32)

                // Age
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edad: \(viewModel.age) anos")
                        .font(.headline)
                    Stepper("", value: $viewModel.age, in: 10...100)
                        .labelsHidden()
                }
                .padding(.horizontal, 32)

                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("Peso: \(String(format: "%.1f", viewModel.weight)) kg")
                        .font(.headline)
                    Slider(value: $viewModel.weight, in: 30...200, step: 0.5)
                }
                .padding(.horizontal, 32)

                // Height
                VStack(alignment: .leading, spacing: 8) {
                    Text("Altura: \(String(format: "%.0f", viewModel.height)) cm")
                        .font(.headline)
                    Slider(value: $viewModel.height, in: 100...220, step: 1)
                }
                .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Step 3: Fitness Goal

private struct FitnessGoalStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Objetivo fisico")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 24)

                Text("Selecciona tu objetivo principal.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                        FitnessGoalCard(
                            goal: goal,
                            isSelected: viewModel.fitnessGoal == goal
                        ) {
                            viewModel.fitnessGoal = goal
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

private struct FitnessGoalCard: View {
    let goal: UserProfile.FitnessGoal
    let isSelected: Bool
    let onTap: () -> Void

    private var icon: String {
        switch goal {
        case .loseWeight: return "arrow.down.circle"
        case .maintain: return "equal.circle"
        case .gainMuscle: return "arrow.up.circle"
        }
    }

    private var description: String {
        switch goal {
        case .loseWeight: return "Deficit de 500 kcal para perder grasa"
        case .maintain: return "Mantener tu peso y composicion actual"
        case .gainMuscle: return "Superavit de 300 kcal para ganar masa muscular"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Step 4: Activity Level

private struct ActivityLevelStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Nivel de actividad")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 24)

                Text("Selecciona tu nivel de actividad fisica habitual.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                        ActivityLevelCard(
                            level: level,
                            isSelected: viewModel.activityLevel == level
                        ) {
                            viewModel.activityLevel = level
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

private struct ActivityLevelCard: View {
    let level: UserProfile.ActivityLevel
    let isSelected: Bool
    let onTap: () -> Void

    private var description: String {
        switch level {
        case .sedentary: return "Poco o ningun ejercicio"
        case .light: return "Ejercicio ligero 1-3 dias/semana"
        case .moderate: return "Ejercicio moderado 3-5 dias/semana"
        case .active: return "Ejercicio intenso 6-7 dias/semana"
        case .veryActive: return "Ejercicio muy intenso o trabajo fisico"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}
