import SwiftUI

struct TrainingDetailV2View: View {
    @Namespace var animation
    @State private var numberOfSetsForSlider: Double = 1
    @State private var numberOfRepsForSlider: Double = 1
    @State private var numberOfMinutesPerSetForSlider: Double = 10
    @State var hasTrainingStarted: Bool = false
    @ObservedObject var viewModel: TrainingDetailV2ViewModel

    var body: some View {
        if hasTrainingStarted {
            CurrentTrainingView(isPresented: $hasTrainingStarted,
                                training: $viewModel.training,
                                animation: animation)
        } else {
            VStack{
                ZStack(alignment: .top) {
                    GeometryReader { geometry in
                        Image(viewModel.training.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20.0)) // Aplica el redondeo correctamente
                    }
                    .frame(height: 300)
                    Text(viewModel.training.name)
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .padding(.top, 150)
                        .foregroundStyle(.white)
                        .shadow(radius: 10)
                    dismissButton
                }
                VStack {
                    VStack(alignment: .leading, spacing: 8) {
                        getSlidersView()
                        getTextTotal()
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.gray.opacity(0.2))
                            )
                        Spacer()
                        SliderView(
                            onFinish: {
                                viewModel.training.startedAt = Date()
                                withAnimation {
                                    hasTrainingStarted = true
                                }
                            },
                            isWaitingResponse: false)
                        .matchedGeometryEffect(id: "background", in: animation)
                    }
                    .padding(16)
                }
                .padding(.bottom, 60)
            }
            .navigationBarBackButtonHidden()
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                updateSliderValues()
            }
        }
    }

    func updateSliderValues() {
        numberOfSetsForSlider = Double(viewModel.training.numberOfSets)
        numberOfRepsForSlider = Double(viewModel.training.numberOfReps)
        numberOfMinutesPerSetForSlider = Double(viewModel.training.numberOfMinutesPerSet)
    }

    @ViewBuilder
    func getTextTotal() -> Text {
        Text("Así harás un total de ") +
        Text("\(viewModel.training.numberOfReps*viewModel.training.numberOfSets)").fontWeight(.bold) +
        Text(" repeticiones a lo largo de ") +
        Text("\(Int(viewModel.training.numberOfMinutesPerSet*viewModel.training.numberOfSets)/60)").fontWeight(.bold) +
        Text(" horas (aproximadamente)")

    }

    @ViewBuilder
    func getSlidersView() -> some View {
        VStack {
            Text("\(viewModel.training.numberOfSets) series")
                .fontWeight(.bold)
            Slider(value: $viewModel.training.numberOfSetsForSlider, in: 1...20, step: 1)

            Divider()

            Text("\(viewModel.training.numberOfReps) repeticiones")
                .fontWeight(.bold)
            Slider(value: $viewModel.training.numberOfRepsForSlider, in: 1...20, step: 1)

            Divider()

            Text("\(viewModel.training.numberOfMinutesPerSet) minutos entre series")
                .fontWeight(.bold)
            Slider(value: $viewModel.training.numberOfMinutesPerSetForSlider, in: 10...120, step: 10)
        }
    }

    var dismissButton: some View {
        HStack {
            Spacer()
            Button {
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(uiColor: .black))
                    .background(Color(uiColor: .white))
                    .clipShape(Circle())
                    .padding(.top, 60)
                    .padding(.trailing, 40)
            }
        }
    }
}
