import SwiftUI

struct CurrentTrainingView: View {
    @ObservedObject var viewModel: CurrentTrainingViewModel
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .top) {
            
            Color.blue
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    closeButton()
                }.padding(.horizontal, 16)
                Text(viewModel.uiState.training.name.uppercased())
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .padding(.vertical, 20)
                styledInfoText(getTextTotal())
                getTextCurrentTotal()
                    .foregroundStyle(.white)
                    .padding(.bottom, 100)
                Spacer()
                CountdownButtonView(
                    hasToResetTimer: $viewModel.uiState.hasToResetTimer,
                    sets: $viewModel.uiState.training.sets,
                    startDate: viewModel.uiState.training.sets.last ?? Date(),
                    totalMinutes: (viewModel.uiState.training.numberOfMinutesPerSet),
                    limitOfSets: viewModel.uiState.training.numberOfSets
                ) {
                    viewModel.incrementSet()
                } end: {
                    viewModel.incrementSet()
                }
                .padding(.bottom, 100)
            }
        }
        .navigationBarBackButtonHidden()
    }

    func getTextTotal() -> Text {
        Text("Tu entreno actual consiste en un total de ") +
        Text("\(viewModel.getTotalReps())").fontWeight(.bold) +
        Text(" repeticiones a lo largo de ") +
        Text("\(viewModel.getTotalDurationInHours())").fontWeight(.bold) +
        Text(" horas")
    }

    @ViewBuilder
    func getTextCurrentTotal() -> some View {
        HStack(spacing: 50){
            VStack(spacing: 10){
                Text("\(viewModel.getCurrentSets())/\(viewModel.uiState.training.numberOfSets)")
                    .font(.system(size: 60))
                    .fontWeight(.bold)
                Text("Ronda")
                    .font(.footnote)
            }
            VStack(spacing: 10){
                Text("\(viewModel.getCurrentTotalReps())")
                    .font(.system(size: 60))
                    .fontWeight(.bold)
                Text("Repeticiones")
                    .font(.footnote)
            }
            VStack(spacing: 10){
                Text("\(viewModel.uiState.training.numberOfMinutes)")
                    .font(.system(size: 60))
                    .fontWeight(.bold)
                Text("Minutos")
                    .font(.footnote)
            }
        }
    }

    func animatePress() {
        withAnimation(.easeOut(duration: 0.1)) {
            isPressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.2)) {
                isPressed = false
            }
        }
    }

    @ViewBuilder
    func styledInfoText(_ text: Text) -> some View {
        text
            .padding()
            .foregroundStyle(.blue)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
            )
            .padding(.bottom, 20)
            .padding(.top, 20)
    }

    @ViewBuilder
    func closeButton() -> some View {
        Button(action: {
            self.viewModel.close()
        }) {
            ZStack{
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 40)
                Image(systemName: "xmark")
                    .foregroundColor(.blue)
            }
        }
    }
}
