import SwiftUI

struct HealthWorkoutDetailView: View {
    @ObservedObject var viewModel: HealthWorkoutDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                dateSection
                statsGrid
                linkSection
            }
            .padding()
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch")
                .font(.largeTitle)
                .foregroundColor(.green)
            VStack(alignment: .leading) {
                Text(viewModel.uiState.workout.activityTypeName)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Apple Watch")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let parts = viewModel.uiState.workout.dateParts {
                Text("\(parts.day) de \(parts.monthName) de \(parts.year)")
                    .font(.headline)
            }
            Text(viewModel.uiState.workout.timeRangeFormatted)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(title: "Duracion", value: viewModel.uiState.workout.durationFormatted, icon: "clock", color: .blue)

            if let cal = viewModel.uiState.workout.caloriesFormatted {
                StatCard(title: "Calorias", value: cal, icon: "flame.fill", color: .orange)
            }

            if let dist = viewModel.uiState.workout.distanceFormatted {
                StatCard(title: "Distancia", value: dist, icon: "figure.run", color: .blue)
            }

            if let hr = viewModel.uiState.workout.heartRateFormatted {
                StatCard(title: "FC media", value: hr, icon: "heart.fill", color: .red)
            }
        }
    }

    private var linkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vincular entrenamiento")
                .font(.headline)

            if let linked = viewModel.uiState.linkedTraining {
                HStack {
                    Image(linked.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading) {
                        Text(linked.name)
                            .fontWeight(.bold)
                        Text("Vinculado")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Button("Desvincular") {
                        viewModel.unlinkTraining()
                    }
                    .foregroundColor(.red)
                    .font(.subheadline)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                if viewModel.uiState.availableTrainings.isEmpty {
                    Text("No hay entrenamientos disponibles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.uiState.availableTrainings) { training in
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
                                viewModel.linkTo(training: training)
                            }
                            .font(.subheadline)
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
