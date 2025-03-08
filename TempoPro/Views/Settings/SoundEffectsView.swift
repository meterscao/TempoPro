//
//  SoundEffectsView.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/8.
//
import SwiftUI

// 音效设置视图
struct SoundEffectsView: View {
    @Binding var soundEffectsEnabled: Bool
    @Binding var operationSoundEnabled: Bool
    
    // 使用 SoundSetManager.availableSoundSets 获取所有可用的音效
    let soundOptions = SoundSetManager.availableSoundSets
    @State private var selectedSoundKey = SoundSetManager.getDefaultSoundSet().key
    
    var body: some View {
        List {
           ForEach(soundOptions, id: \.key) { soundSet in
                Button(action: {
                    selectedSoundKey = soundSet.key
                    // 这里可以添加试听音效的逻辑
                }) {
                    HStack {
                        Text(soundSet.displayName)
                        Spacer()
                        if selectedSoundKey == soundSet.key {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                        Button(action: {
                            // 试听音效
                        }) {
                            Image(systemName: "play.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("节奏音效")
    }
}
