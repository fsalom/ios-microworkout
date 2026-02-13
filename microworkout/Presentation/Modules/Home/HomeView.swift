import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: HomeViewModel
    @Namespace var animation
    @State private var showDetail = false
    @State private var hasAppeared = false
    @Environment(\.scenePhase) private var scenePhase


    var body: some View {
        ZStack(alignment: .top) {
            List {
                CalorieProgressCard()
                    .padding(.horizontal, 8)
                    .listRowSeparator(.hidden)

                HealthGrid()
                    .padding(.horizontal, 8)
                    .listRowSeparator(.hidden)

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
            .background(Color.white)
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
            .background(Color.white)
        }
    }

    @ViewBuilder
    func CalorieProgressCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calorias de hoy")
                .font(.headline)
                .fontWeight(.bold)

            if viewModel.uiState.hasCycling {
                Text(viewModel.uiState.todayIsFreeDay ? "Dia libre" : "Dia estricto")
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

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 24)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(calorieBarColor(ratio: ratio))
                            .frame(width: geometry.size.width * CGFloat(min(progress, 1.0)), height: 24)
                    }
                }
                .frame(height: 24)

                Text("\(Int(consumed)) / \(Int(target)) kcal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let macros = viewModel.uiState.macroTargets {
                    let nutrition = viewModel.uiState.todayNutrition
                    MacroBar(label: "Proteina", current: nutrition.proteins, target: macros.proteins, color: .purple)
                    MacroBar(label: "Carbos", current: nutrition.carbohydrates, target: macros.carbohydrates, color: .orange)
                    MacroBar(label: "Grasa", current: nutrition.fats, target: macros.fats, color: .yellow)
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    func MacroBar(label: String, current: Double, target: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(current))g / \(Int(target))g")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(target > 0 ? min(current / target, 1.0) : 0), height: 6)
                }
            }
            .frame(height: 6)
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
    func HealthGrid() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(viewModel.uiState.healthInfoForToday.dateWithFormat)")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                ForEach([
                    ("\(viewModel.uiState.healthInfoForToday.steps)", "Pasos"),
                    ("\(viewModel.uiState.healthInfoForToday.minutesOfExercise)", "Min. ejercicio"),
                    ("\(viewModel.uiState.healthInfoForToday.minutesStanding)", "Min. de pie")
                ], id: \.1) { value, label in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(value)
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                        Text(label)
                            .font(.footnote)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
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
            ForEach(viewModel.uiState.lastEntriesByDay) { entryDay in
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeBuilder().build(appState: AppState())
    }
}
