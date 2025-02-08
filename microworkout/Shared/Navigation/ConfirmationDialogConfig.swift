//
//  ConfirmationDialogConfig.swift
//  CucharaDePlata
//
//  Created by Adrián Prieto Villena on 28/1/25.
//

import SwiftUI

public struct ConfirmationDialogConfig {
    @ViewBuilder let actions: any View

    init(actions:  @escaping () -> any View) {
        self.actions = actions()
    }
}
