//
//  UserMapper.swift
//
//  Created automatically
//

import Foundation

struct UserMapper {
    func toDomain(_ dto: UserDTO) -> User {
        User(id: dto.id,
             fullname: dto.fullname,
             phone: dto.phone,
             email: dto.email)
    }
}
