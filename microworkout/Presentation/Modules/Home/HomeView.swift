import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image("splash")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome back")
                            .font(.footnote)
                            .lineLimit(2)
                        Text("Fernando!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Image(systemName: "bell")
                    }
                }
                Text("Últimos entrenamientos")
                    .font(.footnote)
                ListLastTrainings()
                Text("Progresión de la semana")
                    .font(.footnote)
                DynamicGridView(columnCount: 7, rowCount: 4)

            }
            .padding()
        }
        .navigationTitle("Entrenamientos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            //viewModel.load()
        }
        .edgesIgnoringSafeArea(.bottom)
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
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 100, maxHeight: 100)
                        .opacity(1.0)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
