import SwiftUI

struct DetailWorkoutView: View {
    @StateObject var viewModel: DetailWorkoutViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !viewModel.isActive {
                    Text(viewModel.training.name)
                        .font(.headline)
                        .padding(.top)

                    Button {
                        viewModel.startWorkout()
                    } label: {
                        Label("Empezar", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.horizontal)
                } else {
                    // Timer
                    Text(viewModel.formattedTime)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(.top, 4)

                    // Heart Rate
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("\(Int(viewModel.heartRate)) bpm")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    // Calories
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(Int(viewModel.activeCalories)) kcal")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    // Distance
                    if viewModel.training.type == .cardio {
                        HStack {
                            Image(systemName: "figure.run")
                                .foregroundColor(.cyan)
                            Text(viewModel.formattedDistance)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }

                    // Controls
                    HStack(spacing: 16) {
                        if viewModel.isPaused {
                            Button {
                                viewModel.resumeWorkout()
                            } label: {
                                Image(systemName: "play.fill")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        } else {
                            Button {
                                viewModel.pauseWorkout()
                            } label: {
                                Image(systemName: "pause.fill")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.yellow)
                        }

                        Button {
                            viewModel.stopWorkout()
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}
