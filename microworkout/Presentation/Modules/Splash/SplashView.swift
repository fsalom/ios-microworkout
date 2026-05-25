//
//  SplashView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/6/23.
//

import SwiftUI

struct SplashView: View {

    @State var isActive: Bool = false

    var body: some View {
        if self.isActive {
            
        } else {
            ZStack {
                Color.white

                Image("splash")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }.onAppear {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
