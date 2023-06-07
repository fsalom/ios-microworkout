//
//  SplashView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/6/23.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        Image("splash")
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
