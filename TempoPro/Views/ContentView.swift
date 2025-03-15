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
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager // 类型改为 CoreDataPlaylistManager
    @EnvironmentObject var practiceManager: CoreDataPracticeManager // 添加这一行
    @StateObject private var metronomeState = MetronomeState()
    
    // 在ContentView.swift中添加状态变量
    @State private var showingCompletionView = false
    @State private var completionDuration: TimeInterval = 0
    @State private var completionTempo: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            MetronomeInfoView()
            .frame(maxHeight: .infinity)

            MetronomeControlView()
                .environmentObject(metronomeState)
                .aspectRatio(16/15, contentMode: .fit)
            
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
                    // 连接practiceManager到metronomeState
                    metronomeState.practiceManager = practiceManager
                }
        .onDisappear {
            metronomeState.cleanup()
        }
        // 在ContentView的body中添加
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPracticeCompletion"))) { notification in
            if let duration = notification.userInfo?["duration"] as? TimeInterval,
               let tempo = notification.userInfo?["tempo"] as? Int {
                completionDuration = duration
                completionTempo = tempo
                showingCompletionView = true
            }
        }
        .sheet(isPresented: $showingCompletionView) {
            PracticeCompletionView(duration: completionDuration, tempo: completionTempo)
        }
        .environmentObject(metronomeState)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
