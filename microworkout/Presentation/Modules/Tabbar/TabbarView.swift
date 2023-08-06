//
//  TabbarView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 10/7/23.
//

import SwiftUI

struct TabbarView: View {
    var body: some View {
        TabView {
            HomeBuilder().build()
                .tabItem {
                    Label("Entrenamiento", systemImage: "dumbbell.fill")
                }

            HealthKitBuilder().build()
                .tabItem {
                    Label("Salud", systemImage: "health")
                }

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
        }
    }
}

struct TabbarView_Previews: PreviewProvider {
    static var previews: some View {
        TabbarView()
    }
}
