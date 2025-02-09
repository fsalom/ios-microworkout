import CoreMotion
import Foundation

class SquatDataCollector: ObservableObject {
    private let motionManager = CMMotionManager()
    private var dataLog: String = "accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,label\n"

    @Published var accelData: CMAcceleration?
    @Published var gyroData: CMRotationRate?
    @Published var currentLabel: String = "reposo"
    @Published var path: String?
    @Published var error: String? {
        didSet {
            isRecording = false
        }
    }
    @Published var isRecording: Bool {
        didSet {
            if oldValue == true {
                path = nil
                error = nil
            }
        }
    }

    private var isSquatting = false // Estado para evitar cambios erráticos

    init(){
        self.isRecording = false
    }

    func detectSquat(accelerationZ: Double) {
        let squatThreshold = -1.2  // Umbral para detectar bajada
        let standThreshold = -0.8  // Umbral para detectar subida

        if accelerationZ < squatThreshold, !isSquatting {
            isSquatting = true
            DispatchQueue.main.async {
                self.currentLabel = "sentadilla"
            }
        } else if accelerationZ > standThreshold, isSquatting {
            isSquatting = false
            DispatchQueue.main.async {
                self.currentLabel = "reposo"
            }
        }
    }

    func startRecording() {
        isRecording = true
        guard motionManager.isDeviceMotionAvailable else {
            error = "Device Motion not available"
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0

        motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
            guard let motion = motion else { return }
            self.accelData = motion.userAcceleration
            self.gyroData = motion.rotationRate
            self.detectSquat(accelerationZ: motion.userAcceleration.z)
            self.recordData(accelData: motion.userAcceleration, gyroData: motion.rotationRate)
        }
    }

    func recordData(accelData: CMAcceleration, gyroData: CMRotationRate) {
        let entry = "\(accelData.x),\(accelData.y),\(accelData.z)," +
                    "\(gyroData.x),\(gyroData.y),\(gyroData.z)," +
                    "\(currentLabel)\n"

        dataLog.append(entry)
    }

    func stopRecording() {
        isRecording = false
        motionManager.stopDeviceMotionUpdates()

        // Guardar el archivo CSV en el Apple Watch
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("squat_data.csv")

        try? dataLog.write(to: fileURL, atomically: true, encoding: .utf8)
        print("Datos guardados en: \(fileURL)")
        path = fileURL.absoluteString
    }
}
