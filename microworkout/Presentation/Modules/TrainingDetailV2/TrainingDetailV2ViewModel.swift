import Foundation
import SwiftUI

final class TrainingDetailV2ViewModel: ObservableObject {

    var namespace: Namespace.ID
    private var router: TrainingDetailV2Router
    @Published var training: Training

    init(router: TrainingDetailV2Router, training: Training, namespace: Namespace.ID) {
        self.router = router
        self.training = training
        self.namespace = namespace
    }
}
