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
            .padding(14)
            .foregroundStyle(theme.primaryColor)
            .frame(width: 60, height: 60)
            .background(RoundedRectangle(cornerRadius: 18).fill(theme.backgroundColor))
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

// 统计视图
struct StatsView: View {
    @Environment(\.metronomeTheme) var theme
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("练习统计")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textColor)
                        .padding(.top, 20)
                    
                    // 这里添加统计内容
                    VStack(spacing: 16) {
                        StatCard(title: "本周练习", value: "5小时32分钟", icon: "clock.fill")
                        StatCard(title: "最常练习的曲目", value: "卡农", icon: "music.note")
                        StatCard(title: "最常用的速度", value: "120 BPM", icon: "metronome")
                        StatCard(title: "练习天数", value: "连续12天", icon: "calendar")
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarItems(trailing: Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.textColor.opacity(0.7))
            })
        }
    }
}

// 统计卡片组件
struct StatCard: View {
    @Environment(\.metronomeTheme) var theme
    var title: String
    var value: String
    var icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(theme.primaryColor)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(theme.primaryColor.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(theme.textColor.opacity(0.7))
                
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textColor)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    MetronomeToolbarView()
        
} 
