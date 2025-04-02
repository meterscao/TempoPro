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
    @StateObject private var metronomeState: MetronomeState
    
    
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

    // 添加练习协调器
    @StateObject private var practiceCoordinator: PracticeCoordinator

    // 添加MyConnector
    private var myConnector = MyConnector()

    
    init() {
        // 应用启动时就禁用屏幕熄屏
        UIApplication.shared.isIdleTimerDisabled = true
        
        // 创建 metronomeState 实例
        let metronomeStateInstance = MetronomeState()
        self._metronomeState = StateObject(wrappedValue: metronomeStateInstance)
        
        // 初始化 Playlist 的 manager
        let manager = CoreDataPlaylistManager(context: PersistenceController.shared.viewContext)
        self._coreDataPlaylistManager = StateObject(wrappedValue: manager)
        manager.createSampleDataIfNeeded()
        
        // 初始化CoreDataPracticeManager
        let practiceManager = CoreDataPracticeManager(context: PersistenceController.shared.viewContext)
        self._practiceManager = StateObject(wrappedValue: practiceManager)
        practiceManager.generateRandomHistoricalData()
        
        // 初始化PracticeCoordinator - 使用刚创建的 metronomeState 实例
        let coordinator = PracticeCoordinator(metronomeState: metronomeStateInstance)
        self._practiceCoordinator = StateObject(wrappedValue: coordinator)
    }
    
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(coreDataPlaylistManager) // 使用CoreDataPlaylistManager
                .environmentObject(practiceManager) // 添加PracticeManager
                .environmentObject(practiceCoordinator) // 添加PracticeCoordinator
                .environmentObject(subscriptionManager) // 将订阅管理器作为环境对象提供给所有视图
                .environmentObject(metronomeState) // 添加 MetronomeState
                .environment(\.metronomeTheme, themeManager.currentTheme)
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(myConnector.metronomeViewModel)
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
