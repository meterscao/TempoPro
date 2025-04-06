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
    @ObservedObject private var audioEngine = MetronomeAudioService.shared

    @EnvironmentObject var metronomeViewModel: MyViewModel
    
    // 使用 SoundSetManager.availableSoundSets 获取所有可用的音效
    let soundOptions = SoundSetManager.availableSoundSets
    
    @State private var selectedSoundKey: String = ""


    // 环境变量
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    init(){
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }

    
    var body: some View {
        
        VStack(){
            ListView {
                
                SectionView{
                    ForEach(soundOptions, id: \.key) { soundSet in
                        Button(action: {
                            // 更新选中的音效键
                            selectedSoundKey = soundSet.key
                            audioEngine.previewSoundSet(soundSet)
                            
                        }) {
                            HStack {
                                
                                Text(soundSet.displayName)
                                    .font(.custom("MiSansLatin-Regular", size: 16))
                                    .foregroundColor(Color("textPrimaryColor"))
                                Spacer()
                                
                                if selectedSoundKey == soundSet.key {
                                    Image("icon-check-s")
                                    .renderingMode(.template)
                                    .foregroundColor(Color("textPrimaryColor"))
                                    
                                }
                                
                                
                            }
                        }
                        .foregroundColor(Color("textPrimaryColor"))
                    }
                }
                
            }
            
            VStack(spacing: 0){
                Button(action: {
                    // 更新 MetronomeState 中的音效设置
                    // metronomeViewModel.updateSoundSet(soundSet)
                }) {
                    HStack(){
                        Text("确定")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                        PremiumLabelView()
                        
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(Color("textPrimaryColor"))
                    .background(Color("backgroundSecondaryColor"))
                    .cornerRadius(12)
                }
                
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
        .background(Color("backgroundPrimaryColor"))
        .scrollContentBackground(.hidden)
        .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
        .navigationTitle("Sound Effect")
        .onAppear {
            // 确保音频引擎已初始化
            audioEngine.initialize()
            
            // 确保选中的音效与 viewmodel 中一致
            selectedSoundKey = metronomeViewModel.soundSet.key
            
            // 预加载所有音效
            audioEngine.preloadAllSoundSets(soundSets: soundOptions)
        }
        .onDisappear {
            // 在视图消失时清理资源
            audioEngine.cleanupBeforeDestroy()
        }
    }
}


