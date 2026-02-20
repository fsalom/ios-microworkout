import SwiftUI

struct LinkSuggestionSheet: View {
    let workout: HealthWorkout
    let trainings: [Training]
    let onLink: (Training) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "applewatch")
                        .font(.title2)
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Se detecto entrenamiento")
                            .font(.headline)
                        Text("\(workout.activityTypeName) (\(workout.durationFormatted))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                Text("Vincular a:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal)

                if trainings.isEmpty {
                    Text("No hay entrenamientos disponibles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(trainings) { training in
                                HStack {
                                    Image(training.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Text(training.name)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Button("Vincular") {
                                        onLink(training)
                                    }
                                    .font(.subheadline)
                                }
                                .padding(10)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Apple Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        onDismiss()
                    }
                }
            }
        }
    }
}
