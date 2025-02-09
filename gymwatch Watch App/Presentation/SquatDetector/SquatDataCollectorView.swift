import SwiftUI

struct SquatDataCollectorView: View {
    @StateObject var squatDataCollector = SquatDataCollector()

    var body: some View {
        ScrollView {
            if let path = squatDataCollector.path {
                Text("Guardado en: \(path)")
                    .foregroundStyle(.white)
                    .font(.subheadline)
            }
            VStack {
                if let accelData = squatDataCollector.accelData, let gyroData = squatDataCollector.gyroData {
                    VStack {
                        HStack {
                            Text("↔️")
                            Text("\(accelData.x)")
                            Text("\(accelData.y)")
                            Text("\(accelData.z)")
                        }
                        HStack {
                            Text("🔄")
                            Text("\(gyroData.x)")
                            Text("\(gyroData.y)")
                            Text("\(gyroData.z)")
                        }
                    }
                }
                if squatDataCollector.isRecording {
                    Text(squatDataCollector.currentLabel)
                    Text("✅ Grabando...")
                        .foregroundStyle(.white)
                        .font(.headline)
                        .padding()
                    if let error = squatDataCollector.error {
                        Text("Error: \(error)")
                            .foregroundStyle(.white)
                            .font(.subheadline)

                    }
                }
                Button(squatDataCollector.isRecording ? "Parar de registrar": "Empezar a registrar") {
                    squatDataCollector.isRecording ?
                    squatDataCollector.stopRecording() :
                    squatDataCollector.startRecording()
                }
            }
        }
    }
}
