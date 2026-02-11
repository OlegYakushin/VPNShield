//
//  FunctionForResize.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 31/7/25.
//

import Foundation
import SwiftUI

func isPad() -> Bool {
     return UIDevice.current.userInterfaceIdiom == .pad
 }

func sizeScreen() -> CGFloat {
    let screenWidth = UIScreen.main.bounds.width
       let screenHeight = UIScreen.main.bounds.height
       
       if UIDevice.current.userInterfaceIdiom == .pad {
           if screenWidth == 1024 {
               return screenWidth / 1024
           }
          else if screenWidth > 1024 {
               return screenWidth / 1024
           } else if screenWidth > 768 {
               return screenWidth / 1024
           } else {
               return screenWidth / 1024
           }
       } else {
           if UIScreen.main.bounds.width == 375 {
               return screenWidth / 480
           } else {
               if screenWidth > screenHeight {
                   return screenWidth / 812
               } else {
                   return screenWidth / 360
               }
           }
       }
   }


