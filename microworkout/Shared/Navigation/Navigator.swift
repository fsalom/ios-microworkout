//
//  Navigator.swift
//  CucharaDePlata
//
//  Created by Adrián Prieto Villena on 20/1/25.
//

import SwiftUI

@Observable
class Navigator: NavigatorProtocol {
    // MARK: - Properties
    var path = [Page]()
    private(set) var root: Page?
    var sheet: Page?
    var toastView: ToastView?
    var alertConfig: AlertConfig?
    var tabIndex: Binding<Int>!
    var confirmationDialogConfig: ConfirmationDialogConfig?
    var isPresentingAlert = false {
        didSet {
            if isPresentingAlert == false {
                alertConfig = nil
            }
        }
    }
    var isPresentingConfirmationDialog = false {
        didSet {
            if isPresentingConfirmationDialog == false {
                confirmationDialogConfig = nil
            }
        }
    }

    // MARK: - Init
    static var shared = Navigator()
    private init() {}

    // MARK: - Methods
    func initialize(root view: any View) {
        root = Page(from: view)
    }
}

// MARK: - Functions NavigatorManagerProtocol 
extension Navigator {
    func push(to view: any View) {
        path.append(Page(from: view))
    }

    func pushAndRemovePrevious(to view: any View) {
        path.append(Page(from: view))
        path.remove(at: path.count - 2)
    }

    func dismiss() {
        path.removeLast()
    }

    func dismissSheet() {
        sheet = nil
    }

    func dismissAll() {
        path.removeAll()
    }

    func replaceRoot(to view: any View) {
        root = Page(from: view)
        path.removeAll()
    }

    func present(view: any View) {
        sheet = Page(from: view)
    }
    
    func presentCustomConfirmationDialog(from config: ConfirmationDialogConfig) {
        confirmationDialogConfig = config
        isPresentingConfirmationDialog = true
    }

    func changeTab(index: Int) {
        var indexIn = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.tabIndex = Binding(get: { indexIn }, set: { indexIn = $0 })
        }
    }

    func presentImagePickerOptions(cameraAction: @escaping () -> Void, galleryAction: @escaping () -> Void) {
        confirmationDialogConfig = ConfirmationDialogConfig(actions: {
            VStack {
                Button("addReview_takePhoto") {
                    cameraAction()
                }
                Button("addReview_selectGallery") {
                    galleryAction()
                }
            }
        })
        isPresentingConfirmationDialog = true
    }
}

// MARK: - Functions ModalPresentProtocol
extension Navigator {
    func showAlert(from config: AlertConfig) {
        alertConfig = config
        isPresentingAlert = true
    }

    func showToast(from toast: ToastView) {
        self.toastView = toast
    }

    func showErrorAlert(title: String, message: String, action: @escaping () -> Void) {
        alertConfig =  AlertConfig(
            title: LocalizedStringKey(stringLiteral: title),
            message: LocalizedStringKey(stringLiteral: message),
            actions: {
                Button("common_accept", role: .cancel) { action() }
            })
        isPresentingAlert = true
    }

    func showAlertPermission(title: String, message: String, action: @escaping () -> Void) {
        alertConfig =  AlertConfig(
            title: LocalizedStringKey(stringLiteral: title),
            message: LocalizedStringKey(stringLiteral: message),
            actions: {
                VStack {
                    Button("common_denied", role: .destructive) {}
                    Button("common_goToSettings", role: .cancel) {
                        action()
                    }
                }
            })
        isPresentingAlert = true
    }
}
