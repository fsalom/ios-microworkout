import Foundation

struct AuthenticatedUser: Codable, Equatable {
    let id: Int
    let email: String
    let fullname: String
    let phone: String?
}
