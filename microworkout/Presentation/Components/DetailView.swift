import SwiftUI

struct DetailView: View {
    var animation: Namespace.ID
    @Binding var showDetail: Bool
    @Binding var training: Training
    @State private var showContent: Bool = false // Asegurar que siempre comienza en false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Image(training.image)
                    .resizable()
                    .frame(height: 300)
                    .matchedGeometryEffect(id: training.image, in: animation, isSource: false)
                    .clipped()
                    .mask(RoundedRectangle(cornerRadius: 20.0))

                if showContent {
                    Text(training.name)
                        .font(.system(size: 50))
                        .fontWeight(.bold)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(training.numberOfSets) Series")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.gray).opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Slider(value: $training.numberOfSetsForSlider, in: 1...20, step: 1)
                        Text("\(training.numberOfReps) Repeticiones")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.gray).opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Slider(value: $training.numberOfRepsForSlider, in: 1...20, step: 1)
                        Spacer()
                        SliderView(onFinish: {}, isWaitingResponse: false)
                    }
                    .padding()
                } else {
                    Spacer()
                }
            }
            .padding(.bottom, 60)
            dismissButton
        }
        .navigationBarBackButtonHidden()
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            // Resetear el contenido antes de animar
            showContent = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showContent = true
            }
        }
    }

    var dismissButton: some View {
        Button {
            showContent = false // Resetear contenido antes de cerrar la vista
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
