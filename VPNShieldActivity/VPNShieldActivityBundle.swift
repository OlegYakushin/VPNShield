//
//  VPNShieldActivityBundle.swift
//  VPNShieldActivity
//
//  Created by Oleg Yakushin on 31/7/25.
//

import WidgetKit
import SwiftUI

@main
struct VPNShieldActivityBundle: WidgetBundle {
    var body: some Widget {
        VPNShieldActivity()
        VPNShieldActivityControl()
        VPNLiveActivity() 
    }
}
