//
//  AlertConfig.swift
//  CucharaDePlata
//
//  Created by Adrián Prieto Villena on 20/1/25.
//

import SwiftUI

public struct AlertConfig {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder let actions: any View

    init(title: LocalizedStringKey, message: LocalizedStringKey, actions: @escaping () -> any View) {
        self.title = title
        self.message = message
        self.actions = actions()
    }
}
