//
//  TileBackgroundImage.swift
//  TempoPro
//
//  Created by Meters on 3/3/2025.
//


import SwiftUI
import UIKit

// 添加扩展来设置平铺图像的尺寸

extension Image {
    func customTiledBackground(tileSize: CGSize) -> some View {
        GeometryReader { geometry in
            self.resizable(resizingMode: .tile)
                .frame(width: tileSize.width, height: tileSize.height)
                .clipped()
                .drawingGroup() // 提高性能
                .customRepeating(x: Int(ceil(geometry.size.width / tileSize.width)),
                           y: Int(ceil(geometry.size.height / tileSize.height)))
        }
    }
}

// 添加扩展来重复视图
extension View {
    func customRepeating(x: Int, y: Int) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<y, id: \.self) { _ in
                HStack(spacing: 0) {
                    ForEach(0..<x, id: \.self) { _ in
                        self
                    }
                }
            }
        }
    }
}
// ... existing code ...
