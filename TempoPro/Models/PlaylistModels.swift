import Foundation
import SwiftUI

// 歌曲模型
struct SongModel: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var bpm: Int
    var beatsPerBar: Int
    var beatUnit: Int
    var beatStatuses: [Int] // 0: strong, 1: medium, 2: normal, 3: muted
    
    // 将 Int 数组转换为 BeatStatus 数组
    func getBeatStatuses() -> [BeatStatus] {
        return beatStatuses.map { statusInt -> BeatStatus in
            switch statusInt {
            case 0: return .strong
            case 1: return .medium
            case 2: return .normal
            case 3: return .muted
            default: return .normal
            }
        }
    }
    
    static func == (lhs: SongModel, rhs: SongModel) -> Bool {
        return lhs.id == rhs.id
    }
}

// 歌单模型
struct PlaylistModel: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var songs: [SongModel]
    var color: String // 存储颜色的Hex值
    
    // 获取UI颜色
    func getColor() -> Color {
        return Color(hex: color) ?? .blue
    }
    
    static func == (lhs: PlaylistModel, rhs: PlaylistModel) -> Bool {
        return lhs.id == rhs.id
    }
}
