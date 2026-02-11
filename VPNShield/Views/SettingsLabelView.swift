//
//  SettingsLabelView.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 4/8/25.
//

import SwiftUI

struct SettingsLabelView: View {
    var icon: String
    var text: String
    var body: some View {
        HStack{
            Image(icon)
                .resizable()
                .frame(width: 13 * sizeScreen(), height:  13 * sizeScreen())
            Text(text)
                .font(.custom("WixMadeforText-Regular", size: 15 * sizeScreen()))
                .foregroundStyle(.mainText)
            Spacer()
            Image("arrowleft")
                .resizable()
                .frame(width: 8 * sizeScreen(), height:  12 * sizeScreen())
        }
        .frame(width: 320 * sizeScreen(), height: 23 * sizeScreen())
    }
}

#Preview {
    SettingsLabelView(icon: "copyIcon", text: "Скопировать ID")
}
