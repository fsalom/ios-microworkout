//
//  StackView.swift
//  CucharaDePlata
//
//  Created by Adrián Prieto Villena on 27/1/25.
//

import SwiftUI

struct StackView: View {
    @State private var navigator: NavigatorProtocol
    var root: () -> any View

    init(navigator: NavigatorProtocol = Navigator.shared, root: @escaping () -> any View) {
        self.navigator = navigator
        self.root = root
    }

    var body: some View {
        NavigationStack(path: $navigator.path) {
            AnyView(root())
                .navigationDestination(for: Page.self) { page in
                    page
                }
        }
    }
}
