import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Namespace var animation
    @State private var selectedTraining: Training? = nil
    @State private var showDetail = false

    var body: some View {
        if showDetail {
            DetailView(animation: animation, showDetail: $showDetail, training: $selectedTraining)
        } else {
            ScrollView {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome back")
                            .font(.footnote)
                            .lineLimit(2)
                        Text("Fernando!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                Text("Últimos entrenamientos")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                ListLastTrainings()

                Divider()
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Progresión ejercicio")
                        .font(.title2)
                        .fontWeight(.bold)

                    HealthWeeksView(weeks: self.$viewModel.weeks)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onAppear {
                //viewModel.load()
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }

    @ViewBuilder
    func ListLastTrainings() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                Text("+")
                    .font(.largeTitle)
                    .frame(width: 100, height: 100)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        viewModel.goToTrainings()
                    }
                ForEach(viewModel.trainings, id: \.id) { training in
                    Image(training.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .matchedGeometryEffect(id: training.image, in: animation, isSource: !showDetail)
                        .mask(RoundedRectangle(cornerRadius: 20.0))
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedTraining = training
                                showDetail = true
                            }
                        }
                }
            }
            .padding()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeBuilder().build()
    }
}
