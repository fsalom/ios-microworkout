import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: HomeViewModel
    @Namespace var animation
    @State private var showDetail = false
    @State private var hasAppeared = false
    @State private var macrosExpanded = false
    @State private var macrosNaturalHeight: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase


    var body: some View {
        ZStack(alignment: .top) {
            List {
                CalorieProgressCard()
                    .padding(.horizontal, 8)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                TodayStatsSection()
                    .padding(.horizontal, 8)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                HealthGrid()
                    .padding(.horizontal, 8)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                Text("Micro entrenamientos")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .listRowSeparator(.hidden)

                ListMicroTrainings()
                    .listRowSeparator(.hidden)

                Text("Últimos entrenamientos")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .listRowSeparator(.hidden)

                ListLastLoggedExercises()
                    .padding(.horizontal, 8)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .padding(0)
            .onAppear {
                if !hasAppeared {
                    viewModel.loadWeeksWithHealthInfo()
                    hasAppeared = true
                }
                viewModel.load()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active && hasAppeared {
                    viewModel.loadWeeksWithHealthInfo()
                }
            }
            .background(Color(.systemGroupedBackground))
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .navigationTitle("hola")
            .navigationBarTitleDisplayMode(.large)

        }
        .statusBarHidden(true)
        .safeAreaInset(edge: .top) {
            VStack {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.gray)
                        .clipShape(Circle())
                    VStack(alignment: .leading) {
                        Text("Bienvenido")
                        Text(viewModel.uiState.userName ?? "Fernando")
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                Divider()
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .background(Color(.systemBackground))
        }
    }

    @ViewBuilder
    func CalorieProgressCard() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Calorías de hoy")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { viewModel.goToAddMeal() }) {
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
            HealthWeeksView(weeks: self.$viewModel.uiState.weeks) { day in
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

    @ViewBuilder
    func ListLastLoggedExercises() -> some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.uiState.lastWorkoutItems) { item in
                switch item {
                case .manual(let entryDay):
                    HStack(spacing: 10) {
                        if let parts = entryDay.dateParts {
                            DateBadge(day: parts.day, monthName: parts.monthName)
                        }
                        VStack(alignment: .leading) {
                            Text(entryDay.exercisesFormatted).fontWeight(.bold)
                            Text(entryDay.totalSeriesFormatted).fontWeight(.bold)
                            Text(entryDay.durationFormatted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        viewModel.goTo(this: entryDay)
                    }
                case .appleWatch(let workout):
                    AppleWatchWorkoutCard(workout: workout)
                        .onTapGesture {
                            viewModel.goTo(this: workout)
                        }
                }
            }
        }
    }


    @ViewBuilder
    func ListLastTrainings() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                Text("+")
                    .font(.largeTitle)
                    .frame(width: 100, height: 100)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        viewModel.goToTrainings()
                    }
                ForEach(viewModel.uiState.trainings, id: \.id) { training in
                    Image(training.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .matchedGeometryEffect(id: training.image, in: animation, isSource: !showDetail)
                        .mask(RoundedRectangle(cornerRadius: 20.0))
                        .onTapGesture {
                            viewModel.goToStart(this: training)
                        }
                }
            }
            .padding()
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
        HomeBuilder(component: DefaultAppComponent()).build(appState: AppState())
    }
}
