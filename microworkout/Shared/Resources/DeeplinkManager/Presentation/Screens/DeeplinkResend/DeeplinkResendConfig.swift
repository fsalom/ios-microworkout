//
//  Gula
//
//  DeeplinkResendConfig.swift
//
//  Created by Rudo Apps on 9/5/25
//

import Foundation
import SwiftUI

struct DeeplinkResendConfig {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let email: String
    let messageType: MessageType

    enum MessageType {
        case emailVerification
        case recoverPassword
    }
}
