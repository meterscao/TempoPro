//
//  MetronomeToolbarView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct MetronomeToolbarView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager
    @State private var showingStatsView = false
    @State private var showingSetTimerView = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 上边框
            Rectangle()
                .fill(Color.black)
                .frame(height: 2)
            
            // 工具栏内容
            HStack(spacing: 0) {
                // 第一个按钮
                toolbarButton(image: "icon-timer") {
                    showingSetTimerView = true
                }
                
                // 分隔线
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2)
                
                // 第二个按钮
                toolbarButton(image: "icon-play-list") {
                    playlistManager.openPlaylistsSheet()
                }
                
                // 分隔线
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2)
                
                // 第三个按钮
                toolbarButton(image: "icon-clap") {
                    // 拍手动作
                }
                
                // 分隔线
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2)
                
                // 第四个按钮
                toolbarButton(image: "icon-analysis") {
                    showingStatsView = true
                }
            }
            
        }
        .sheet(isPresented: $playlistManager.showPlaylistsSheet) {
            PlaylistListView()
                .environmentObject(playlistManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingStatsView) {
            PracticeStatsView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingSetTimerView) {
            SetTimerView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        .frame(height: 100)
        
        
        
    }
    
    // 工具栏按钮布局
    private func toolbarButton(image: String, action: @escaping () -> Void) -> some View {
            VStack() {
                Image(image)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }
            
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
        
    }
}

#Preview {
    MetronomeToolbarView()
} 
