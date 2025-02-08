import SwiftUI


struct TrainingListView: View {
    @ObservedObject var viewModel: TrainingListViewModel

    var body: some View {
        List(viewModel.trainings) { training in
            
        }
    }
}

struct TrainingListView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingListBuilder().build()
    }
}
