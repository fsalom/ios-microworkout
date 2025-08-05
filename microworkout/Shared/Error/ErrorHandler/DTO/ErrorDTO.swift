//
//  ErrorDTO.swift
//  Gula
//
//  Created by Axel Pérez Gaspar on 20/8/24.
//

import Foundation

struct ErrorDTO: Codable {
    let type: String
    let field: String?
    let message: String
}
