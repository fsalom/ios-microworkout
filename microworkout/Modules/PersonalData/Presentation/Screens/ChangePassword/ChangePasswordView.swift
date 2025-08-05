//
//  Gula
//
//  ChangePasswordView.swift
//
//  Created by Rudo Apps on 7/5/25
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentation
    @ObservedObject var viewModel: ChangePasswordViewModel
    @State private var errorAlertTitle: LocalizedStringKey = ""
    @State private var errorAlertMessage: LocalizedStringKey = ""
    @State private var showAlert = false
    @State private var sendButtonState: ButtonState = .normal
    @State private var navigateToFakeShowToast = false
    @FocusState var isFocusedNewPasswordTextField: Bool
    @FocusState var isFocusedRepeatPasswordTextField: Bool

    var body: some View {
        VStack(alignment: .leading) {
            header
            fields
            Spacer()
        }
        .onChange(of: viewModel.uiState.areAllFieldsOk, { _, areAllFieldsOk in
            if areAllFieldsOk {
                sendButtonState = .loading
                viewModel.changePassword()
            }
        })
        .onChange(of: viewModel.uiState.error, { _, error in
            guard let error else { return }
            sendButtonState = .normal
            handle(this: error)
            viewModel.uiState.areAllFieldsOk = false
        })
        .onChange(of: viewModel.uiState.hasChangePasswordSucceeded, { _, _ in
            presentation.wrappedValue.dismiss()
        })
        .alert(isPresented: $showAlert) {
            Alert(title: Text(errorAlertTitle), message: Text(errorAlertMessage), dismissButton: .default(Text("common_accept"), action: {
                viewModel.uiState.error = nil
            }))
        }
        .padding(.horizontal, 16)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("auth_password")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
            ToolbarItem(placement: .topBarLeading) {
                HStack {
                    Button {
                        presentation.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(maxWidth: 16, maxHeight: 16)
                    }
                }
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("auth_updateWriteNewPassword")
                .font(.system(size: 16, weight: .semibold))
            Text("auth_newPasswordInformation")
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(8)
        }
        .padding(.bottom, 32)
        .padding(.top, 24)
    }

    @ViewBuilder
    private var fields: some View {
        VStack {
            CustomTextField(text: $viewModel.password,
                            isFieldValid: $viewModel.uiState.isValidPassword,
                            title: "auth_newPassword",
                            placeholder: "auth_newPassword",
                            errorMessage: LocalizedStringKey(viewModel.uiState.passwordErrorMessage),
                            type: .password,
                            maxLength: 15,
                            isFieldMandatory: true)
            CustomTextField(text: $viewModel.repeatPassword,
                            isFieldValid: $viewModel.uiState.arePasswordsEqual,
                            title: "auth_repeatPassword",
                            placeholder: "auth_repeatNewPassword",
                            errorMessage: "auth_passwordsDoNotMatch",
                            type: .password,
                            maxLength: 15,
                            isFieldMandatory: true)
            CustomButton(buttonState: $sendButtonState,
                         type: .primary,
                         buttonText: "auth_update") {
                viewModel.checkIfReadyToChangePassword()
                isFocusedNewPasswordTextField = false
                isFocusedRepeatPasswordTextField = false
            }
        }
    }

    private func handle(this error: UserError) {
        switch error {
        case .inputsError(let fields, let messages):
            fields.enumerated().forEach { index, field in
                if field == "password" {
                    viewModel.uiState.passwordErrorMessage = messages[index]
                    viewModel.uiState.isValidPassword = false
                }
            }
        default:
            errorAlertTitle = LocalizedStringKey(error.title)
            errorAlertMessage = LocalizedStringKey(error.message)
            showAlert = true
        }
    }
}
