import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: HomeViewModel
    @Namespace var animation
    @State private var showDetail = false
    @State private var hasAppeared = false
    @State private var macrosExpanded = false
    @State private var macrosNaturalHeight: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase


    var body: some View {
        ScrollView {
            content
                .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.hidden)
        .pinnedTabHeader(subtitle: "BIENVENIDO", title: welcomeTitle)
        .onAppear {
            if !hasAppeared {
                viewModel.start()
                viewModel.loadWeeksWithHealthInfo()
                hasAppeared = true
            } else {
                viewModel.load()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && hasAppeared {
                viewModel.loadWeeksWithHealthInfo()
            }
        }
        .onChange(of: appState.selectedTab) { _, newTab in
            if newTab == 0 {
                viewModel.load()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            viewModel.loadWeeksWithHealthInfo()
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .mealsChanged)) { _ in
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutLogsChanged)) { _ in
            viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            if viewModel.uiState.isLoadingCalories {
                SkeletonCard(height: 130)
                    .padding(.horizontal, 8)
            } else {
                CalorieProgressCard()
                    .padding(.horizontal, 8)
            }

            TodayTrainingCard(
                workouts: viewModel.uiState.todayHealthWorkouts,
                burned: viewModel.uiState.caloriesBurnedToday,
                onSeeAll: { appState.selectedTab = 1 }
            )
            .padding(.horizontal, 8)

            if viewModel.uiState.isLoadingHealth {
                SkeletonStatsRow()
                    .padding(.horizontal, 8)
            } else {
                TodayStatsSection()
                    .padding(.horizontal, 8)
            }

            if viewModel.uiState.isLoadingHealth {
                SkeletonHeatmap()
                    .padding(.horizontal, 8)
            } else {
                HealthGrid()
                    .padding(.horizontal, 8)
            }

            if !viewModel.uiState.lastTrainings.isEmpty {
                Text("Micro entrenamientos")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)

                ListMicroTrainings()
            }
        }
    }

    private var welcomeTitle: String {
        if let name = viewModel.uiState.userName, !name.isEmpty {
            return name
        }
        return "Hola"
    }

    @ViewBuilder
    func CalorieProgressCard() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Calorías de hoy")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { appState.selectedTab = 3 }) {
                    Text("Añadir")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if viewModel.uiState.hasCycling {
                Text(viewModel.uiState.todayIsFreeDay ? "Día libre" : "Día estricto")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(viewModel.uiState.todayIsFreeDay ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(viewModel.uiState.todayIsFreeDay ? .green : .blue)
                    .cornerRadius(6)
            }

            if let target = viewModel.uiState.dailyCalorieTarget {
                let consumed = viewModel.uiState.todayCalories
                let progress = min(consumed / target, 1.5)
                let ratio = consumed / target

                ProgressBar(progress: min(progress, 1.0), color: calorieBarColor(ratio: ratio), height: 8)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        macrosExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("\(Int(consumed))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("/ \(Int(target)) kcal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        if viewModel.uiState.macroTargets != nil {
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(macrosExpanded ? 180 : 0))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.uiState.macroTargets == nil)

                if let macros = viewModel.uiState.macroTargets {
                    let nutrition = viewModel.uiState.todayNutrition
                    VStack(spacing: 10) {
                        MacroBar(label: "Proteína", current: nutrition.proteins, target: macros.proteins, color: .green)
                        MacroBar(label: "Carbos", current: nutrition.carbohydrates, target: macros.carbohydrates, color: .orange)
                        MacroBar(label: "Grasa", current: nutrition.fats, target: macros.fats, color: Color.orange.opacity(0.7))
                    }
                    .padding(.top, 4)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: MacrosHeightKey.self, value: proxy.size.height)
                        }
                    )
                    .frame(height: macrosExpanded ? macrosNaturalHeight : 0, alignment: .top)
                    .clipped()
                    .onPreferenceChange(MacrosHeightKey.self) { newHeight in
                        if newHeight > 0 { macrosNaturalHeight = newHeight }
                    }
                }
            } else {
                let consumed = viewModel.uiState.todayCalories
                Text("\(Int(consumed)) kcal consumidas")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Configura tu perfil para ver tu objetivo diario")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    @ViewBuilder
    func ProgressBar(progress: Double, color: Color, height: CGFloat) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: height)
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(progress), height: height)
            }
        }
        .frame(height: height)
    }

    @ViewBuilder
    func MacroBar(label: String, current: Double, target: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(Int(current))g")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("/ \(Int(target))g")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            ProgressBar(
                progress: target > 0 ? min(current / target, 1.0) : 0,
                color: color,
                height: 5
            )
        }
    }

    private func calorieBarColor(ratio: Double) -> Color {
        if ratio > 1.0 {
            return .red
        } else if ratio > 0.8 {
            return .orange
        } else {
            return .green
        }
    }

    @ViewBuilder
    func TodayStatsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hoy")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                StatCard(value: "\(formattedNumber(viewModel.uiState.healthInfoForToday.steps))", label: "Pasos")
                StatCard(value: "\(viewModel.uiState.healthInfoForToday.minutesOfExercise)", label: "Min. ejercicio")
                StatCard(value: "\(viewModel.uiState.healthInfoForToday.minutesStanding)", label: "Min. de pie")
            }
        }
    }

    @ViewBuilder
    func StatCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private func formattedNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    @ViewBuilder
    func HealthGrid() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progresión ejercicio")
                .font(.title2)
                .fontWeight(.bold)
            HealthWeeksView(
                weeks: self.$viewModel.uiState.weeks,
                selectedDate: viewModel.uiState.healthInfoForToday.date
            ) { day in
                self.viewModel.showHealthInfo(for: day)
            }
        }
    }


    @ViewBuilder
    func ListMicroTrainings() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(viewModel.uiState.lastTrainings, id: \.id) { training in
                    Image(training.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .mask(RoundedRectangle(cornerRadius: 20.0))
                        .onTapGesture {
                            viewModel.goToStart(this: training)
                        }
                }
            }
            .padding(0)
        }
    }
}

// MARK: - Today Training Card

private struct TodayTrainingCard: View {
    let workouts: [HealthWorkout]
    let burned: Double
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Entrenado hoy")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onSeeAll) {
                    Text("Ver")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if workouts.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("Sin entrenamientos hoy")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("\(Int(burned)) kcal quemadas")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 0) {
                    ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                        TodayWorkoutRow(workout: workout)
                            .padding(.vertical, 10)
                        if index < workouts.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

private struct TodayWorkoutRow: View {
    let workout: HealthWorkout

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 32, height: 32)
                .background(Color.green.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.activityTypeName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("\(workout.timeRangeFormatted) · \(workout.durationFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                if let cal = workout.caloriesFormatted {
                    Label(cal, systemImage: "flame.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                if let hr = workout.heartRateFormatted {
                    Label(hr, systemImage: "heart.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Skeleton loaders

private struct SkeletonCard: View {
    let height: CGFloat
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemGroupedBackground))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .opacity(pulse ? 0.3 : 0.7)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

private struct SkeletonStatsRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 22)

            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCard(height: 90)
                }
            }
        }
    }
}

private struct SkeletonHeatmap: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 160, height: 22)

            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 40)
                }
            }
        }
    }
}

private struct MacrosHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeBuilder(component: DefaultAppComponent.preview).build(appState: AppState())
    }
}
