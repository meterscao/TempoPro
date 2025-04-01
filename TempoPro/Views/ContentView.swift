//
//  ContentView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var metronomeState: MetronomeState
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager // 类型改为 CoreDataPlaylistManager
    @EnvironmentObject var practiceManager: CoreDataPracticeManager // 添加这一行
    @EnvironmentObject var practiceCoordinator: PracticeCoordinator // 添加练习协调器引用
    
    // 控制器实例，用于传递给环境
    @State private var metronomeController: MetronomeController?
    
    @State private var completionDuration: TimeInterval = 0
    @State private var completionTempo: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            MetronomeInfoView()
            .frame(maxHeight: .infinity)

            MetronomeControlView()
                .aspectRatio(16/16, contentMode: .fit)
            
            MetronomeToolbarView()
                .environmentObject(playlistManager) // 确保传递 CoreDataPlaylistManager
                
        }
        .environment(\.metronomeController, metronomeController) // 将控制器注入到环境中
        .ignoresSafeArea(edges: .all)
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .background(
            Image("bg-noise")
                .resizable(resizingMode: .tile)
                .opacity(0.06)
                .ignoresSafeArea()
        )
        .background(theme.primaryColor.ignoresSafeArea())
        .onAppear {
            // 连接CoreData管理器和练习协调器到metronomeState
            metronomeState.practiceManager = practiceManager
            metronomeState.practiceCoordinator = practiceCoordinator
            
            // 获取Controller并提供给环境
            metronomeController = metronomeState.getController()
        }
        .onDisappear {
            // 清理MetronomeState资源
            metronomeState.cleanup()
        }
        
        .environmentObject(metronomeState)

    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
