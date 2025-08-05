//  CustomTextField.swift
//  Gula
//
//  Created by Jorge Planells Zamora on 4/7/24.
//

import SwiftUI

enum TextFieldType {
    case text
    case password
    case numeric
}

struct CustomTextField: View {
    @Binding var text: String
    @Binding var isFieldValid: Bool
    @State var hasUserStartedTyping: Bool = false
    @State var areValidationsActive = false
    @State var isSecured: Bool = true
    var title: LocalizedStringKey?
    var subtitle: Text?
    var isDisabled: Bool = false
    var placeholder: LocalizedStringKey
    var textFieldFontSize: CGFloat = 14
    var warningFontSize: CGFloat = 12
    var errorMessage: LocalizedStringKey
    var type: TextFieldType = .text
    var maxLength: Int = 999
    var maxHeight: CGFloat = 48
    var textAlignment: Alignment = .center
    var isFieldMandatory: Bool = false
    var isFieldEmptyCheckedFromView: Bool = false
    var getTextFieldType: (_ textFieldType: TextFieldType) -> Void = { _ in }

    private let borderColor: Color = .black
    private let borderOpacity: Double = 0.5
    private let backgroundColor: Color = .black
    private let backgroundOpacity: Double = 0.5
    private let titleColor: Color = .white
    private let subtitleColor: Color = .white
    private let errorColor: Color = .red

    var displayErrorWarning: Bool {
        areValidationsActive && !isFieldValid && !text.isEmpty && hasUserStartedTyping
    }
    var displayFieldIsMandatoryWarning: Bool {
        (areValidationsActive && isFieldMandatory && hasUserStartedTyping && text.isEmpty) || (isFieldEmptyCheckedFromView && !hasUserStartedTyping)
    }
    @FocusState var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading) {
                if let title {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 14))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let subtitle = subtitle {
                            VStack(alignment: .leading, spacing: 4) {
                                subtitle
                                    .font(.system(size: 12))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundStyle(displayErrorWarning || displayFieldIsMandatoryWarning ? Color.red : Color.gray)
                            }
                        }

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .onChange(of: isFocused) {
                if hasUserStartedTyping {
                    self.areValidationsActive = true
                }
            }
            HStack(spacing: 8) {
                let textFieldPlaceholder = Text(placeholder)
                    .font(.system(size: textFieldFontSize, weight: .light))
                    .foregroundColor(.gray)

                switch type {
                case .text:
                    TextField("", text: $text, prompt: textFieldPlaceholder)
                        .font(.system(size: textFieldFontSize, weight: .light))
                        .textInputAutocapitalization(.never)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: textAlignment)
                        .padding(12)
                        .focused($isFocused)
                        .onChange(of: text, { _, _ in
                            hasUserStartedTyping = true
                            text = String(text.prefix(maxLength))
                        })
                        .foregroundStyle(isDisabled ? Color(.systemGray4) : .black)
                        .disabled(isDisabled)
                case .numeric:
                    TextField("", text: $text, prompt: textFieldPlaceholder)
                        .font(.system(size: textFieldFontSize, weight: .light))
                        .textInputAutocapitalization(.never)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: textAlignment)
                        .padding(12)
                        .focused($isFocused)
                        .keyboardType(.numberPad)
                        .onChange(of: text, { _, _ in
                            hasUserStartedTyping = true
                            text = String(text.prefix(maxLength))
                        })

                case .password:
                    let passwordMaxLength = 15
                    if isSecured {
                        SecureField("", text: $text, prompt: textFieldPlaceholder)
                            .font(.system(size: textFieldFontSize, weight: .light))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: textAlignment)
                            .padding(12)
                            .focused($isFocused)
                            .onChange(of: text, { _, _ in
                                hasUserStartedTyping = true
                                text = String(text.prefix(passwordMaxLength))
                            })
                    } else {
                        TextField("", text: $text, prompt: textFieldPlaceholder)
                            .font(.system(size: textFieldFontSize, weight: .light))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: textAlignment)
                            .padding(12)
                            .focused($isFocused)
                            .onChange(of: text, { _, _ in
                                hasUserStartedTyping = true
                                text = String(text.prefix(passwordMaxLength))
                            })
                    }
                    Button {
                        self.isSecured.toggle()
                    } label: {
                        Image(systemName: isSecured ? "eye" : "eye.slash")
                            .padding(.trailing, 12)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onChange(of: isFocused) {
                if isFocused {
                    getTextFieldType(type)
                }
            }
            .frame(maxWidth: .infinity, minHeight: maxHeight, maxHeight: maxHeight, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 6)
                .stroke(strokeColor, lineWidth: 2))
            .cornerRadius(6)

            Text(displayFieldIsMandatoryWarning ? "common_mandatoryField" : errorMessage)
                .font(.system(size: warningFontSize))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, maxHeight: 12, alignment: .leading)
                .padding(.top, 8)
                .padding(.bottom, 16 - warningFontSize)
                .opacity(displayErrorWarning || displayFieldIsMandatoryWarning ? 1 : 0 )
        }
    }

    var strokeColor: Color {
        if displayErrorWarning || displayFieldIsMandatoryWarning {
            return Color.red
        }

        if isFocused {
            return Color.black
        }

        return Color(.systemGray5)
    }
}
