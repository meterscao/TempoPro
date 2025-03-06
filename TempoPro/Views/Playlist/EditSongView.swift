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
                theme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 歌曲名称
                        VStack(alignment: .leading, spacing: 8) {
                            Text("歌曲名称")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textColor)
                            
                            TextField("输入歌曲名称", text: $songName)
                                .font(.system(size: 17))
                                .padding()
                                .background(theme.cardBackgroundColor)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                        }
                        
                        // BPM设置
                        VStack(alignment: .leading, spacing: 8) {
                            Text("节拍速度 (BPM)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textColor)
                            
                            HStack {
                                Button(action: {
                                    if tempo > 30 {
                                        tempo -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(theme.primaryColor)
                                }
                                
                                Slider(value: Binding(
                                    get: { Double(tempo) },
                                    set: { tempo = Int($0) }
                                ), in: 30...240, step: 1)
                                .accentColor(theme.primaryColor)
                                
                                Button(action: {
                                    if tempo < 240 {
                                        tempo += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(theme.primaryColor)
                                }
                            }
                            
                            Text("\(tempo) BPM")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(theme.primaryColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        // 拍号设置
                        VStack(alignment: .leading, spacing: 8) {
                            Text("拍号设置")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textColor)
                            
                            HStack(spacing: 20) {
                                // 分子
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("节拍数")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.textColor.opacity(0.7))
                                    
                                    HStack {
                                        Button(action: {
                                            if beatsPerBar > 1 {
                                                beatsPerBar -= 1
                                                updateBeatStatuses(count: beatsPerBar)
                                            }
                                        }) {
                                            Image(systemName: "minus.circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(theme.primaryColor)
                                        }
                                        
                                        Text("\(beatsPerBar)")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(theme.textColor)
                                            .frame(width: 40, alignment: .center)
                                        
                                        Button(action: {
                                            if beatsPerBar < 12 {
                                                beatsPerBar += 1
                                                updateBeatStatuses(count: beatsPerBar)
                                            }
                                        }) {
                                            Image(systemName: "plus.circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(theme.primaryColor)
                                        }
                                    }
                                }
                                
                                Divider()
                                    .frame(height: 40)
                                
                                // 分母
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("音符单位")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.textColor.opacity(0.7))
                                    
                                    HStack {
                                        ForEach(beatUnits, id: \.self) { unit in
                                            Button(action: {
                                                beatUnit = unit
                                            }) {
                                                Text("\(unit)")
                                                    .font(.system(size: 20, weight: unit == beatUnit ? .bold : .regular))
                                                    .foregroundColor(unit == beatUnit ? theme.primaryColor : theme.textColor.opacity(0.7))
                                                    .frame(width: 40, height: 40)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(unit == beatUnit ? theme.primaryColor : theme.textColor.opacity(0.3), lineWidth: unit == beatUnit ? 2 : 1)
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 节拍强弱设置
                        VStack(alignment: .leading, spacing: 10) {
                            Text("节拍强弱设置")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textColor)
                            
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
                                                .shadow(color: getBeatStatusColor(beatStatuses[index]).opacity(0.3), radius: 3, x: 0, y: 2)
                                            
                                            Text("\(index + 1)")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 6)
                            
                            // 强弱图例
                            HStack(spacing: 10) {
                                ForEach([BeatStatus.strong, BeatStatus.medium, BeatStatus.normal, BeatStatus.muted], id: \.self) { status in
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(getBeatStatusColor(status))
                                            .frame(width: 12, height: 12)
                                        
                                        Text(getBeatStatusName(status))
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.textColor.opacity(0.7))
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitle(isEditMode ? "编辑歌曲" : "添加歌曲", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    if !songName.isEmpty {
                        onSave(songName, tempo, beatsPerBar, beatUnit, beatStatuses)
                        isPresented = false
                    }
                }
                .disabled(songName.isEmpty)
            )
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
            return .blue
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
            return "普通拍"
        case .muted:
            return "静音"
        }
    }
}
