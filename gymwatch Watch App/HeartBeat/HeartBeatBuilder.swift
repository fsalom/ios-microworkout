//
//  HeartBeatBuilder.swift
//  gymwatch Watch App
//
//  Created by Fernando Salom Carratala on 7/8/23.
//

import Foundation

class HeartBeatBuilder {
    func build() -> HeartBeatView {
        let viewModel = HeartBeatViewModel()
        let view = HeartBeatView(viewModel: viewModel)
        return view
    }
}
