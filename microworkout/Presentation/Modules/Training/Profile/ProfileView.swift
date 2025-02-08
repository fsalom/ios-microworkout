//
//  ProfileView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 10/7/23.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    Circle()
                        .fill(.gray)
                        .frame(width: 160, height: 160)
                    Image("splash")
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                }
                Spacer()
            }.navigationTitle("Perfil")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
