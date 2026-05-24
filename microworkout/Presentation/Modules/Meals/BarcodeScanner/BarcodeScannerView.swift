//
//  BarcodeScannerView.swift
//  microworkout
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @ObservedObject var viewModel: BarcodeScannerViewModel
    @Environment(\.dismiss) private var dismiss

    private var isCameraActive: Bool {
        if viewModel.isCreatingCustom { return false }
        switch viewModel.state {
        case .scanning: return true
        default: return false
        }
    }

    var body: some View {
        Group {
            if viewModel.isCreatingCustom {
                CreateCustomFoodSheet(
                    barcode: viewModel.scannedBarcode,
                    onSave: { name, kcal, p, c, f in
                        viewModel.saveCustomFood(
                            name: name,
                            kcalPer100g: kcal,
                            proteinsPer100g: p,
                            carbsPer100g: c,
                            fatsPer100g: f
                        )
                    },
                    onCancel: { viewModel.closeCreateCustom() }
                )
            } else {
                scannerContent
            }
        }
        .navigationTitle("Escanear código")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.isCreatingCustom {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onChange(of: viewModel.shouldDismiss) { _, value in
            if value { dismiss() }
        }
    }

    private var scannerContent: some View {
        ZStack {
            // Camera View — desmontamos completamente cuando ya no estamos
            // buscando para evitar que un nuevo escaneo dispare cambios de estado.
            if isCameraActive {
                BarcodeCameraView(isActive: true) { barcode in
                    viewModel.onBarcodeScanned(barcode)
                }
                .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }

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
                        onScanAgain: { viewModel.scanAgain() },
                        onCreate: { viewModel.openCreateCustom() }
                    )

                case .error(let message):
                    ErrorOverlay(
                        message: message,
                        onScanAgain: { viewModel.scanAgain() }
                    )
                }
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
    let onCreate: () -> Void

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

            Button(action: onCreate) {
                Label("Crear alimento", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Button(action: onScanAgain) {
                Text("Escanear otro")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .padding()
    }
}

// MARK: - Create custom food sheet

struct CreateCustomFoodSheet: View {
    let barcode: String
    let onSave: (String, Double, Double, Double, Double) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var kcal: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fats: String = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && parsed(kcal) != nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Identificación") {
                    HStack {
                        Image(systemName: "barcode")
                            .foregroundColor(.secondary)
                        Text(barcode)
                            .font(.system(.subheadline, design: .monospaced))
                    }
                    TextField("Nombre del alimento", text: $name)
                }

                Section("Nutrición por 100 g") {
                    NumericRow(label: "Calorías (kcal)", value: $kcal)
                    NumericRow(label: "Proteína (g)", value: $protein)
                    NumericRow(label: "Carbohidratos (g)", value: $carbs)
                    NumericRow(label: "Grasas (g)", value: $fats)
                }

                Section {
                    Text("Se guardará localmente. La próxima vez que escanees este código, lo encontraremos directamente.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Crear alimento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        onSave(
                            name.trimmingCharacters(in: .whitespaces),
                            parsed(kcal) ?? 0,
                            parsed(protein) ?? 0,
                            parsed(carbs) ?? 0,
                            parsed(fats) ?? 0
                        )
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func parsed(_ value: String) -> Double? {
        Double(value.replacingOccurrences(of: ",", with: "."))
    }
}

private struct NumericRow: View {
    let label: String
    @Binding var value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: $value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
        }
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

/// UIView whose backing layer IS an AVCaptureVideoPreviewLayer.
/// This way the layer auto-resizes with the view via UIKit's normal layout.
final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        // Force-cast is safe because layerClass is overridden above.
        return layer as! AVCaptureVideoPreviewLayer
    }
}

struct BarcodeCameraView: UIViewRepresentable {
    let isActive: Bool
    let onBarcodeScanned: (String) -> Void

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.backgroundColor = .black
        view.previewLayer.videoGravity = .resizeAspectFill

        let captureSession = AVCaptureSession()
        view.previewLayer.session = captureSession
        context.coordinator.captureSession = captureSession

        let coordinator = context.coordinator
        coordinator.sessionQueue.async {
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                print("[BarcodeScanner] No video device available")
                return
            }

            let videoInput: AVCaptureDeviceInput
            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                print("[BarcodeScanner] Failed to create input: \(error)")
                return
            }

            captureSession.beginConfiguration()

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("[BarcodeScanner] Cannot add input")
                captureSession.commitConfiguration()
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
            } else {
                print("[BarcodeScanner] Cannot add metadata output")
                captureSession.commitConfiguration()
                return
            }

            captureSession.commitConfiguration()

            // Set delegate AFTER commitConfiguration so the output is fully wired.
            // Use main queue for metadata callbacks — the work is light and we marshal
            // to UI immediately anyway.
            metadataOutput.setMetadataObjectsDelegate(coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39, .code93, .qr, .dataMatrix]

            captureSession.startRunning()

            // Set the preview connection orientation on the main thread.
            DispatchQueue.main.async {
                if let connection = view.previewLayer.connection {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90 // portrait
                    } else if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                }
            }
        }

        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        let coordinator = context.coordinator
        let active = isActive
        coordinator.sessionQueue.async {
            guard let session = coordinator.captureSession else { return }
            if active {
                if !session.isRunning { session.startRunning() }
            } else {
                if session.isRunning { session.stopRunning() }
                // Reset last seen so the user can rescan the same code after pausing.
                DispatchQueue.main.async { coordinator.resetLastScanned() }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var captureSession: AVCaptureSession?
        let onBarcodeScanned: (String) -> Void
        let sessionQueue = DispatchQueue(label: "BarcodeScanner.sessionQueue", qos: .userInitiated)
        private var lastScannedCode: String?

        init(onBarcodeScanned: @escaping (String) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
        }

        func resetLastScanned() {
            lastScannedCode = nil
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

            guard stringValue != lastScannedCode else { return }
            lastScannedCode = stringValue

            print("[BarcodeScanner] Detected: \(stringValue)")
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onBarcodeScanned(stringValue)
        }
    }

    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: Coordinator) {
        let session = coordinator.captureSession
        coordinator.sessionQueue.async {
            session?.stopRunning()
        }
    }
}

#Preview {
    NavigationStack {
        BarcodeScannerBuilder(component: DefaultAppComponent.preview).build(onScanComplete: { _ in })
    }
}
