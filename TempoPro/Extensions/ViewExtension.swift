//
//  ViewExtension.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/21.
//

import SwiftUI

extension View {
    @ViewBuilder
    func compatibleCornerRadius(_ radius: CGFloat) -> some View {
        if #available(iOS 16.4, macOS 13.3, *) {
            self.presentationCornerRadius(radius)
        } else {
            self
        }
    }
}
