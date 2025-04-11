import SwiftUI


struct TrainingDetailView: View {
    @ObservedObject var viewModel: TrainingDetailViewModel

    var body: some View {
        VStack {
            Image(viewModel.training.image)
                .resizable()
                .scaledToFill()
                .frame(height: 300)
                .clipped()
                .matchedGeometryEffect(id: viewModel.training.image, in: viewModel.namespace, isSource: false)
                .opacity(0.5)
            Text(viewModel.training.name)
                .font(.system(size: 50))
                .fontWeight(.bold)
            VStack(alignment: .leading, spacing: 8) {
                Text("\(viewModel.training.numberOfSets) Series")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.gray).opacity(0.5)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                //Slider(value: $viewModel.training.numberOfSetsForSlider, in: 1...20, step: 1)
                Text("\(viewModel.training.numberOfReps) Repeticiones")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.gray).opacity(0.5)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                //Slider(value: $viewModel.training.numberOfRepsForSlider, in: 1...20, step: 1)
                Spacer()
                SliderView(onFinish: {

                }, isWaitingResponse: false)
            }
            .padding()
        }
    }
}

struct TrainingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        @Namespace var namespace
        TrainingDetailBuilder().build(this: Training(name: "example",
                                                     image: "abs-1",
                                                     type: .strength,
                                                     numberOfSetsForSlider: 10,
                                                     numberOfRepsForSlider: 10,
                                                     numberOfMinutesPerSetForSlider: 60),
                                      and: namespace)
    }
}
