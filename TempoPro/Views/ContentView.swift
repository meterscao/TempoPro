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
