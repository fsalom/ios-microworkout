import CoreMotion
import WatchKit

class MotionManager {
    private let motionManager = CMMotionManager()
    private var zValues: [Double] = []
    private let filterSize = 5 // Tamaño del filtro

    func startAccelerometerUpdates() {
        guard motionManager.isAccelerometerAvailable else {
            print("Acelerómetro no disponible")
            return
        }

        motionManager.accelerometerUpdateInterval = 1.0 / 50.0 // 50 Hz
        motionManager.startAccelerometerUpdates(to: .main) { data, error in
            guard let data = data, error == nil else { return }

            let rawZ = data.acceleration.z
            self.zValues.append(rawZ)

            if self.zValues.count > self.filterSize {
                self.zValues.removeFirst()
            }

            let smoothedZ = self.zValues.reduce(0, +) / Double(self.zValues.count)

            self.detectSquat(with: smoothedZ)
        }
    }

    func detectSquat(with zAcceleration: Double) {
        if zAcceleration < -1.0 {
            print("Bajando en sentadilla")
        } else if zAcceleration > -0.2 {
            print("Subiendo en sentadilla")
        }
    }

    func stopAccelerometerUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
}
