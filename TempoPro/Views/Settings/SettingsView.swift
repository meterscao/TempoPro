//
//  SettingsView.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/8.
//


//
//  SettingsView.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/8.
//

import SwiftUI

struct SettingsView: View {
    // 使用 AppStorage 替换状态变量
    @AppStorage(AppStorageKeys.Settings.operationSoundEnabled) private var operationSoundEnabled = true
    @AppStorage(AppStorageKeys.Settings.flashlightEnabled) private var flashlightEnabled = false
    @AppStorage(AppStorageKeys.Settings.screenFlashEnabled) private var screenFlashEnabled = true
    @AppStorage(AppStorageKeys.Settings.rhythmVibrationEnabled) private var rhythmVibrationEnabled = true
    @AppStorage(AppStorageKeys.Settings.operationVibrationEnabled) private var operationVibrationEnabled = false
    @AppStorage(AppStorageKeys.Settings.selectedLanguage) private var selectedLanguage = 0
    @AppStorage(AppStorageKeys.Settings.icloudSyncEnabled) private var icloudSyncEnabled = false
    @AppStorage(AppStorageKeys.Settings.wheelScaleEnabled) private var wheelScaleEnabled = false
    
    // 添加环境变量用于关闭模态视图
    @Environment(\.dismiss) private var dismiss

    @Environment(\.metronomeTheme) var theme
    
    // 语言选项
    let languages = ["简体中文", "English", "日本語", "Español", "Français"]
    
    var body: some View {
        NavigationView {
            List {
                // 主题设置
                Section(header: Text("主题").foregroundColor(theme.primaryColor)) {
                    ThemeSelectionView()
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))

                Section(header: Text("iCloud").foregroundColor(theme.primaryColor)) {
                    Toggle("同步歌单与练习记录", isOn: $icloudSyncEnabled)
                        .foregroundColor(theme.primaryColor)
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))
                
                // 音效设置
                Section(header: Text("音效").foregroundColor(theme.primaryColor)) {
                    NavigationLink(destination: SoundEffectsView()) {
                        Text("节奏音效")
                            .foregroundColor(theme.primaryColor)
                    }
                    Toggle("节拍闪光灯", isOn: $flashlightEnabled)
                        .foregroundColor(theme.primaryColor)
                    Toggle("节拍屏幕闪光", isOn: $screenFlashEnabled)
                        .foregroundColor(theme.primaryColor)
                    Toggle("节拍震动", isOn: $rhythmVibrationEnabled)
                        .foregroundColor(theme.primaryColor)
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))
                
                // 视觉设置
                Section(header: Text("反馈").foregroundColor(theme.primaryColor)) {
                    Toggle("操作音效", isOn: $operationSoundEnabled)
                        .foregroundColor(theme.primaryColor)
                    Toggle("操作震动", isOn: $operationVibrationEnabled)
                        .foregroundColor(theme.primaryColor)
                    Toggle("滚轮刻度", isOn: $wheelScaleEnabled)
                        .foregroundColor(theme.primaryColor)
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))
                
                // 其他设置
                Section(header: Text("其他").foregroundColor(theme.primaryColor)) {
                    NavigationLink(destination: LanguageSettingsView(selectedLanguage: $selectedLanguage, languages: languages)) {
                        HStack {
                            Text("语言设置")
                                .foregroundColor(theme.primaryColor)
                            Spacer()
                            Text(languages[selectedLanguage])
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                }
            }
            .toolbarBackground(theme.backgroundColor, for: .navigationBar) 
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .listStyle(InsetGroupedListStyle())
            .background(theme.backgroundColor)
            .scrollContentBackground(.hidden)
            .foregroundColor(theme.primaryColor)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(theme.primaryColor)
        .preferredColorScheme(.dark)
    }
}

// 语言设置视图
struct LanguageSettingsView: View {
    @Environment(\.metronomeTheme) var theme
    @Binding var selectedLanguage: Int
    
    let languages: [String]
    
    var body: some View {
        List {
            ForEach(0..<languages.count, id: \.self) { index in
                Button(action: {
                    selectedLanguage = index
                }) {
                    HStack {
                        Text(languages[index])
                            .foregroundColor(theme.primaryColor)
                        Spacer()
                        if selectedLanguage == index {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(theme.primaryColor)
                .listRowBackground(theme.primaryColor.opacity(0.1))
            }
        }
        .navigationTitle("语言设置")
        .listStyle(InsetGroupedListStyle())
        .background(theme.backgroundColor)
        .scrollContentBackground(.hidden)
        .toolbarBackground(theme.backgroundColor, for: .navigationBar) 
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView()
}
