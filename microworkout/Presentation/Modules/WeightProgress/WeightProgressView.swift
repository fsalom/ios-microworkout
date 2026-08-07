import Charts
import SwiftUI

/// Progresión de peso: la gráfica, el resumen de la tendencia y el campo para
/// anotar. Lo que se anota aquí va a Apple Salud, que es la fuente.
struct WeightProgressView: View {
    @StateObject var viewModel: WeightProgressViewModel
    @FocusState private var isInputFocused: Bool

    private let windows: [(label: String, days: Int)] = [
        ("1 mes", 30), ("3 meses", 90), ("1 año", 365),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                chart
                entryCard
                history
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Peso")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
        .onTapGesture { isInputFocused = false }
    }

    // MARK: - Cabecera

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            if let latest = viewModel.uiState.latest?.weightKg {
                Text(WeightProgressViewModel.format(latest))
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                Text("kg").foregroundStyle(.secondary)
            } else {
                Text("Sin datos todavía")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            trendBadge
        }

        if let error = viewModel.uiState.error {
            Text(error)
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var trendBadge: some View {
        if let trend = viewModel.uiState.trend {
            VStack(alignment: .trailing, spacing: 2) {
                Label(
                    String(format: "%+.1f kg", trend.deltaKg),
                    systemImage: trend.deltaKg <= 0 ? "arrow.down.right" : "arrow.up.right"
                )
                .font(.subheadline.weight(.medium))
                // Sin color de "bueno/malo": bajar no es un logro para quien está
                // ganando masa. El dato es el dato.
                .foregroundStyle(.secondary)

                if let perWeek = trend.kgPerWeek {
                    Text(String(format: "%+.2f kg/semana", perWeek))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("en \(trend.days) días")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Gráfica

    @ViewBuilder
    private var chart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Rango", selection: Binding(
                get: { viewModel.uiState.windowDays },
                set: { viewModel.changeWindow(days: $0) }
            )) {
                ForEach(windows, id: \.days) { window in
                    Text(window.label).tag(window.days)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.uiState.hasData {
                Chart(viewModel.uiState.measurements.filter { $0.weightKg != nil }) { measurement in
                    LineMark(
                        x: .value("Fecha", measurement.date),
                        y: .value("Peso", measurement.weightKg ?? 0)
                    )
                    .interpolationMethod(.monotone)
                    PointMark(
                        x: .value("Fecha", measurement.date),
                        y: .value("Peso", measurement.weightKg ?? 0)
                    )
                    .symbolSize(20)
                }
                .chartYScale(domain: viewModel.uiState.weightRange ?? 0...1)
                .frame(height: 200)
            } else if viewModel.uiState.isLoading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Text("Anota tu peso o dale permiso a Salud y aquí verás la progresión.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Anotar

    @ViewBuilder
    private var entryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Anotar peso").font(.headline)

            HStack(spacing: 12) {
                TextField("0,0", text: Binding(
                    get: { viewModel.uiState.weightInput },
                    set: { viewModel.uiState.weightInput = $0 }
                ))
                .keyboardType(.decimalPad)
                .focused($isInputFocused)
                .font(.title3.weight(.medium))
                .frame(maxWidth: 100)
                .padding(8)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("kg").foregroundStyle(.secondary)

                DatePicker(
                    "",
                    selection: Binding(
                        get: { viewModel.uiState.entryDate },
                        set: { viewModel.uiState.entryDate = $0 }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .labelsHidden()

                Spacer()

                Button {
                    isInputFocused = false
                    viewModel.save()
                } label: {
                    if viewModel.uiState.isSaving {
                        ProgressView()
                    } else {
                        Text("Guardar").bold()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.uiState.isSaving)
            }

            Text("Se guarda también en Apple Salud, para que no haya dos pesos distintos.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Historial

    @ViewBuilder
    private var history: some View {
        let entries = viewModel.uiState.measurements
            .filter { $0.weightKg != nil }
            .sorted { $0.date > $1.date }

        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("Historial")
                    .font(.headline)
                    .padding(.bottom, 8)

                ForEach(entries) { measurement in
                    HStack {
                        Text(measurement.date, format: .dateTime.day().month(.abbreviated).year())
                            .font(.subheadline)
                        if measurement.source == .health {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.pink)
                                .accessibilityLabel("Viene de Salud")
                        }
                        Spacer()
                        Text("\(WeightProgressViewModel.format(measurement.weightKg ?? 0)) kg")
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.delete(measurement)
                        } label: {
                            Label("Borrar", systemImage: "trash")
                        }
                    }
                    Divider()
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("Borrar aquí quita la medida de la app y de tu cuenta, pero no de Apple Salud: esos datos son tuyos y pueden venir de tu báscula.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
