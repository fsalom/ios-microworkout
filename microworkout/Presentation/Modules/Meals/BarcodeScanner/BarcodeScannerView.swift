//
//  BarcodeScannerView.swift
//  microworkout
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @ObservedObject var viewModel: BarcodeScannerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Camera View
            BarcodeCameraView { barcode in
                viewModel.onBarcodeScanned(barcode)
            }
            .ignoresSafeArea()

            // Overlay based on state
            VStack {
                Spacer()

                switch viewModel.state {
                case .scanning:
                    ScanningOverlay()

                case .loading:
                    LoadingOverlay(barcode: viewModel.scannedBarcode)

                case .found(let item):
                    ProductFoundOverlay(
                        item: item,
                        quantity: $viewModel.quantity,
                        onAdjustQuantity: { viewModel.adjustQuantity(by: $0) },
                        onAdd: { viewModel.addToMeal() },
                        onScanAgain: { viewModel.scanAgain() }
                    )

                case .notFound:
                    ProductNotFoundOverlay(
                        barcode: viewModel.scannedBarcode,
                        onScanAgain: { viewModel.scanAgain() }
                    )

                case .error(let message):
                    ErrorOverlay(
                        message: message,
                        onScanAgain: { viewModel.scanAgain() }
                    )
                }
            }
        }
        .navigationTitle("Escanear código")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancelar") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Scanning Overlay

struct ScanningOverlay: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 250, height: 150)

            Text("Apunta al código de barras")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
        }
        .padding(.bottom, 100)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let barcode: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Buscando producto...")
                .font(.headline)
                .foregroundColor(.white)

            Text(barcode)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(24)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .padding(.bottom, 100)
    }
}

// MARK: - Product Found Overlay

struct ProductFoundOverlay: View {
    let item: FoodItem
    @Binding var quantity: Double
    let onAdjustQuantity: (Double) -> Void
    let onAdd: () -> Void
    let onScanAgain: () -> Void

    private var adjustedNutrition: NutritionInfo {
        item.nutritionPer100g.scaled(by: quantity / 100)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Product info
            HStack(spacing: 12) {
                if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            Image(systemName: "photo")
                                .frame(width: 60, height: 60)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(2)

                    Text("Por 100g: \(Int(item.nutritionPer100g.calories)) kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Quantity selector
            HStack {
                Text("Cantidad:")
                    .font(.subheadline)

                Spacer()

                HStack(spacing: 12) {
                    Button(action: { onAdjustQuantity(-10) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }

                    Text("\(Int(quantity))g")
                        .font(.headline)
                        .frame(minWidth: 60)

                    Button(action: { onAdjustQuantity(10) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }

            // Nutrition for selected quantity
            HStack(spacing: 16) {
                NutrientBadge(value: adjustedNutrition.calories, label: "kcal", color: .orange)
                NutrientBadge(value: adjustedNutrition.proteins, label: "Prot", color: .red)
                NutrientBadge(value: adjustedNutrition.carbohydrates, label: "Carb", color: .blue)
                NutrientBadge(value: adjustedNutrition.fats, label: "Gras", color: .yellow)
            }

            // Buttons
            HStack(spacing: 12) {
                Button(action: onScanAgain) {
                    Text("Escanear otro")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }

                Button(action: onAdd) {
                    Text("Añadir")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .padding()
    }
}

struct NutrientBadge: View {
    let value: Double
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.0f", value))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Product Not Found Overlay

struct ProductNotFoundOverlay: View {
    let barcode: String
    let onScanAgain: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Producto no encontrado")
                .font(.headline)

            Text("El código \(barcode) no está en la base de datos")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onScanAgain) {
                Text("Escanear otro")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .padding()
    }
}

// MARK: - Error Overlay

struct ErrorOverlay: View {
    let message: String
    let onScanAgain: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)

            Button(action: onScanAgain) {
                Text("Intentar de nuevo")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .padding()
    }
}

// MARK: - Camera View (UIViewRepresentable)

struct BarcodeCameraView: UIViewRepresentable {
    let onBarcodeScanned: (String) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let captureSession = AVCaptureSession()
        context.coordinator.captureSession = captureSession

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return view
        }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return view
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39, .code93]
        } else {
            return view
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        let onBarcodeScanned: (String) -> Void
        private var lastScannedCode: String?

        init(onBarcodeScanned: @escaping (String) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let metadataObject = metadataObjects.first,
                  let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else {
                return
            }

            // Avoid duplicate scans
            guard stringValue != lastScannedCode else { return }
            lastScannedCode = stringValue

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onBarcodeScanned(stringValue)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.captureSession?.stopRunning()
    }
}

#Preview {
    NavigationStack {
        BarcodeScannerBuilder().build(onScanComplete: { _ in })
    }
}
