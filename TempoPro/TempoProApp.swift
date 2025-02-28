//
//  TempoProApp.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/2/27.
//

import SwiftUI

@main
struct TempoProApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environment(\.metronomeTheme, themeManager.currentTheme)
                .onChange(of: themeManager.currentThemeName) { _ in
                    // 通过主题名称变化来触发环境更新
                }
        }
    }
}
