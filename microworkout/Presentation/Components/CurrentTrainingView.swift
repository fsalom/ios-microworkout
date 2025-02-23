//
//  CurrentTrainingView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 23/2/25.
//

import SwiftUI

struct CurrentTrainingView: View {
    @Binding var isPresented: Bool
    @Binding var training: Training
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
                HStack(spacing: 10) {
                    VStack {
                        Text("\(training.numberOfSets)")
                            .font(.title)
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                        Text("Series")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Text("\(training.numberOfReps)")
                            .font(.title)
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                        Text("Repeticiones")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Text("\(training.numberOfMinutesPerSet) min")
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
                CountdownView(minutes: 60)
            }
            .padding(.top, 100)
            .padding()
            dismissButton
        }
        .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder
    func getTextTotal() -> Text {
        Text("Tu entreno actual consiste en un total de ") +
        Text("\(training.numberOfReps*training.numberOfSets)").fontWeight(.bold) +
        Text(" repeticiones a lo largo de ") +
        Text("\(Int(training.numberOfMinutesPerSet*training.numberOfSets)/60)").fontWeight(.bold) +
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
