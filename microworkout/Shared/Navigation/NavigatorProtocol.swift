//
//  NavigatorProtocol.swift
//  CucharaDePlata
//
//  Created by Adrián Prieto Villena on 20/1/25.
//

import SwiftUI

protocol NavigatorProtocol: NavigatorManagerProtocol, ModalPresenterProtocol {
    // MARK: - Properties
    var path: [Page] { get set }
    var root: Page? { get }
    // MARK: - Methods
    func initialize(root view: any View)
}

protocol NavigatorManagerProtocol {
    // MARK: - Properties
    var sheet: Page? { get set }

    // MARK: - Methods
    func push(to view: any View)
    func pushAndRemovePrevious(to view: any View)
    func dismiss()
    func dismissSheet()
    func dismissAll()
    func replaceRoot(to view: any View)
    func present(view: any View)
    func presentCustomConfirmationDialog(from config: ConfirmationDialogConfig)
    func presentImagePickerOptions(cameraAction: @escaping () -> Void, galleryAction: @escaping () -> Void)
    func changeTab(index: Int)
}


protocol ModalPresenterProtocol {
    // MARK: - Properties
    var toastView: ToastView? { get set }
    var alertConfig: AlertConfig? { get }
    var confirmationDialogConfig: ConfirmationDialogConfig? { get }
    var isPresentingAlert: Bool { get set }
    var isPresentingConfirmationDialog: Bool { get set }

    // MARK: - Methods
    func showAlert(from config: AlertConfig)
    func showToast(from toast: ToastView)
    func showErrorAlert(title: String, message: String, action: @escaping () -> Void)
    func showAlertPermission(title: String, message: String, action: @escaping () -> Void)
}
