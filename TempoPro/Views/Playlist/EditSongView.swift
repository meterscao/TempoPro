//
//  EditSongView.swift
//  TempoPro
//
//  Created by Meters on 6/3/2025.
//
import SwiftUI

struct EditSongView: View {
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
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
        NavigationStack {
            List {
                // 曲目名称部分
                Section {
                    TextField("输入曲目名称", text: $songName)
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                        .padding(.vertical, 8)
                } header: {
                    Text("曲目名称")
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textSecondaryColor"))
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                // BPM设置部分
                Section {
                    VStack(spacing: 12) {
                        HStack {
                            Button(action: {
                                if tempo > 30 {
                                    tempo -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color("textSecondaryColor"))
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
                                    .foregroundColor(Color("textSecondaryColor"))
                            }
                        }
                        
                        Text("\(tempo) BPM")
                            .font(.custom("MiSansLatin-Semibold", size: 18))
                            .foregroundColor(Color("textPrimaryColor"))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("节拍速度 (BPM)")
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textSecondaryColor"))
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                // 拍号设置部分
                Section {
                    VStack(spacing: 16) {
                        // 拍子数
                        HStack {
                            Text("节拍数")
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .foregroundColor(Color("textPrimaryColor"))
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    if beatsPerBar > 1 {
                                        beatsPerBar -= 1
                                        updateBeatStatuses(count: beatsPerBar)
                                    }
                                }) {
                                    Image(systemName: "minus.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color("textSecondaryColor"))
                                }
                                
                                Text("\(beatsPerBar)")
                                    .font(.custom("MiSansLatin-Semibold", size: 20))
                                    .foregroundColor(Color("textPrimaryColor"))
                                    .frame(width: 30, alignment: .center)
                                
                                Button(action: {
                                    if beatsPerBar < 12 {
                                        beatsPerBar += 1
                                        updateBeatStatuses(count: beatsPerBar)
                                    }
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color("textSecondaryColor"))
                                }
                            }
                        }
                        
                        Divider()
                        
                        // 音符单位
                        HStack {
                            Text("音符单位")
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .foregroundColor(Color("textPrimaryColor"))
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                ForEach(beatUnits, id: \.self) { unit in
                                    Button(action: {
                                        beatUnit = unit
                                    }) {
                                        Text("\(unit)")
                                            .font(.custom("MiSansLatin-Semibold", size: 18))
                                            .foregroundColor(unit == beatUnit ? Color.white : Color("textSecondaryColor"))
                                            .frame(width: 40, height: 36)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(unit == beatUnit ? theme.primaryColor : Color("backgroundPrimaryColor"))
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("拍号设置")
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textSecondaryColor"))
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                // 节拍强弱设置部分
                Section {
                    VStack(spacing: 16) {
                        // 节拍按钮
                        HStack(spacing: 10) {
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
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            
                            if beatsPerBar < 6 {
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                        
                        // 图例
                        HStack(spacing: 12) {
                            ForEach([BeatStatus.strong, BeatStatus.medium, BeatStatus.normal, BeatStatus.muted], id: \.self) { status in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(getBeatStatusColor(status))
                                        .frame(width: 10, height: 10)
                                    
                                    Text(getBeatStatusName(status))
                                        .font(.custom("MiSansLatin-Regular", size: 14))
                                        .foregroundColor(Color("textSecondaryColor"))
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("节拍强弱设置")
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textSecondaryColor"))
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
            }
            .background(Color("backgroundPrimaryColor"))
            .scrollContentBackground(.hidden)
            .navigationTitle(isEditMode ? "编辑曲目" : "添加曲目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon-x")
                            .renderingMode(.template)
                            .foregroundColor(Color("textSecondaryColor"))
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .contentShape(Rectangle())
                }
                
                ToolbarItem(placement: .principal) {
                    Text(isEditMode ? "编辑曲目" : "添加曲目")
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if !songName.isEmpty {
                            onSave(songName, tempo, beatsPerBar, beatUnit, beatStatuses)
                            isPresented = false
                        }
                    }) {
                        Text(isEditMode ? "保存" : "添加")
                            .font(.custom("MiSansLatin-Semibold", size: 16))
                            .foregroundColor(songName.isEmpty ? Color("textSecondaryColor").opacity(0.5) : theme.primaryColor)
                    }
                    .disabled(songName.isEmpty)
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
            return theme.primaryColor
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
