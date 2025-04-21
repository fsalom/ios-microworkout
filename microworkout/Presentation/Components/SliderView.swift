import SwiftUI

struct SliderView: View {
    @State private var offset: CGFloat = 5
    @State private var isComplete: Bool = false
    var message: String = "Desliza para iniciar"
    var backgroundColor: Color = .gray
    var frontColor: Color = .black
    var successColor: Color = .green
    let sliderHeight: CGFloat = 60
    @State private var offsetAnimation: CGFloat = 200

    var onFinish: () -> Void

    var isWaitingResponse: Bool


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let sliderWidth = geometry.size.width

                // Background track
                RoundedRectangle(cornerRadius: 12)
                    .fill(isComplete ? successColor : backgroundColor.opacity(0.3))
                    .frame(height: sliderHeight)

                // Label
                HStack {
                    Text(isComplete ? "Cargando..." : (isWaitingResponse ? "Cargando..." : message))
                        .foregroundColor(frontColor)
                        .font(.system(size: 17, weight: .bold))
                }
                // Draggable button
                button().offset(x: offset - (sliderWidth / 2 - sliderHeight / 2))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if !isComplete {
                                    let maxOffset = sliderWidth - sliderHeight - 5
                                    offset = max(0, min(gesture.translation.width, maxOffset))
                                }
                            }
                            .onEnded { _ in
                                let threshold = sliderWidth - sliderHeight - 5
                                if offset >= threshold {
                                    withAnimation {
                                        isComplete = true
                                        onFinish()
                                    }
                                } else {
                                    withAnimation {
                                        offset = 5
                                    }
                                }
                            }
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: sliderHeight)
        }
        .frame(height: sliderHeight)
        .transition(.opacity)
        .offset(x: offsetAnimation)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.5)) {
                offsetAnimation = 0
            }
        }
        .onChange(of: isWaitingResponse) { (_ , newValue) in
            if newValue == false {
                self.offset = 5
                self.isComplete = false
            }
        }
    }

    @ViewBuilder
    func button() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isComplete ? successColor : backgroundColor)
                .frame(width: sliderHeight, height: sliderHeight - 10)
            if isWaitingResponse {
                ProgressView()
                    .frame(width: 25, height: 25, alignment: .center)
            } else {
                Image("ic_slide_arrow")
                    .renderingMode(.template)
                    .resizable()
                //.opacity(0.5)
                    .frame(width: 25, height: 25, alignment: .center)
                    .tint(frontColor)
                    .foregroundColor(frontColor)
            }

        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


// Preview
struct CheckOutView_Previews: PreviewProvider {
    static var previews: some View {
        SliderView(onFinish: {},
                   isWaitingResponse: false
        )
    }
}
