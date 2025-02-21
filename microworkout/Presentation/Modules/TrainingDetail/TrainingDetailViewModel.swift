import Foundation
import SwiftUI

final class TrainingDetailViewModel: ObservableObject {

    var namespace: Namespace.ID
    private var router: TrainingDetailRouter
    @Published var training: Training

    init(router: TrainingDetailRouter, training: Training, namespace: Namespace.ID) {
        self.router = router
        self.training = training
        self.namespace = namespace
    }
}
