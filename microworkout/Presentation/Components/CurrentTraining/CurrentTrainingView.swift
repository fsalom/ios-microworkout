import SwiftUI

struct CurrentTrainingView: View {
    @Binding var isPresented: Bool
    @StateObject var viewModel: CurrentTrainingViewModel
    var animation: Namespace.ID

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.blue
                .matchedGeometryEffect(id: "background", in: animation)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }

            VStack {
                getTextTotal()
                    .padding()
                    .foregroundStyle(.blue)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                    )
                    .padding(.bottom, 50)

                // Resto del cuerpo igual pero usando viewModel.training en vez de training...

                Button {
                    viewModel.incrementSet()
                    animatePress()
                } label: {
                    CountdownView(
                        startDate: viewModel.training.sets.last ?? Date(),
                        totalMinutes: viewModel.training.numberOfMinutesPerSet,
                        hasToResetTimer: $viewModel.hasToResetTimer
                    )
                    .padding(5)
                    .background(isPressed ? Color.blue : Color.clear)
                    .overlay(
                        Circle().fill(Color.clear).frame(width: 200, height: 200)
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 100)

                // ...
            }
        }
    }

    func getTextTotal() -> Text {
        Text("Tu entreno actual consiste en un total de ") +
        Text("\(viewModel.totalReps())").fontWeight(.bold) +
        Text(" repeticiones a lo largo de ") +
        Text("\(viewModel.totalDurationInHours())").fontWeight(.bold) +
        Text(" horas")
    }

    func animatePress() {
        withAnimation(.easeOut(duration: 0.2)) {
            isPressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                isPressed = false
            }
        }
    }
}
