//
//  PacketTunnelProvider.swift
//  VPNPacketTunnel
//
//  Created by Oleg Yakushin on 6/8/25.
//

import NetworkExtension
import OpenVPNAdapter

// Чтобы packetFlow подходил под OpenVPNAdapter
extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow {}

class PacketTunnelProvider: NEPacketTunnelProvider {
    lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self
        return adapter
    }()

    let reachability = OpenVPNReachability()
    var startCompletion: ((Error?) -> Void)?

    override func startTunnel(options: [String : NSObject]?,
                              completionHandler: @escaping (Error?) -> Void) {
        self.startCompletion = completionHandler

        guard
            let protoConfig = protocolConfiguration as? NETunnelProviderProtocol,
            let ovpnData   = protoConfig.providerConfiguration?["ovpn"] as? Data
        else {
            return completionHandler(NSError(
                domain: "OpenVPN", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid config"]))
        }

        // 1) Применяем конфиг
        let config = OpenVPNConfiguration()
        config.fileContent = ovpnData
        do {
            _ = try vpnAdapter.apply(configuration: config)
        } catch {
            return completionHandler(error)
        }

        // 2) Если требуется логин/пароль:
        if !vpnAdapter.configurationEvaluation.autologin {
            let cred = OpenVPNCredentials()
            cred.username = protoConfig.username!
            // достаём пароль по ключchainRef
            cred.password = retrievePassword(from: protoConfig.passwordReference!)
            do { try vpnAdapter.provide(credentials: cred) }
            catch { return completionHandler(error) }
        }

        // 3) Следим за сменой сети, чтобы корректно переподключаться
        reachability.startTracking { status in
            if status == .reachableViaWiFi {
                self.vpnAdapter.reconnect(interval: 5)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason,
                             completionHandler: @escaping () -> Void) {
        vpnAdapter.disconnect()
        completionHandler()
    }
}

// Обработка колбэков от OpenVPNAdapter
extension PacketTunnelProvider: OpenVPNAdapterDelegate {
    func openVPNAdapter(_ adapter: OpenVPNAdapter,
                        handleLogMessage logMessage: String) {
        // Можно логировать
        NSLog("[OpenVPN] %@", logMessage)
    }

    func openVPNAdapter(_ adapter: OpenVPNAdapter,
                        configureTunnelWithNetworkSettings settings: NEPacketTunnelNetworkSettings,
                        completionHandler: @escaping (Error?) -> Void) {
        // OpenVPNAdapter сгенерировал сетевые настройки (IP, маршруты, DNS)
        setTunnelNetworkSettings(settings, completionHandler: completionHandler)
        // И наконец вызываем старт VPN-туннеля
        startCompletion?(nil)
        startCompletion = nil
    }
}
