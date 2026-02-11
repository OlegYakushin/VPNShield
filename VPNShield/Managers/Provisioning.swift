//
//  Provisioning.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 6/8/25.
//

import Foundation

import Foundation

import Foundation

struct Provisioning {
    let api: VPNResellersAPI

    /// Фиксированные учётные данные
    private let username = "adminIos"
    private let password = "something89"

    /// Просто валидируем пару и возвращаем id
    func account() async throws -> (id: Int, username: String) {
        let v = try await api.validate(username: username, password: password)
        guard v.success, let id = v.id else {
            throw NSError(domain: "Provisioning",
                          code: Int(v.code) ?? 0,
                          userInfo: [NSLocalizedDescriptionKey: v.message])
        }
        return (id, username)
    }
}
