//
//  Page.swift
//  CucharaDePlata
//
//  Created by Adrián Prieto Villena on 20/1/25.
//

import SwiftUI

struct Page: View, Equatable, Hashable, Identifiable {
    let id: UUID = .init()
    private let view: AnyView

    var body: some View {
        view
    }

    init(from view: any View) {
        self.view = AnyView(view)
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
