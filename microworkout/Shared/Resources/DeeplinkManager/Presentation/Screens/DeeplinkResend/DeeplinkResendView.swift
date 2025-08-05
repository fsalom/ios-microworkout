//
//  Gula
//
//  DeeplinkResendView.swift
//
//  Created by Rudo Apps on 9/5/25
//

import SwiftUI

struct DeeplinkResendView: View {
    @StateObject var viewModel: DeeplinkResendViewModel
    @Environment(\.presentationMode) var presentation

    var body: some View {
        VStack(spacing: 50) {
            Image(systemName: "pencil")
                .frame(width: 100, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(.gray)
                )
            VStack(spacing: 35) {
                Text(viewModel.config.title)
                    .font(.system(size: 20))
                    .bold()
                Text(viewModel.config.message)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)
                    .font(.system(size: 18))
                VStack(spacing: 0) {
                    Text("auth_emailNotReceived")
                        .font(.system(size: 14))
                    Button {
                        switch viewModel.config.messageType {
                        case .emailVerification:
                            viewModel.resendLinkVerification()
                        case .recoverPassword:
                            presentation.wrappedValue.dismiss()
                        }
                    } label: {
                        Text("auth_sendAgain")
                            .font(.system(size: 14))
                            .bold()
                            .foregroundStyle(.black)
                            .underline()
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .navigationBarBackButtonHidden()
        .overlay {
            VStack {
                ToastView(isVisible: $viewModel.uiState.needToShowToast,
                          message: "auth_changeEmailSent",
                          isCloseButtonActive: true,
                          textAlingment: .leading,
                          closeAction:  {
                    withAnimation(.easeInOut) {
                        viewModel.uiState.needToShowToast = false
                    }
                })
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation(.easeInOut) {
                            viewModel.uiState.needToShowToast = false
                        }
                    }
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    DeepLinkManager.shared.changeScreen(to: .none)
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.black)
                        .frame(width: 19, height: 19)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(Config.appName)
                    .font(.system(size: 20))
                    .bold()
            }
        }
    }
}
