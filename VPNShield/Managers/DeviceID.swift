//
//  DeviceID.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 30/7/25.
//

import SwiftUI
import Foundation
import Security

enum DeviceID {
    static let service = "com.yourapp.deviceid"
    static let account = "uuid"
    static func getOrCreate() -> String {
        if let d = Keychaing.load(service: service, account: account),
           let s = String(data: d, encoding: .utf8) { return s }
        let uuid = UUID().uuidString.lowercased() // 36 символов
        Keychaing.save(service: service, account: account, data: Data(uuid.utf8))
        return uuid
    }
}

enum Keychaing {
    static func save(service: String, account: String, data: Data) {
        let q: [String:Any] = [kSecClass as String: kSecClassGenericPassword,
                               kSecAttrService as String: service,
                               kSecAttrAccount as String: account,
                               kSecValueData as String: data]
        SecItemDelete(q as CFDictionary); SecItemAdd(q as CFDictionary, nil)
    }
    static func load(service: String, account: String) -> Data? {
        let q: [String:Any] = [kSecClass as String: kSecClassGenericPassword,
                               kSecAttrService as String: service,
                               kSecAttrAccount as String: account,
                               kSecReturnData as String: true,
                               kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?; SecItemCopyMatching(q as CFDictionary, &item)
        return item as? Data
    }
}
