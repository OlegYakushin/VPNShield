//
//  Configuration.swift
//  Demo
//
//  Created by Davide De Rosa on 6/13/20.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/keeshux
//
//  This file is part of TunnelKit.
//
//  TunnelKit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  TunnelKit is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with TunnelKit.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
// import TunnelKitCore
// import TunnelKitOpenVPN

#if os(macOS)
let appGroup = "DTDYD63ZX9.group.com.algoritmico.TunnelKit.Demo"
private let bundleComponent = "macos"
#elseif os(iOS)
let appGroup = "group.com.algoritmico.TunnelKit.Demo"
private let bundleComponent = "ios"
#else
let appGroup = "group.com.algoritmico.TunnelKit.Demo"
private let bundleComponent = "tvos"
#endif

enum TunnelIdentifier {
    static let openVPN = "com.algoritmico.\(bundleComponent).TunnelKit.Demo.OpenVPN-Tunnel"

    static let wireGuard = "com.algoritmico.\(bundleComponent).TunnelKit.Demo.WireGuard-Tunnel"
}


