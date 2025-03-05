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
    
    // 注入PersistenceController
    let persistenceController = PersistenceController.shared
    
    // 添加 CoreDataPlaylistManager 替代原来的 PlaylistManager
    @StateObject private var coreDataPlaylistManager: CoreDataPlaylistManager
    
    // 应用生命周期事件观察
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // 应用启动时就禁用屏幕熄屏
        UIApplication.shared.isIdleTimerDisabled = true
        
        // 初始化CoreDataPlaylistManager
        let manager = CoreDataPlaylistManager(context: PersistenceController.shared.viewContext)
        self._coreDataPlaylistManager = StateObject(wrappedValue: manager)
        
        // 创建示例数据（如果需要）
        manager.createSampleDataIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(coreDataPlaylistManager) // 使用CoreDataPlaylistManager
                .environment(\.metronomeTheme, themeManager.currentTheme)
                .environment(\.managedObjectContext, persistenceController.viewContext)
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
                // 保存CoreData更改
                persistenceController.save()
                print("应用进入后台，已保存数据")
            @unknown default:
                print("未知场景状态")
            }
        }
    }
}
