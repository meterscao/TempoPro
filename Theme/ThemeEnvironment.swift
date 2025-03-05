// ThemeEnvironment.swift
import SwiftUI

// 环境键
struct ThemeKey: EnvironmentKey {
    static let defaultValue: MetronomeTheme = .greenTheme
}

// 扩展环境值
extension EnvironmentValues {
    var metronomeTheme: MetronomeTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
} 