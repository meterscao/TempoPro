//
//  TempoProApp.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/2/27.
//

import SwiftUI
import UIKit
import RevenueCat

@main
struct TempoProApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    // 注入PersistenceController
    let persistenceController = PersistenceController.shared
    
    // 添加 CoreDataPlaylistManager 替代原来的 PlaylistManager
    @StateObject private var coreDataPlaylistManager: CoreDataPlaylistManager
    
    // 在TempoProApp结构体中添加
    @StateObject private var practiceManager: CoreDataPracticeManager
    
    // 引用订阅管理器
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // 应用生命周期事件观察
    @Environment(\.scenePhase) private var scenePhase
    
    
    
    init() {
        // 应用启动时就禁用屏幕熄屏
        UIApplication.shared.isIdleTimerDisabled = true
        
        
        // 初始化 Playlist 的 manager
        let manager = CoreDataPlaylistManager(context: PersistenceController.shared.viewContext)
        self._coreDataPlaylistManager = StateObject(wrappedValue: manager)
        manager.createSampleDataIfNeeded()
        
        // 初始化CoreDataPracticeManager
        let practiceManager = CoreDataPracticeManager(context: PersistenceController.shared.viewContext)
        self._practiceManager = StateObject(wrappedValue: practiceManager)
        // practiceManager.generateRandomHistoricalData()

        hideNavigationBarBottomBorder()
    }
    
    

    func hideNavigationBarBottomBorder() {
        let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.shadowColor = .clear // 移除底部线条阴影
            // 或者完全设置为透明背景
            // appearance.configureWithTransparentBackground()
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(coreDataPlaylistManager) // 使用CoreDataPlaylistManager
                .environmentObject(practiceManager) // 添加PracticeManager
                .environmentObject(subscriptionManager) // 将订阅管理器作为环境对象提供给所有视图
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
