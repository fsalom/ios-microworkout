//
//  CustomSlider.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 11/7/23.
//

import SwiftUI

struct CustomSlider: View {
    var maxHeight: CGFloat = 200
    @State var weight: Float
    @State var sliderHeight: CGFloat = 0
    @State var lastDragValue: CGFloat = 0
    var maxValue: CGFloat = 200
    var minValue: CGFloat = 0

    var body: some View {
        VStack {
            Text("Peso")
            Text("\(sliderHeight.formatted)")
                .padding(10)
                .font(.largeTitle)
                .textFieldStyle(.roundedBorder)
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.gray)
                    .opacity(0.5)
                Rectangle()
                    .fill(.gray)
                    .frame(height: sliderHeight)
                Divider().offset(y:100)
            }.frame(width: 100, height: maxHeight)
                .cornerRadius(20)
                .gesture(DragGesture(minimumDistance: 1).onChanged({ value in
                    let translation = value.translation
                    let newValue = -translation.height + lastDragValue

                    if newValue > maxValue {
                        sliderHeight = maxValue
                        return
                    }
                    if newValue < minValue {
                        sliderHeight = minValue
                        return
                    }
                    sliderHeight = newValue
                }).onEnded({ value in
                    let percentage = (minValue * maxHeight) / maxValue
                    maxValue
                    lastDragValue = sliderHeight
                }))
        }.padding(16)
    }
}
