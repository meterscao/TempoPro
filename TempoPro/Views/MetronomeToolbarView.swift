//
//  MetronomeToolbarView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI


struct CircularButtonStyle: ViewModifier {
    @Environment(\.metronomeTheme) var theme
    func body(content: Content) -> some View {
        content
            .foregroundStyle(theme.backgroundColor)
            .padding(0)
            .frame(width: 62, height: 62, alignment: .center)
            
            .cornerRadius(100)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(theme.backgroundColor, lineWidth: 2)
                    
                    
            )
            
    }
}

extension View {
    func circularButton() -> some View {
        self.modifier(CircularButtonStyle())
    }
}

struct MetronomeToolbarView: View {
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager
    @State private var showingStatsView = false
    
    var body: some View {
        HStack() {
            Button(action: {}) {
                Image("icon-timer")
                    .renderingMode(.template)
                    .circularButton()
            }
            Spacer()
            Button(action: {
                // 打开歌单列表
                playlistManager.openPlaylistsSheet()
            }) {
                Image("icon-play-list")
                    .renderingMode(.template)
                    .circularButton()
            }
            Spacer()
            Button(action: {}) {
                Image("icon-clap")
                    .renderingMode(.template)
                    .circularButton()
            }
            Spacer()
            Button(action: {
                // 打开统计视图
                showingStatsView = true
            }) {
                Image("icon-analysis")
                    .renderingMode(.template)
                    .circularButton()
            }
        }
        .font(.title2)
        .padding(.horizontal,30)
        .frame(maxWidth: .infinity)
        .fullScreenCover(isPresented: $playlistManager.showPlaylistsSheet) {
            PlaylistListView()
                .environmentObject(playlistManager)
        }
        .fullScreenCover(isPresented: $showingStatsView) {
            PracticeStatsView()
        }
    }
}



#Preview {
    MetronomeToolbarView()
        
} 
