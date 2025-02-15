import SwiftUI


struct TrainingListView: View {
    @ObservedObject var viewModel: TrainingListViewModel

    var body: some View {
        VStack {
            switch viewModel.typeOfList {
            case .horizontal:
                getListHorizontal()
            case .vertical:
                getListVertical()
            }
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    viewModel.changeListType()
                }) {
                    Image(systemName: viewModel.typeOfList == .horizontal ? "arrow.up.and.down" : "arrow.left.and.right")
                        .tint(Color.black)
                }
            }
        }
        .navigationTitle("Entrenamientos")
        .toolbarTitleDisplayMode(.large)
    }

    @ViewBuilder
    func getListVertical() -> some View {
        ScrollView(.vertical) {
            VStack {
                ForEach(viewModel.trainings, id: \.id) { training in
                    ZStack {
                        Image(training.image)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .padding(10)
                    .background(content: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                    })
                    .visualEffect { content, proxy in
                        let frame = proxy.frame(in: .scrollView(axis: .vertical))
                        _ = proxy
                            .bounds(of: .scrollView(axis: .vertical)) ??
                            .infinite
                        let distance = min(0, frame.minY)

                        return content
                            .scaleEffect(1 + distance / 700)
                            .offset(y: -distance / 1.25)
                            .brightness(-distance / 400)
                            .blur(radius: -distance / 50)
                    }
                    .onTapGesture {
                        viewModel.goToWorkout()
                    }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    func getListHorizontal() -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 16) {
                ForEach(viewModel.trainings, id: \.id) { training in
                    VStack {
                        ZStack {
                            Image(training.image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 600)
                            .opacity(0.5)
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content
                                        .offset(x: phase.isIdentity ? 0 : phase.value * -200)
                                }
                            VStack {
                                Text(training.name)
                                    .font(.system(size: 40))
                                    .fontWeight(.black)
                                    .padding(0)
                                Divider()
                                    .background(.black)
                                    .frame(width:200, height: 1)
                                HStack {
                                    Text("\(training.numberOfSets)").fontWeight(.bold)
                                    +
                                    Text(" sets")
                                    Text("\(training.numberOfReps)").fontWeight(.bold)
                                    +
                                    Text(" reps")
                                }
                            }
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content
                                        .offset(x: phase.value * 100)
                                }
                        }
                        .containerRelativeFrame(.horizontal)
                        .clipShape(RoundedRectangle(cornerRadius: 36))
                    }
                    .onTapGesture {
                        viewModel.goToWorkout()
                    }
                }
            }
        }
        .contentMargins(32)
        .scrollTargetBehavior(.paging)
    }
}



struct TrainingListView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingListBuilder().build()
    }
}
