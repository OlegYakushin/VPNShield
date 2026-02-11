//
//  VPNResellersAPI.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 6/8/25.
//

import Foundation

import Foundation

// MARK: – Public façade
struct VPNResellersAPI {

    // ────────── static data ──────────
    private let base  = URL(string: "https://api.vpnresellers.com")!
    private let token = "ID-9874~cpFYjQ08T357HKJXyWIA4ixrEoSfBaOLdGzNDRqVu9sUvtwCkbnPMhZe6lg12m"

    // MARK: – High-level calls
    // 1. login (существующий user → id)
    func login(username: String, password: String) async throws -> Int {
        let r = try await validate(username: username, password: password)
        guard r.success, let id = r.id else {
            throw APIError.server(r.message)
        }
        return id
    }
    func openvpnConfig(accountId: Int,serverId: Int,
                       portId: Int? = nil) async throws -> OVPNConfigResponse {
        var q: [URLQueryItem] = [.init(name: "server_id", value: String(serverId))]
        if let portId {
            q.append(.init(name: "port_id", value: String(portId)))
        }

        return try await request("v3_2/configuration", query: q, as: OVPNConfigResponse.self)
    }
    // 2. openvpn config (можно передать port_id, если сервер его требует)
 

    // 3. plain helpers из v3.2
    func listServers()                        async throws -> ServersResponse { try await request("v3_2/servers", as: ServersResponse.self) }
    func checkUsername(_ u:String)            async throws -> CheckUsername   { try await request("v3_2/accounts/check_username", query:[.init(name:"username",value:u)], as: CheckUsername.self) }
    func createAccount(username: String,
                       password: String)      async throws -> AccountResponse  { try await request("v3_2/accounts", method:"POST", json:CreateAccount(username:username,password:password), as: AccountResponse.self) }
    func validate(username: String,
                          password: String)   async throws -> ValidateResponse { try await request("v3_2/accounts/validate", method:"POST", json:ValidateRequest(username:username,password:password), as: ValidateResponse.self) }

    // Optional helper: сохранить .ovpn в Documents (для AirDrop/TestFlight проверки)
    func save(_ response: OVPNConfigResponse) throws -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                     .appendingPathComponent(response.data.file_name)
        try response.data.file_body.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

// MARK: – Generic request/decoder
private extension VPNResellersAPI {

    /// Отправляет запрос и декодирует ответ, либо бросает APIError.server(…) с текстом сервера
    func request<T: Decodable>(
        _ path: String,
        query: [URLQueryItem] = [],
        method: String = "GET",
        json body: Encodable? = nil,
        accept: String = "application/json",
        as type: T.Type
    ) async throws -> T {

        var comp = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            comp.queryItems = query
        }

        var req = URLRequest(url: comp.url!)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(accept, forHTTPHeaderField: "Accept")

        if let body {
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // 🔍 Логируем запрос перед отправкой
        print("[VPN][HTTP] ▶️ Метод: \(method)")
        print("[VPN][HTTP] ▶️ URL: \(comp.url?.absoluteString ?? "неизвестно")")
        if let headers = req.allHTTPHeaderFields {
            print("[VPN][HTTP] ▶️ Заголовки: \(headers)")
        }
        if let body = req.httpBody, let str = String(data: body, encoding: .utf8) {
            print("[VPN][HTTP] ▶️ Тело запроса:\n\(str)")
        }

        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown server error"
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? -1

            print("[VPN][HTTP] ⛔️ Ответ с ошибкой: \(statusCode)")
            print("[VPN][HTTP] ⛔️ Тело ответа:\n\(msg)")
            throw APIError.server(msg)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // JSON не декодируется — печатаем «как есть»
            if let json = try? JSONSerialization.jsonObject(with: data),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
               let str = String(data: pretty, encoding: .utf8) {
                print("⛔️ Decode failed – raw JSON:\n\(str)")
            } else {
                print("⛔️ Decode failed – не удалось преобразовать JSON в человекочитаемый вид")
            }
            throw APIError.decoding(error)
        }
    }
}


// MARK: - Models

struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ e: Encodable) { encodeFunc = e.encode }
    func encode(to e: Encoder) throws { try encodeFunc(e) }
}

struct CheckUsername: Decodable {
    struct D: Decodable { let message: String }
    let data: D
}

struct CreateAccount: Encodable {
    let username: String
    let password: String
}

struct AccountResponse: Decodable {
    struct A: Decodable {
        let id: Int
        let username: String
        let status: String
        let expired_at: String?
    }
    let data: A
}

struct ValidateRequest: Encodable {
    let username: String
    let password: String
}

struct ValidateResponse: Decodable {
    let success: Bool
    let message: String
    let id: Int?
    let code: String
}

struct ServersResponse: Decodable {
    struct Server: Decodable {
        let id: Int
        let name: String
        let ip: String
        let country_code: String
        let city: String
        let capacity: Int
    }
    let data: [Server]
}

struct OVPNConfigResponse: Decodable {
    struct D: Decodable {
        let download_url: String
        let file_body: String
        let file_name: String
    }
    let data: D
}

// import TunnelKit

enum APIError: LocalizedError {
    case server(String), decoding(Error)
    var errorDescription: String? {
        switch self {
        case .server(let msg):   return msg
        case .decoding(let e):   return "Decode failed: \(e.localizedDescription)"
        }
    }
}
