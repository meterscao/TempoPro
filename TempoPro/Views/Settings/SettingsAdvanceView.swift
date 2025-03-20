//
//  SettingsAdvanceView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/15.
//

import SwiftUI

struct SettingsAdvanceView: View {

    @AppStorage(AppStorageKeys.Settings.operationSoundEnabled) private var operationSoundEnabled = true
    @AppStorage(AppStorageKeys.Settings.flashlightEnabled) private var flashlightEnabled = false
    @AppStorage(AppStorageKeys.Settings.screenFlashEnabled) private var screenFlashEnabled = true
    @AppStorage(AppStorageKeys.Settings.rhythmVibrationEnabled) private var rhythmVibrationEnabled = true
    @AppStorage(AppStorageKeys.Settings.operationVibrationEnabled) private var operationVibrationEnabled = false
    @AppStorage(AppStorageKeys.Settings.selectedLanguage) private var selectedLanguage = 0
    @AppStorage(AppStorageKeys.Settings.wheelScaleEnabled) private var wheelScaleEnabled = false

    // 添加环境变量用于关闭模态视图
    @Environment(\.dismiss) private var dismiss

    @Environment(\.metronomeTheme) var theme
    
    // 语言选项
    let languages = ["简体中文", "English", "日本語", "Español", "Français"]
    @State private var displaySubscriptionView = false


    var body: some View {
        List {

                
                
                // 音效设置
                Section(header: Text("音效").foregroundColor(Color("textSecondaryColor"))) {
                    
                    Toggle("节拍闪光灯", isOn: $flashlightEnabled)
                        
                    Toggle("节拍屏幕闪光", isOn: $screenFlashEnabled)
                        
                    Toggle("节拍震动", isOn: $rhythmVibrationEnabled)
                        
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                // 视觉设置
                Section(header: Text("反馈").foregroundColor(Color("textSecondaryColor"))) {
                    Toggle("操作音效", isOn: $operationSoundEnabled)
                        
                    Toggle("操作震动", isOn: $operationVibrationEnabled)
                        
                    Toggle("滚轮刻度", isOn: $wheelScaleEnabled)
                        
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                // 其他设置
                Section(header: Text("其他").foregroundColor(Color("textSecondaryColor"))) {
                    NavigationLink(destination: LanguageSettingsView(selectedLanguage: $selectedLanguage, languages: languages)) {
                        HStack {
                            Text("语言设置")
                                .foregroundColor(Color("textPrimaryColor"))
                            Spacer()
                            Text(languages[selectedLanguage])
                                .foregroundColor(Color("textSecondaryColor"))
                        }
                    }
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
            }
            .foregroundColor(Color("textPrimaryColor"))
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar) 
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .listStyle(InsetGroupedListStyle())
            .background(Color("backgroundPrimaryColor"))
            .scrollContentBackground(.hidden)
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
    SettingsAdvanceView()
}
