//
//  VerifyPasswordView.swift
//  Gula
//
//  Created by Adrian Prieto Villena on 4/11/24.
//

import SwiftUI

struct VerifyPasswordView: View {
    @StateObject var viewModel: VerifyPasswordViewModel
    @Binding var isShowingVerifyPasswordSheet: Bool
    @Binding var navigateToNewPassword: Bool
    @State var buttonState: ButtonState = .normal
    @State private var errorAlertTitle: LocalizedStringKey = ""
    @State private var errorAlertMessage: LocalizedStringKey = ""
    @State private var passwordErrorMessage = "auth_wrongPassword"
    @State private var isShowingErrorAlert = false
    @FocusState var isFocusedPasswordTextField: Bool

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header
                CustomTextField(
                    text: $viewModel.password,
                    isFieldValid: $viewModel.uiState.isValidPassword,
                    hasUserStartedTyping: viewModel.uiState.hasStartTyping,
                    areValidationsActive: true,
                    placeholder: "auth_actualPassword",
                    errorMessage: LocalizedStringKey(passwordErrorMessage),
                    type: .password,
                    maxLength: 15,
                    isFocused: _isFocusedPasswordTextField
                )
                CustomButton(
                    buttonState: $buttonState,
                    type: .primary,
                    buttonText: "common_continue",
                    action: {
                        isFocusedPasswordTextField = false
                        viewModel.verifyPassword()
                    }
                )
            }
            .padding(.horizontal, 16)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .presentationDetents([.height(204)])
            .onChange(of: viewModel.uiState.error, { _, error in
                guard let error else { return }
                handle(this: error)
            })
            .alert(isPresented: $isShowingErrorAlert) {
                Alert(
                    title: Text(errorAlertTitle),
                    message: Text(errorAlertMessage),
                    dismissButton: .default(Text("common_accept"), action: {
                        viewModel.uiState.error = nil
                    })
                )
            }
            .onChange(of: viewModel.uiState.isPasswordVerified) { _, isVerified in
                if isVerified {
                    isShowingVerifyPasswordSheet = false
                    navigateToNewPassword = true
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("auth_updatePassword")
                .font(.system(size: 14, weight: .medium))
                .padding(.top, 16)
            Text("auth_updatePasswordMessage")
                .font(.system(size: 14, weight: .regular))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 16)
    }

    private func handle(this error: UserError) {
        switch error {
        case .inputPasswordError:
            passwordErrorMessage = error.message
            viewModel.uiState.isValidPassword = false
        default:
            errorAlertTitle = LocalizedStringKey(error.title)
            errorAlertMessage = LocalizedStringKey(error.message)
            isShowingErrorAlert = true
        }
    }
}
