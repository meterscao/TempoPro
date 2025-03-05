// AppStorageKeys.swift
// 集中管理应用中所有UserDefaults/AppStorage键

import Foundation

/// 集中定义所有应用存储键，避免硬编码字符串
struct AppStorageKeys {
    /// 基础前缀，用于所有键
    static let prefix = "us.besttime.tempopro"
    
    /// 创建带前缀的完整键
    private static func key(_ name: String) -> String {
        return "\(prefix).\(name)"
    }
    
    // 节拍器相关设置
    struct Metronome {
        /// 每小节拍数键
        static let beatsPerBar = key("beatsPerBar")
        
        /// 拍号单位键
        static let beatUnit = key("beatUnit")
        
        /// 速度/BPM键
        static let tempo = key("tempo")
        
        /// 节拍强度配置键
        static let beatStatuses = key("beatStatuses")
        
        /// 当前节拍键
        static let currentBeat = key("currentBeat")
        
        // 在 Metronome 结构体中添加
        static let subdivisionType = key("subdivisionType")
    }
    
    // 主题相关设置
    struct Theme {
        /// 当前主题键
        static let currentTheme = key("currentTheme")
    }
    
    // DispatchQueue标签
    struct QueueLabels {
        /// 节拍器定时器队列标签
        static let metronomeTimer = "\(prefix).metronome.timer"
    }
} 
