import SwiftUI


struct TrainingDetailView: View {
    @ObservedObject var viewModel: TrainingDetailViewModel

    var body: some View {
        Text("To be implemented")
        SliderView(onFinish: {

        }, isWaitingResponse: false)
    }
}

struct TrainingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingDetailBuilder().build()
    }
}
