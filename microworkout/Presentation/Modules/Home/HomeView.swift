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
                        Text("Fernando")
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
