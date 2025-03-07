//
//  EditSongView.swift
//  TempoPro
//
//  Created by Meters on 6/3/2025.
//
import SwiftUI

struct EditSongView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager
    @Binding var isPresented: Bool
    @Binding var songName: String
    @Binding var tempo: Int
    @Binding var beatsPerBar: Int
    @Binding var beatUnit: Int
    @Binding var beatStatuses: [BeatStatus]
    var isEditMode: Bool = false
    
    var onSave: (String, Int, Int, Int, [BeatStatus]) -> Void
    
    let beatUnits = [2, 4, 8, 16]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 使用与PracticeStatsView相同的背景
                theme.primaryColor.ignoresSafeArea()
                // 添加噪声背景
                Image("bg-noise")
                    .resizable(resizingMode: .tile)
                    .opacity(0.06)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // 歌曲名称
                        VStack(alignment: .leading, spacing: 12) {
                            Text("歌曲名称")
                                .font(.custom("MiSansLatin-Semibold", size: 18))
                                .foregroundColor(theme.backgroundColor)
                                .padding(.leading, 4)
                            
                            TextField("输入歌曲名称", text: $songName)
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .padding()
                                .background(theme.backgroundColor)
                                .cornerRadius(12)
                                .foregroundColor(theme.beatBarColor)
                        }
                        
                        // BPM设置
                        VStack(alignment: .leading, spacing: 12) {
                            Text("节拍速度 (BPM)")
                                .font(.custom("MiSansLatin-Semibold", size: 18))
                                .foregroundColor(theme.backgroundColor)
                                .padding(.leading, 4)
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Button(action: {
                                        if tempo > 30 {
                                            tempo -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.custom("MiSansLatin-Regular", size: 24))
                                            .foregroundColor(theme.backgroundColor)
                                    }
                                    
                                    Slider(value: Binding(
                                        get: { Double(tempo) },
                                        set: { tempo = Int($0) }
                                    ), in: 30...240, step: 1)
                                    .accentColor(theme.backgroundColor)
                                    
                                    Button(action: {
                                        if tempo < 240 {
                                            tempo += 1
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.custom("MiSansLatin-Regular", size: 24))
                                            .foregroundColor(theme.backgroundColor)
                                    }
                                }
                                
                                Text("\(tempo) BPM")
                                    .font(.custom("MiSansLatin-Semibold", size: 20))
                                    .foregroundColor(theme.beatBarColor)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(theme.backgroundColor)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // 拍号设置
                        VStack(alignment: .leading, spacing: 12) {
                            Text("拍号设置")
                                .font(.custom("MiSansLatin-Semibold", size: 18))
                                .foregroundColor(theme.backgroundColor)
                                .padding(.leading, 4)
                            
                            HStack(spacing: 20) {
                                // 拍子数
                                VStack(alignment: .center, spacing: 8) {
                                    Text("节拍数")
                                        .font(.custom("MiSansLatin-Regular", size: 14))
                                        .foregroundColor(theme.backgroundColor)
                                    
                                    HStack {
                                        Button(action: {
                                            if beatsPerBar > 1 {
                                                beatsPerBar -= 1
                                                updateBeatStatuses(count: beatsPerBar)
                                            }
                                        }) {
                                            Image(systemName: "minus.circle")
                                                .font(.custom("MiSansLatin-Regular", size: 20))
                                                .foregroundColor(theme.backgroundColor)
                                        }
                                        
                                        Text("\(beatsPerBar)")
                                            .font(.custom("MiSansLatin-Semibold", size: 24))
                                            .foregroundColor(theme.backgroundColor)
                                            .frame(width: 40, alignment: .center)
                                        
                                        Button(action: {
                                            if beatsPerBar < 12 {
                                                beatsPerBar += 1
                                                updateBeatStatuses(count: beatsPerBar)
                                            }
                                        }) {
                                            Image(systemName: "plus.circle")
                                                .font(.custom("MiSansLatin-Regular", size: 20))
                                                .foregroundColor(theme.backgroundColor)
                                        }
                                    }
                                }
                                
                                Divider()
                                    .frame(height: 40)
                                    .background(theme.backgroundColor)
                                
                                // 音符单位
                                VStack(alignment: .center, spacing: 8) {
                                    Text("音符单位")
                                        .font(.custom("MiSansLatin-Regular", size: 14))
                                        .foregroundColor(theme.backgroundColor)
                                    
                                    HStack(spacing: 8) {
                                        ForEach(beatUnits, id: \.self) { unit in
                                            Button(action: {
                                                beatUnit = unit
                                            }) {
                                                Text("\(unit)")
                                                    .font(.custom("MiSansLatin-Semibold", size: 20))
                                                    .foregroundColor(unit == beatUnit ? theme.beatBarColor : theme.backgroundColor)
                                                    .frame(width: 40, height: 40)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(unit == beatUnit ? theme.backgroundColor : theme.primaryColor.opacity(0.3))
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(theme.primaryColor.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        // 节拍强弱设置
                        VStack(alignment: .leading, spacing: 12) {
                            Text("节拍强弱设置")
                                .font(.custom("MiSansLatin-Semibold", size: 18))
                                .foregroundColor(theme.backgroundColor)
                                .padding(.leading, 4)
                            
                            VStack(spacing: 16) {
                                HStack(spacing: 8) {
                                    ForEach(0..<beatsPerBar, id: \.self) { index in
                                        Button(action: {
                                            var newStatuses = beatStatuses
                                            newStatuses[index] = newStatuses[index].next()
                                            beatStatuses = newStatuses
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(getBeatStatusColor(beatStatuses[index]))
                                                    .frame(width: 40, height: 40)
                                                
                                                Text("\(index + 1)")
                                                    .font(.custom("MiSansLatin-Bold", size: 16))
                                                    .foregroundColor(theme.backgroundColor)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(theme.backgroundColor)
                                .cornerRadius(12)
                                
                                // 强弱图例
                                HStack(spacing: 16) {
                                    ForEach([BeatStatus.strong, BeatStatus.medium, BeatStatus.normal, BeatStatus.muted], id: \.self) { status in
                                        HStack(spacing: 5) {
                                            Circle()
                                                .fill(getBeatStatusColor(status))
                                                .frame(width: 12, height: 12)
                                            
                                            Text(getBeatStatusName(status))
                                                .font(.custom("MiSansLatin-Regular", size: 12))
                                                .foregroundColor(theme.backgroundColor)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 保存按钮
                        Button(action: {
                            if !songName.isEmpty {
                                onSave(songName, tempo, beatsPerBar, beatUnit, beatStatuses)
                                isPresented = false
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle")
                                    .font(.custom("MiSansLatin-Regular", size: 16))
                                    .foregroundColor(theme.backgroundColor)
                                
                                Text(isEditMode ? "保存修改" : "添加歌曲")
                                    .font(.custom("MiSansLatin-Semibold", size: 16))
                                    .foregroundColor(theme.backgroundColor)
                            }
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(songName.isEmpty ? theme.beatBarColor.opacity(0.3) : theme.beatBarColor)
                            .cornerRadius(12)
                        }
                        .disabled(songName.isEmpty)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitle(isEditMode ? "编辑歌曲" : "添加歌曲", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.custom("MiSansLatin-Regular", size: 20))
                            .foregroundColor(theme.backgroundColor)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(isEditMode ? "编辑歌曲" : "添加歌曲")
                        .font(.custom("MiSansLatin-Semibold", size: 20))
                        .foregroundColor(theme.backgroundColor)
                }
            }
        }
    }
    
    private func updateBeatStatuses(count: Int) {
        var newStatuses = Array(repeating: BeatStatus.normal, count: count)
        
        for i in 0..<min(count, beatStatuses.count) {
            newStatuses[i] = beatStatuses[i]
        }
        
        if count > 0 && count > beatStatuses.count {
            newStatuses[0] = .strong
        }
        
        beatStatuses = newStatuses
    }
    
    private func getBeatStatusColor(_ status: BeatStatus) -> Color {
        switch status {
        case .strong:
            return .red
        case .medium:
            return .orange
        case .normal:
            return theme.beatBarColor
        case .muted:
            return .gray
        }
    }
    
    private func getBeatStatusName(_ status: BeatStatus) -> String {
        switch status {
        case .strong:
            return "强拍"
        case .medium:
            return "次强拍"
        case .normal:
            return "弱拍"
        case .muted:
            return "静音"
        }
    }
}
