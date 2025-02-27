//
//  CurrentTrainingView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 23/2/25.
//

import SwiftUI

struct CurrentTrainingView: View {
    @Binding var isPresented: Bool
    @Binding var training: Training?
    @State var hasToResetTimer = false
    @State private var isPressed = false
    var animation: Namespace.ID

    var body: some View {
        ZStack(alignment: .top) {
            Color.blue
                .matchedGeometryEffect(id: "background", in: animation)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            VStack{
                getTextTotal()
                    .padding()
                    .foregroundStyle(.blue)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                    )
                    .padding(.bottom, 50)
                HStack(spacing: 10) {
                    VStack {
                        Text("\(training!.numberOfSetsCompleted)")
                            .font(.title)
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                        Text("Series")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Text("\(training!.numberOfSetsCompleted*training!.numberOfReps)")
                            .font(.title)
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                        Text("Repeticiones")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Text(training!.startedAt!, style: .timer)
                            .font(.title)
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                        Text("Tiempo")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 100)
                Button {
                    training?.numberOfSetsCompleted += 1
                    hasToResetTimer = true
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            isPressed = false
                        }
                    }
                } label: {
                    CountdownView(startDate:training?.sets.last ?? Date(), totalMinutes: training!.numberOfMinutesPerSet, hasToResetTimer: $hasToResetTimer)
                        .padding(5)
                        .background(isPressed ? Color.blue : Color.clear)
                        .overlay(
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 200, height: 200)
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 100)
                Text("Pulsa al completar la serie")
                    .font(.footnote)
                    .foregroundStyle(.white)
                Spacer()
                SliderView(
                    message: "Finalizar",
                    backgroundColor: .white,
                    frontColor: .blue,
                    onFinish: {
                        withAnimation {
                            isPresented = false
                        }
                    },
                    isWaitingResponse: false
                )
                .foregroundStyle(.white)
                .padding(.bottom, 60)
            }
            .padding(.top, 100)
            .padding()
            //dismissButton
        }
        .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder
    func getTextTotal() -> Text {
        Text("Tu entreno actual consiste en un total de ") +
        Text("\(training!.numberOfReps*training!.numberOfSets)").fontWeight(.bold) +
        Text(" repeticiones a lo largo de ") +
        Text("\(Int(training!.numberOfMinutesPerSet*training!.numberOfSets)/60)").fontWeight(.bold) +
        Text(" horas")
    }

    var dismissButton: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.smooth) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(uiColor: .blue))
                    .background(Color(uiColor: .white))
                    .clipShape(Circle())
                    .padding(.top, 60)
                    .padding(.trailing, 40)
            }
        }
    }
}
