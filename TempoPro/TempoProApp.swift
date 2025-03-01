//
//  TempoProApp.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/2/27.
//

import SwiftUI
import UIKit

@main
struct TempoProApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    // 添加应用生命周期事件观察
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // 应用启动时就禁用屏幕熄屏
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environment(\.metronomeTheme, themeManager.currentTheme)
                .onChange(of: themeManager.currentThemeName) { _ in
                    // 通过主题名称变化来触发环境更新
                }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // 应用进入前台时确保屏幕不会熄屏
                UIApplication.shared.isIdleTimerDisabled = true
                print("应用进入前台，保持屏幕常亮")
            case .inactive:
                print("应用进入非活跃状态")
            case .background:
                // 应用进入后台时，可以考虑恢复系统默认的熄屏设置以节省电池
                print("应用进入后台，保持屏幕熄屏设置不变")
                // 注释掉下面一行，让应用即使在后台也保持屏幕常亮设置
                // UIApplication.shared.isIdleTimerDisabled = false
            @unknown default:
                print("未知场景状态")
            }
        }
    }
}
