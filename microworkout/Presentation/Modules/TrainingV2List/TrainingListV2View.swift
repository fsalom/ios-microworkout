import SwiftUI


struct TrainingListV2View: View {
    @ObservedObject var viewModel: TrainingListV2ViewModel
    @Namespace var animation
    @State var selectedTraining: Training?
    @State var showDetail: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollPosition: UUID? = nil
    
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical) {
                VStack {
                    ForEach(viewModel.trainings, id: \.id) { training in
                        TrainingRow(with: training)
                    }
                }
                .padding()
            }
        }
    }
    
    
    @ViewBuilder
    func TrainingRow(with training: Training) -> some View {
        VStack {
            Image(training.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
                .matchedGeometryEffect(id: training.image, in: animation, isSource: showDetail)
                .mask(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .trailing) {
                Text(training.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                HStack {
                    Spacer()
                    Text("\(training.numberOfSets)").fontWeight(.bold)
                    +
                    Text(" sets")
                    Text("\(training.numberOfReps)").fontWeight(.bold)
                    +
                    Text(" reps")
                }
            }.padding()
        }
        .onTapGesture {
            withAnimation(.easeInOut) {
                self.showDetail = true
                self.selectedTraining = training
            }
        }
        .padding(10)
    }
}


struct TrainingListV2View_Previews: PreviewProvider {
    static var previews: some View {
        TrainingListBuilder().build()
    }
}
