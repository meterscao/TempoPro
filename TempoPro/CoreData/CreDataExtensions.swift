//
//  CreDataExtensions.swift
//  TempoPro
//
//  Created by Meters on 5/3/2025.
//

import Foundation
import CoreData
import SwiftUI

// Song实体扩展
extension Song {
    
    
    // 获取 BeatStatus 数组
        func getBeatStatuses() -> [BeatStatus] {
            let statusArray = self.beatStatuses as? [Int] ?? []
            return statusArray.map { statusInt -> BeatStatus in
                switch statusInt {
                case 0: return .strong
                case 1: return .medium
                case 2: return .normal
                case 3: return .muted
                default: return .normal
                }
            }
        }
    
}

// Playlist实体扩展
extension Playlist {
    
    
    // 获取UI颜色
        func getColor() -> Color {
            return Color(hex: self.color ?? "#0000FF") ?? .blue
        }
        
        // 获取所有曲目
        var songsArray: [Song] {
            return self.songs?.allObjects as? [Song] ?? []
        }
}
