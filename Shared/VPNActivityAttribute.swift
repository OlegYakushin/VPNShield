//
//  VPNActivityAttribute.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 31/7/25.
//
import Foundation
import ActivityKit

public struct VPNActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var isConnected: Bool
        public var serverName: String
        public var startedAt: Date
        public init(isConnected: Bool, serverName: String, startedAt: Date) {
            self.isConnected = isConnected
            self.serverName = serverName
            self.startedAt = startedAt
        }
    }
    public var serviceName: String  // "VPN ЩИТ"
    public init(serviceName: String) { self.serviceName = serviceName }
}


