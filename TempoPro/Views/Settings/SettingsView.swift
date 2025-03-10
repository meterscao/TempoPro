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
    // 状态变量
    @State private var selectedTheme = 0
    @State private var soundEffectsEnabled = true
    @State private var operationSoundEnabled = true
    @State private var flashlightEnabled = false
    @State private var screenFlashEnabled = true
    @State private var rhythmVibrationEnabled = true
    @State private var operationVibrationEnabled = false
    @State private var selectedLanguage = 0
    
    
    // 添加环境变量用于关闭模态视图
    @Environment(\.dismiss) private var dismiss
    
    // 主题选项
    let themes = ["默认", "暗黑", "明亮", "蓝色", "绿色"]
    // 语言选项
    let languages = ["简体中文", "English", "日本語", "Español", "Français"]
    
    var body: some View {
        NavigationView {
            
            
            List {
                // 主题设置
                Section(header: Text("主题")) {
                    ThemeSelectionView()
                }
                
                // 音效设置
                Section(header: Text("音效")) {
                    NavigationLink(destination: SoundEffectsView()) {
                        Text("节奏音效")
                    }
                    Toggle("节拍闪光灯", isOn: $flashlightEnabled)
                    Toggle("节拍屏幕闪光", isOn: $screenFlashEnabled)
                    Toggle("节奏震动", isOn: $rhythmVibrationEnabled)
                }
                
                // 视觉设置
                Section(header: Text("反馈")) {
                    Toggle("操作音效", isOn: $operationSoundEnabled)
                    Toggle("操作震动", isOn: $operationVibrationEnabled)
                }
                
                // 其他设置
                Section(header: Text("其他")) {
                    NavigationLink(destination: LanguageSettingsView(selectedLanguage: $selectedLanguage, languages: languages)) {
                        HStack {
                            Text("语言设置")
                            Spacer()
                            Text(languages[selectedLanguage])
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                    }
                }
            }
        }
    }
}





// 语言设置视图
struct LanguageSettingsView: View {
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
                        Spacer()
                        if selectedLanguage == index {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("语言设置")
    }
}

#Preview {
    SettingsView()
}
