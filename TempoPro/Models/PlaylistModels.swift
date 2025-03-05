import Foundation
import SwiftUI

// 歌曲模型
struct Song: Identifiable, Codable, Equatable {
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
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
}

// 歌单模型
struct Playlist: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var songs: [Song]
    var color: String // 存储颜色的Hex值
    
    // 获取UI颜色
    func getColor() -> Color {
        return Color(hex: color) ?? .blue
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        return lhs.id == rhs.id
    }
}

// 颜色扩展，用于从十六进制字符串创建颜色
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    // 转换颜色为十六进制字符串
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
} 