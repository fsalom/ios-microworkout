import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    enum CaptureMode {
        case photo
        case video
        /// Permite tanto foto como vídeo en la misma cámara (selector arriba en iOS).
        case both
    }

    let mode: CaptureMode
    let onPicked: (Result) -> Void
    let onCancel: () -> Void

    enum Result {
        case photo(UIImage)
        case video(URL)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.modalPresentationStyle = .fullScreen
        switch mode {
        case .photo:
            picker.mediaTypes = ["public.image"]
            picker.cameraCaptureMode = .photo
        case .video:
            picker.mediaTypes = ["public.movie"]
            picker.cameraCaptureMode = .video
            picker.videoQuality = .typeHigh
        case .both:
            picker.mediaTypes = ["public.image", "public.movie"]
            picker.videoQuality = .typeHigh
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let url = info[.mediaURL] as? URL {
                parent.onPicked(.video(url))
            } else if let image = info[.originalImage] as? UIImage {
                parent.onPicked(.photo(image))
            } else {
                parent.onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}
