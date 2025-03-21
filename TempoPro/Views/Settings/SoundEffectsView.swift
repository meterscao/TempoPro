//
//  SoundEffectsView.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/8.
//
import SwiftUI

// 音效设置视图
struct SoundEffectsView: View {
    
    // 使用共享实例而不是创建新实例
    @ObservedObject private var audioEngine = MetronomeAudioEngine.shared
    
    // 添加对 MetronomeState 的引用
    @EnvironmentObject var metronomeState: MetronomeState
    
    // 使用 SoundSetManager.availableSoundSets 获取所有可用的音效
    let soundOptions = SoundSetManager.availableSoundSets
    
    // 初始状态使用 MetronomeState 中当前的音效设置
    @State private var selectedSoundKey: String = ""
    // 环境变量
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    init(){
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }

    
    var body: some View {
        List {
            
            Section(){
                ForEach(soundOptions, id: \.key) { soundSet in
                    Button(action: {
                        // 更新选中的音效键
                        selectedSoundKey = soundSet.key
                        
                        // 更新 MetronomeState 中的音效设置
                        metronomeState.updateSoundSet(soundSet)
                    }) {
                        HStack {
                            if selectedSoundKey == soundSet.key {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("textPrimaryColor"))
                            }
                            
                            Text(soundSet.displayName)
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .foregroundColor(Color("textPrimaryColor"))
                            Spacer()
                            
                            Button(action: {
                                // 播放音效预览
                                audioEngine.previewSoundSet(soundSet)
                            }) {
                                Image(systemName: "play.circle")
                                    .foregroundColor(Color("textPrimaryColor"))
                            }
                        }
                    }
                    .foregroundColor(Color("textPrimaryColor"))
                }
            }
            .listRowBackground(Color("backgroundSecondaryColor"))
        }
        
        .background(theme.backgroundColor)
        .scrollContentBackground(.hidden)
        .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
        .onAppear {
            // 确保音频引擎已初始化
            audioEngine.initialize()
            
            // 确保选中的音效与 MetronomeState 中一致
            selectedSoundKey = metronomeState.soundSet.key
            
            // 预加载所有音效
            audioEngine.preloadAllSoundSets(soundSets: soundOptions)
        }
        .onDisappear {
            // 在视图消失时清理资源
            audioEngine.cleanupBeforeDestroy()
        }
    }
}
