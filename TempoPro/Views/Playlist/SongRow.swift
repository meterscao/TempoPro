//
//  SongRow.swift
//  TempoPro
//
//  Created by Meters on 6/3/2025.
//

import SwiftUI
// 更新 SongRow 以使用 CoreData Song 实体
struct SongRow: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var metronomeState: MetronomeState
    let song: Song
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(song.name ?? "未命名歌曲")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textColor)
                
                HStack(spacing: 12) {
                    Label("\(song.bpm) BPM", systemImage: "metronome")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor.opacity(0.7))
                    
                    Text("\(song.beatsPerBar)/\(song.beatUnit)")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor.opacity(0.7))
                }
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            Button(action: {
                applySongSettings(song)
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(theme.primaryColor)
                    .padding(.trailing, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
    
    // 应用歌曲设置到节拍器
    private func applySongSettings(_ song: Song) {
        metronomeState.updateTempo(Int(song.bpm))
        metronomeState.updateBeatsPerBar(Int(song.beatsPerBar))
        metronomeState.updateBeatUnit(Int(song.beatUnit))
        
        // 转换 beatStatuses
        if let statusArray = song.beatStatuses as? [Int] {
            let statuses = statusArray.map { statusInt -> BeatStatus in
                switch statusInt {
                case 0: return .strong
                case 1: return .medium
                case 2: return .normal
                case 3: return .muted
                default: return .normal
                }
            }
            metronomeState.updateBeatStatuses(statuses)
        }
        
        // 如果节拍器还没有启动，则启动它
        if !metronomeState.isPlaying {
            metronomeState.togglePlayback()
        }
    }
}
