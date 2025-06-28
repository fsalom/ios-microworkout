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
                Text("12:53")
                    .font(.subheadline)
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Image(systemName: "battery.75")
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 4) {
                Text("Sesión")
                    .font(.largeTitle)
                    .bold()

                HStack {
                    Text("Inicio rápido")
                        .bold()
                    Text("Guías de running")
                        .foregroundColor(.gray)
                }
                .font(.subheadline)
            }
            .padding()

            Spacer()

            Text(String(format: "%02d:%02d", duration / 60, duration % 60))
                .font(.system(size: 64, weight: .bold))
                .padding(.bottom, 4)
            Text("Horas : Minutos")
                .foregroundColor(.gray)

            Map(coordinateRegion: $region)
                .frame(height: 220)
                .cornerRadius(20)
                .padding()

            HStack(spacing: 40) {
                CircleButton(icon: "gearshape")
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
                CircleButton(icon: "speaker.slash")
            }

            Text("Tiempo")
                .foregroundColor(.gray)
                .padding(.top, 8)

            Spacer()
        }
    }
}

struct CircleButton: View {
    let icon: String

    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.title2)
                .padding()
                .background(Color.gray.opacity(0.2))
                .clipShape(Circle())
        }
    }
}

#Preview {
    CurrentSessionView()
}
