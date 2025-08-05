//
//  ChangeEmailView.swift
//  Gula
//
//  Created by Jesu Castellano on 5/11/24.
//

import SwiftUI

struct ChangeEmailView: View {
    @Environment(\.presentationMode) var presentation
    @ObservedObject var viewModel: ChangeEmailViewModel
    @State private var errorAlertTitle: LocalizedStringKey = ""
    @State private var errorAlertMessage: LocalizedStringKey = ""
    @State private var showAlert = false
    @State private var isFieldEmptyCheckedFromView = false
    @FocusState var isFocusedEmailField: Bool

    var body: some View {
        VStack {
            VStack(spacing: 8) {
                Text("auth_updateEmail")
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .font(.system(size: 14))
                    .bold()
                Text("auth_changeEmailInfo")
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity,alignment: .leading)
            }
            .padding(.top, 24)
            .padding(.bottom, 40)

            CustomTextField(text: $viewModel.email,
                            isFieldValid: $viewModel.uiState.isValidEmail,
                            title: "auth_newEmail",
                            placeholder: "auth_writeEmail",
                            errorMessage: LocalizedStringKey(viewModel.uiState.emailErrorMessage),
                            isFieldMandatory: true,
                            isFieldEmptyCheckedFromView: isFieldEmptyCheckedFromView,
                            isFocused: _isFocusedEmailField
            )
            CustomButton(buttonState: $viewModel.uiState.sendButtonState,
                         type: .primary,
                         buttonText: "auth_update") {
                isFocusedEmailField = false
                isFieldEmptyCheckedFromView = viewModel.email.isEmpty
                viewModel.changeEmail()
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .navigationDestination(isPresented: $viewModel.uiState.hasEmailBeenSent, destination: {
            EmptyView()
        })
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: viewModel.uiState.error) { _, error in
            guard let error  else { return }
            handle(error: error)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(errorAlertTitle), message: Text(errorAlertMessage), dismissButton: .default(Text("common_accept"), action: {
                viewModel.uiState.error = nil
            }))
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("auth_changeEmailToolbarTitle")
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
                            .frame(maxWidth: 16, maxHeight: 16)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private func handle(error: UserError) {
        switch error {
        case .inputEmailError:
            isFieldEmptyCheckedFromView = true
            viewModel.uiState.emailErrorMessage = error.message
            viewModel.uiState.isValidEmail = false
            viewModel.uiState.error = nil
        default:
            errorAlertTitle = LocalizedStringKey(error.title)
            errorAlertMessage = LocalizedStringKey(error.message)
            showAlert = true
        }
    }
}
