import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: HomeViewModel
    @Namespace var animation
    @State private var showDetail = false
    @State private var hasAppeared = false
    @Environment(\.scenePhase) private var scenePhase


    var body: some View {
        ScrollView {
            // HEADER
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome back")
                        .font(.footnote)
                        .lineLimit(2)
                    Text("Fernando!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // TODAY HEALTH INFO
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // HEALTH CALENDAR
            VStack(alignment: .leading, spacing: 10) {
                Text("Progresión ejercicio")
                    .font(.title2)
                    .fontWeight(.bold)
                HealthWeeksView(weeks: self.$viewModel.uiState.weeks) { day in
                    self.viewModel.showHealthInfo(for: day)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 16)

            // MICRO WORKOUT
            Text("Micro entrenamientos")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            ListLastTrainings()

            Divider()
                .padding(.horizontal, 16)

        }
        .onAppear {
            if !hasAppeared {
                viewModel.loadWeeksWithHealthInfo()
                hasAppeared = true
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && hasAppeared {
                viewModel.loadWeeksWithHealthInfo()
            }
        }
        .edgesIgnoringSafeArea(.bottom)
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
                            viewModel.goToStart(this: training, and: animation)
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
