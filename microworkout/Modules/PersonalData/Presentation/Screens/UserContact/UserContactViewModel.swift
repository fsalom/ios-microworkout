import Foundation

class UserContactViewModel: ObservableObject {
    struct UIState {
        var isValidPhone = false
        var error: UserError?
        var fullnameErrorMessage = ""
        var canContinue = false
        var needToShowToast = false
        var phoneErrorMessage = "common_wrongPhoneFormat"
    }

    private let validationUseCase: ValidationUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol

    @Published var uiState = UIState()
    @Published var name: String = ""
    @Published var phone: String = "" {
        didSet {
            checkIsValidPhone(phone: phone)
        }
    }

    init(validationUseCase: ValidationUseCaseProtocol, userUseCase: UserUseCaseProtocol) {
        self.validationUseCase = validationUseCase
        self.userUseCase = userUseCase
    }

    @MainActor
    func getUser() {
        Task {
            do {
                let user = try await userUseCase.getUser()
                name = user.fullname
                phone = user.phone
            } catch let error as UserError {
                uiState.error = error
            }
        }
    }

    @MainActor
    func checkIfReadyToContinue() {
        if uiState.isValidPhone, !name.isEmpty {
            updateUser()
        }
    }

    @MainActor
    private func updateUser() {
        Task {
            do {
                _ = try await userUseCase.updateUser(name: name, phone: phone)
                uiState.needToShowToast = true
            } catch let error as UserError {
                uiState.error = error
            }
        }
    }

    private func checkIsValidPhone(phone: String) {
        uiState.isValidPhone = validationUseCase.validate(phone: phone)
    }
}
