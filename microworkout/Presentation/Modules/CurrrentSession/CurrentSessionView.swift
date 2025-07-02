//
//  StartSessionView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 26/6/25.
//

import SwiftUI
import MapKit

struct CurrentSessionView: View {
    @State private var duration = 30
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.4362, longitude: -0.4648),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 32, height: 32)
                Spacer()
            }
            .padding(.horizontal)

            Spacer()
            CronoView()
                .font(.system(size: 64, weight: .bold))
                .padding(.bottom, 4)
            Spacer()
            HStack(spacing: 40) {
                Button(action: {
                    // Acción comenzar
                }) {
                    Text("COMENZAR")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(width: 120, height: 120)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
    }
}

#Preview {
    CurrentSessionView()
}
