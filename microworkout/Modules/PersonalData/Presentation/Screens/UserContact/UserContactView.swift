//
//  ContactView.swift
//  Gula
//
//  Created by Jorge on 29/8/24.
//

import SwiftUI

struct UserContactView: View {
    @Environment(\.presentationMode) var presentation
    @StateObject var viewModel: UserContactViewModel
    @State var shouldNavigate = false
    @State private var continueButtonState: ButtonState = .normal
    @State private var isShowingAlert = false
    @State private var isFieldEmptyCheckedFromView = false
    @State private var errorAlertTitle: LocalizedStringKey = ""
    @State private var errorAlertMessage: LocalizedStringKey = ""
    @FocusState var isFocusedNameTextField: Bool
    @FocusState var isFocusedPhoneTextField: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text("personalData_changePersonalData")
            Text("personalData_changePersonalDataInfo")
            textFields
            Spacer()
            CustomButton(buttonState: $continueButtonState,
                         type: .primary,
                         buttonText: "common_save") {
                didUpdateUserButtonPressed()
            }
                         .padding(.bottom, 10)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("personalData_personalData")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
            ToolbarItem(placement: .topBarLeading) {
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
        .onChange(of: viewModel.uiState.error) { _, error in
            guard let error = viewModel.uiState.error else { return }
            handle(error)
        }
        .onChange(of: viewModel.uiState.canContinue) {
            shouldNavigate = viewModel.uiState.canContinue
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text(errorAlertTitle),
                message: Text(errorAlertMessage),
                dismissButton: .default(Text(LocalizedStringKey("common_accept")), action: {
                    viewModel.uiState.error = nil
                })
            )
        }
        .navigationDestination(isPresented: $shouldNavigate, destination: {
            EmptyView()
        })
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .padding(.top, 20)
        .padding(.horizontal, 16)
        .onAppear {
            viewModel.getUser()
        }
        .overlay {
            VStack {
                ToastView(isVisible: $viewModel.uiState.needToShowToast,
                          message: "personalData_savedSuccess",
                          isCloseButtonActive: true,
                          textAlingment: .leading,
                          textHorizontalPadding: 20,
                          closeAction:  {
                    withAnimation(.easeInOut) {
                        viewModel.uiState.needToShowToast = false
                    }
                })
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.easeInOut) {
                        viewModel.uiState.needToShowToast = false
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    @ViewBuilder
    private var textFields: some View {
        VStack {
            CustomTextField(text: $viewModel.name,
                            isFieldValid: .constant(true),
                            title: "personalData_completeName",
                            placeholder: "personalData_completeName",
                            errorMessage: LocalizedStringKey(viewModel.uiState.fullnameErrorMessage),
                            maxLength: 50,
                            isFieldMandatory: true,
                            isFieldEmptyCheckedFromView: isFieldEmptyCheckedFromView,
                            isFocused: _isFocusedNameTextField)

            CustomTextField(text: $viewModel.phone,
                            isFieldValid: $viewModel.uiState.isValidPhone,
                            title: "personalData_phoneContact",
                            placeholder: "personalData_phone",
                            errorMessage: LocalizedStringKey(viewModel.uiState.phoneErrorMessage),
                            type: .numeric,
                            maxLength: 9,
                            isFieldMandatory: true,
                            isFieldEmptyCheckedFromView: isFieldEmptyCheckedFromView,
                            isFocused: _isFocusedPhoneTextField)
        }
        .padding(.top, 20)
    }

    private func didUpdateUserButtonPressed() {
        isFocusedNameTextField = false
        isFocusedPhoneTextField = false
        isFieldEmptyCheckedFromView = viewModel.name.isEmpty || viewModel.phone.isEmpty
        viewModel.checkIfReadyToContinue()
    }

    private func handle(_ error: UserError) {
        switch error {
        case .inputsError(let fields, let messages):
            fields.enumerated().forEach { index, field in
                if field == "fullname" {
                    viewModel.uiState.fullnameErrorMessage = messages[index]
                }
                if field == "phone" {
                    viewModel.uiState.phoneErrorMessage = messages[index]
                }
            }
        case .inputFullnameError(let message):
            viewModel.uiState.fullnameErrorMessage = message
        case .inputPhoneError(let message):
            viewModel.uiState.phoneErrorMessage = message
        default:
            errorAlertTitle = LocalizedStringKey(error.title)
            errorAlertMessage = LocalizedStringKey(error.message)
            isShowingAlert = true
        }
    }
}
