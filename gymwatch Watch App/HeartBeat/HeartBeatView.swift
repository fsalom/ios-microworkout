//
//  HeartBeatView.swift
//  gymwatch Watch App
//
//  Created by Fernando Salom Carratala on 7/8/23.
//

import SwiftUI

struct HeartBeatView: View {
    @ObservedObject var viewModel: HeartBeatViewModel

    var body: some View {
        VStack{
            HStack{
                Text("❤️")
                    .font(.system(size: 50))
                Spacer()

            }

            HStack{
                Text("\(viewModel.value)")
                    .fontWeight(.regular)
                    .font(.system(size: 70))

                Text("BPM")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.red)
                    .padding(.bottom, 28.0)

                Spacer()

            }

        }
        .padding()
        .onAppear(perform: viewModel.start)
    }
}

struct HeartBeatView_Previews: PreviewProvider {
    static var previews: some View {
        HeartBeatView(viewModel: HeartBeatViewModel())
    }
}
