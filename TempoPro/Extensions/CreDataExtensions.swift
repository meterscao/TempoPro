//
//  CreDataExtensions.swift
//  TempoPro
//
//  Created by Meters on 5/3/2025.
//

import Foundation
import CoreData
import SwiftUI

// 为Playlist添加方便的访问方法
extension Playlist {
    // 获取排序后的歌曲数组
    var songsArray: [Song] {
        let set = songs as? Set<Song> ?? []
        return set.sorted { (song1, song2) -> Bool in
            // 安全比较可选日期
            guard let date1 = song1.createdDate, let date2 = song2.createdDate else {
                // 如果任一日期为nil，将nil值排在后面
                return song1.createdDate != nil && song2.createdDate == nil
            }
            // 两个日期都不为nil，正常比较
            return date1 > date2
        }
    }
    
    // 转换颜色
    var uiColor: Color {
        return Color(hex: color ?? "#0000FF") ?? .blue
    }
}

// 为Song添加便捷方法
extension Song {
    // 获取BeatStatus数组
    var beatStatusArray: [BeatStatus] {
        guard let statusArray = beatStatuses as? [Int] else {
            return Array(repeating: .normal, count: Int(beatsPerBar))
        }
        
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
    
    // 设置BeatStatus数组
    func setBeatStatuses(_ statuses: [BeatStatus]) {
        let statusInts = statuses.map { status -> Int in
            switch status {
            case .strong: return 0
            case .medium: return 1
            case .normal: return 2
            case .muted: return 3
            }
        }
        self.beatStatuses = statusInts as NSArray
    }
}
