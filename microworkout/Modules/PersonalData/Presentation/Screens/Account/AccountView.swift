//
//  AccountView.swift
//  Gula
//
//  Created by Maria on 7/11/24.
//

import SwiftUI

struct AccountView: View {

    enum MenuItem: LocalizedStringKey, CaseIterable {
        case user = "account_user"
        case personalData = "account_personalData"
        case direction = "account_directions"
        case payment = "account_paymentMethod"
        case changePassword = "account_changePassword"
        case changeEmail = "account_changeEmail"
    }

    @Environment(\.presentationMode) var presentation
    @StateObject var viewModel: AccountViewModel
    @State var isShowingVerifyPassword = false
    @State var navigateToNewPassword = false
    @State var didUserTapDeleteAccount = false
    @State var isShowingToast = false
    @State var didUserTapLogoutAccount = false
    @State var toastType: ToastType = .email

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ForEach(MenuItem.allCases.indices, id: \.self) { index in
                    if index != 0 {
                        Divider().background(Color.gray)
                    }
                    menuRow(for: index)
                }
                Divider().background(Color.gray)
            }
            Button("alert_deleteAccountTitle") {
                didUserTapDeleteAccount = true
            }
            .foregroundColor(.black)
            .font(.system(size: 18))
            .padding()
            Button("common_logout") {
                didUserTapLogoutAccount = true
            }
            .foregroundColor(.black)
            .font(.system(size: 18))
            .padding()
            Spacer()
        }
        .onChange(of: viewModel.uiState.isDeleteAccountSuccessful, { _, isDeleteAccountSuccessful in
            toastType = .deleteAccount
            isShowingToast = isDeleteAccountSuccessful
        })
        .alert("account_alert_logoutAccountTitle", isPresented: $didUserTapLogoutAccount) {
            Button("common_cancel", role: .cancel) {
                didUserTapLogoutAccount = false
            }
            Button("common_logout", role: .destructive) {
                viewModel.logout()
            }
        } message: {
            Text("common_logoutAccountMessage")
        }
        .alert("account_alert_deleteAccountTitle", isPresented: $didUserTapDeleteAccount) {
            Button("common_cancel", role: .cancel) {
                didUserTapDeleteAccount = false
            }
            Button("common_delete", role: .destructive) {
                viewModel.deleteAccount()
                didUserTapDeleteAccount = false
            }
        } message: {
            Text("alert_deleteAccountMessage")
        }
        .alert("error_unexpectedError", isPresented: $viewModel.uiState.didFindErrorWhenDeletingAccount) {
            Button("common_accept", role: .cancel) {
                viewModel.uiState.didFindErrorWhenDeletingAccount = false
            }
        } message: {
            Text("error_unexpectedErrorMessage")
        }
        .padding(.top, 16)
        .toolbar {
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
            ToolbarItem(placement: .principal) {
                Text("account_title")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .onAppear {
            viewModel.getUser()
        }
        .sheet(isPresented: $isShowingVerifyPassword, content: {
            VerifyPasswordBuilder().build(isShowingVerifyPasswordSheet: $isShowingVerifyPassword,
                                          navigateToNewPassword: $navigateToNewPassword)
        })
        .navigationDestination(isPresented: $navigateToNewPassword) {
            ChangePasswordBuilder().build(needToShowToast: $isShowingToast)
        }
        .overlay(
            VStack {
                ToastView(isVisible: $isShowingToast,
                          message: toastType.message,
                          isCloseButtonActive: true,
                          textAlingment: .leading,
                          textHorizontalPadding: 20,
                          closeAction:  {
                    withAnimation(.easeInOut) {
                        isShowingToast = false
                        toastType = .email
                    }
                })
            }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation(.easeInOut) {
                            isShowingToast = false
                            toastType = .email
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        )
    }

    @ViewBuilder
    private func menuRow(for index: Int) -> some View {
        let item = MenuItem.allCases[index]

        if item == .user {
            HStack {
                Text(viewModel.userName)
                    .font(.system(size: 16)).bold()
                    .foregroundColor(.black)
                    .padding(.vertical, 19)
                Spacer()
            }
            .padding(.horizontal)
        } else if item != .changePassword {
            NavigationLink(destination: destinationView(for: item)) {
                HStack {
                    Text(item.rawValue)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .padding(.vertical, 19)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
            }
        } else {
            Button {
                toastType = .password
                isShowingVerifyPassword = true
            } label: {
                HStack {
                    Text(item.rawValue)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .padding(.vertical, 19)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for item: MenuItem) -> some View {
        switch item {
        case .personalData:
            UserContactBuilder().build()
        case .direction:
            // Uncoment when directions module is implemented
            // AccountAddressesBuilder().build()
            EmptyView()
        case .changeEmail:
            ChangeEmailBuilder().build()

        default:
            EmptyView()
        }
    }
}
