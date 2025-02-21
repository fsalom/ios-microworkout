import SwiftUI


struct TrainingListView: View {
    @ObservedObject var viewModel: TrainingListViewModel
    @Namespace var animation
    @State var selectedTraining = Training(name: "", image: "", type: .cardio, numberOfSets: 0, numberOfReps: 0, numberOfMinutesPerSet: 0)
    @State var showDetail: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollPosition: UUID? = nil


    var body: some View {
        if showDetail {
            getDetail()
        } else {
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
        /*
            .fullScreenCover(isPresented: Binding<Bool>(
                get: { showDetail && !image.isEmpty },
                set: { showDetail = $0 }
            )) {
                getDetail()
            }*/
        }
    }

    @ViewBuilder
    func getListVertical() -> some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical) {
                VStack {
                    ForEach(viewModel.trainings, id: \.id) { training in
                        TrainingRow(with: training)
                            .id(training.id) // Identificador para restaurar la posición
                    }
                }
                .padding()
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                if let position = scrollPosition {
                                    DispatchQueue.main.async {
                                        scrollView.scrollTo(position, anchor: .top) // Restaura la posición
                                    }
                                }
                            }
                    }
                )
            }
        }
    }


    @ViewBuilder
    func TrainingRow(with training: Training) -> some View {
        ZStack {
            Image(training.image)
                .resizable()
                .scaledToFill()
                .opacity(0.7)
                .matchedGeometryEffect(id: training.image, in: animation, isSource: !showDetail)
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
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                self.scrollPosition = training.id
                self.selectedTraining = training
                self.showDetail = true
            }
            //viewModel.goTo(training)
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
    }

    @ViewBuilder
    func getListHorizontal() -> some View {
        ScrollViewReader { scrollView in
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
                                    .matchedGeometryEffect(id: training.image, in: animation, isSource: !showDetail)
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
                                        .frame(width: 200, height: 1)
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
                            .onAppear {
                                if let position = scrollPosition {
                                    DispatchQueue.main.async {
                                        scrollView.scrollTo(position, anchor: .center) // Restaurar la posición
                                    }
                                }
                            }
                            .overlay( // Overlay transparente para capturar el toque
                                Color.clear
                                    .contentShape(Rectangle()) // Asegura que toda el área sea interactuable
                                    .onTapGesture {
                                        withAnimation(.linear(duration: 1.0)) {
                                            self.scrollPosition = training.id
                                            self.selectedTraining = training
                                            self.showDetail = true
                                        }
                                        //viewModel.goTo(training)
                                    }
                            )
                        }
                    }
                }
            }
            .contentMargins(32)
            .scrollTargetBehavior(.paging)
        }
    }

    struct RoundedCorner: Shape {
        var radius: CGFloat
        var corners: UIRectCorner

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            return Path(path.cgPath)
        }
    }

    @ViewBuilder
    func getDetail() -> some View {
        ZStack {
            Color.white
            VStack {
                ZStack(alignment: .top) {
                    VStack {
                        Image(selectedTraining.image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .matchedGeometryEffect(id: selectedTraining.image, in: animation, isSource: showDetail)
                            .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                        VStack(alignment: .leading, spacing: 8){
                            Text("\(selectedTraining.numberOfSets) Series")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.gray).opacity(0.5)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Slider(value: $selectedTraining.numberOfSetsForSlider, in: 1...20, step: 1)
                            Text("\(selectedTraining.numberOfReps) Repeticiones")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.gray).opacity(0.5)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Slider(value: $selectedTraining.numberOfRepsForSlider, in: 1...20, step: 1)
                            Text("Una serie cada \(selectedTraining.numberOfMinutesPerSet) minutos")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.gray).opacity(0.5)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Slider(value: $selectedTraining.numberOfMinutesPerSetForSlider, in: 5...120, step: 5)
                            Spacer()
                            SliderView(onFinish: {

                            }, isWaitingResponse: false)
                        }
                        .padding()
                        .padding(.bottom, 60)
                    }

                    dismissButton
                }
                Spacer()
            }

        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarBackButtonHidden()
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
            }
            .padding([.top], 60)
            .padding([.trailing], 30)
        }
    }
}



struct TrainingListView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingListBuilder().build()
    }
}
