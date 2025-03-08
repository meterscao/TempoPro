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
    
    // 添加音频引擎实例
    private let audioEngine = MetronomeAudioEngine()
    
    var body: some View {
        List {
            ForEach(soundOptions, id: \.key) { soundSet in
                Button(action: {
                    selectedSoundKey = soundSet.key
                }) {
                    HStack {
                        Text(soundSet.displayName)
                        Spacer()
                        if selectedSoundKey == soundSet.key {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                        Button(action: {
                            // 播放音效预览
                            audioEngine.previewSoundSet(soundSet)
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
        .onAppear {
            // 确保音频引擎已初始化
            audioEngine.initialize()
            // 预加载所有音效
            audioEngine.preloadAllSoundSets(soundSets: soundOptions)
        }
    }
}
