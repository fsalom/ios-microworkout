//
//  DeeplinkManager.swift
//  Gula
//
//  Created by Jorge Planells Zamora on 23/7/24.
//

import Foundation

class DeepLinkManager: ObservableObject {
    static var shared: DeepLinkManager = .init(scheme: Config.scheme)

    enum Destination: String {
        case none = "__none__"
        case newPassword = "newpassword"
        case registerComplete = "register/verify"
        case changeEmailComplete = "change-email/verify"
        case home = "home"
    }

    @Published var screen: Destination = .none
    var id: String?

    private let scheme: String

    private init(scheme: String) {
        self.scheme = scheme
    }

    func manage(this deeplink: URL) {
        if deeplink.scheme == self.scheme,
           let host = deeplink.host,
           let components = URLComponents(url: deeplink, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let id = queryItems.first(where: { $0.name == "suid" })?.value {
            self.id = id

            let path = "\(host)\(deeplink.path)"
            changeScreen(to: Destination(rawValue: path) ?? .none)
        }
    }

    func changeScreen(to screen: Destination) {
        DispatchQueue.main.async {
            self.screen = screen
        }
    }
}
