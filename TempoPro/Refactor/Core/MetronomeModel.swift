//
//  MetronomeModel.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/31.
//
import SwiftUI

// 基础数据模型，定义所有需要存储的属性
struct MetronomeModel {
    // 节拍器基本设置
    var tempo: Int = 120
    var beatsPerBar: Int = 4
    var beatUnit: Int = 4
    var isPlaying: Bool = false
    var currentBeat: Int = 0
    var completedBars: Int = 0
    
    // 节拍模式
    var beatPatterns: [BeatPattern] = [.accented, .normal, .normal, .normal]
    
    // 音效设置
    var soundSet: SoundSet = .woodblock
    
    // 切分音符设置
    var subdivision: Subdivision = .none
    
    // 练习模式设置
    var practiceMode: PracticeMode?
    
    // 辅助枚举定义
    enum BeatPattern: String, Codable, CaseIterable {
        case accented, normal, weak, muted
        
        var displayName: String {
            switch self {
            case .accented: return "强拍"
            case .normal: return "普通拍"
            case .weak: return "弱拍"
            case .muted: return "静音"
            }
        }
    }
    
    enum SoundSet: String, Codable, CaseIterable {
        case click, woodblock, metronome, drum
        
        var displayName: String {
            switch self {
            case .click: return "点击音"
            case .woodblock: return "木鱼"
            case .metronome: return "节拍器"
            case .drum: return "鼓声"
            }
        }
    }
    
    enum Subdivision: String, Codable, CaseIterable {
        case none, duplet, triplet, quadruplet
        case custom
        
        var displayName: String {
            switch self {
            case .none: return "无切分"
            case .duplet: return "2连音"
            case .triplet: return "3连音"
            case .quadruplet: return "4连音"
            case .custom: return "自定义"
            }
        }
    }
    
    enum PracticeMode: Codable {
        case countdown(minutes: Int)
        case barCount(count: Int)
        case combined(minutes: Int, barCount: Int)
    }
}

// 持久化设置模型
struct MetronomeSettings: Codable {
    var tempo: Int = 120
    var beatsPerBar: Int = 4
    var beatUnit: Int = 4
    var beatPatterns: [String] = ["accented", "normal", "normal", "normal"]
    var soundSet: String = "woodblock"
    var subdivision: String = "none"
    
    // 构造函数，从MetronomeModel转换
    init(from model: MetronomeModel) {
        self.tempo = model.tempo
        self.beatsPerBar = model.beatsPerBar
        self.beatUnit = model.beatUnit
        self.beatPatterns = model.beatPatterns.map { $0.rawValue }
        self.soundSet = model.soundSet.rawValue
        self.subdivision = model.subdivision.rawValue
    }
}

// 预设模型
struct MetronomePreset: Codable, Identifiable {
    var id = UUID().uuidString
    var name: String
    var settings: MetronomeSettings
}
