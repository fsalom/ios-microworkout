import SwiftUI

struct DetailView: View {
    var animation: Namespace.ID
    @State private var numberOfSetsForSlider: Double = 1
    @State private var numberOfRepsForSlider: Double = 1
    @State private var numberOfMinutesPerSetForSlider: Double = 10
    @Binding var showDetail: Bool
    @Binding var training: Training
    @State var hasTrainingStarted: Bool = false

    var body: some View {
        if hasTrainingStarted {
            CurrentTrainingBuilder().build(appState: AppState())
        } else {
            VStack{
                ZStack(alignment: .top) {
                    GeometryReader { geometry in
                        Image(training.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: 300)
                            .matchedGeometryEffect(id: training.image, in: animation, isSource: showDetail)
                            .clipShape(RoundedRectangle(cornerRadius: 20.0)) // Aplica el redondeo correctamente
                    }
                    .frame(height: 300)
                    Text(training.name)
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
                                training.startedAt = Date()
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

            numberOfSetsForSlider = Double(training.numberOfSets)
            numberOfRepsForSlider = Double(training.numberOfReps)
            numberOfMinutesPerSetForSlider = Double(training.numberOfMinutesPerSet)

    }

    @ViewBuilder
    func getTextTotal() -> Text {
        Text("Así harás un total de ") +
        Text("\(training.numberOfReps*training.numberOfSets)").fontWeight(.bold) +
        Text(" repeticiones a lo largo de ") +
        Text("\(Int(training.numberOfMinutesPerSet*training.numberOfSets)/60)").fontWeight(.bold) +
        Text(" horas (aproximadamente)")

    }

    @ViewBuilder
    func getSlidersView() -> some View {
            VStack {
                /*
                Text("\(training.numberOfSets) series")
                    .fontWeight(.bold)
                Slider(value: $numberOfSetsForSlider, in: 1...20, step: 1, onEditingChanged: { _ in
                    self.training.numberOfSets = Int(numberOfSetsForSlider)
                })

                Divider()

                Text("\(training.numberOfReps) repeticiones")
                    .fontWeight(.bold)
                Slider(value: $numberOfRepsForSlider, in: 1...20, step: 1, onEditingChanged: { _ in
                    self.training.numberOfReps = Int(numberOfRepsForSlider)
                })

                Divider()

                Text("\(training.numberOfMinutesPerSet) minutos entre series")
                    .fontWeight(.bold)
                Slider(value: $numberOfMinutesPerSetForSlider, in: 10...120, step: 10, onEditingChanged: { _ in
                    self.training.numberOfMinutesPerSet = Int(numberOfMinutesPerSetForSlider)
                })*/
            }
    }

    var dismissButton: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.smooth) {
                    showDetail = false
                }
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
