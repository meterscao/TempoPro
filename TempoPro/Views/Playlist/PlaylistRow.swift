//
//  PlaylistRow.swift
//  TempoPro
//
//  Created by Meters on 6/3/2025.
//

import SwiftUI
struct PlaylistRow: View {
    @Environment(\.metronomeTheme) var theme
    let playlist: Playlist
    
    var body: some View {
        HStack(spacing: 16) {
            // 歌单颜色标识
            RoundedRectangle(cornerRadius: 10)
                .fill(playlist.getColor())  // 使用扩展方法
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "music.note.list")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )
                .shadow(color: Color(hex: playlist.color ?? "#0000FF")?.opacity(0.3) ?? .blue.opacity(0.3), radius: 5, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name ?? "未命名歌单")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textColor)
                
                let songCount = playlist.songs?.count ?? 0
                Text("\(songCount) 首歌曲")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textColor.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(theme.primaryColor.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}
