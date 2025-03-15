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
import RevenueCat

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
    @State private var displaySubscriptionView = false
    
    var body: some View {
        NavigationView {
            List {

                Button(action: {
                    displaySubscriptionView = true
                }) {
                    Text("订阅")
                        .foregroundColor(theme.primaryColor)
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))

                
                // 主题设置
                Section(header: Text("主题").foregroundColor(theme.primaryColor)) {
                    ThemeSelectionView()
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))

                Section(header: Text("iCloud").foregroundColor(theme.primaryColor)) {
                    Toggle("同步曲库与练习记录", isOn: $icloudSyncEnabled)
                        .foregroundColor(theme.primaryColor)
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))
                
                // 音效设置
                Section(header: Text("音效").foregroundColor(theme.primaryColor)) {
                    NavigationLink(destination: SoundEffectsView()) {
                        Text("节奏音效")
                            .foregroundColor(theme.primaryColor)
                    }
                    
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))
                
                
                
                // 其他设置
                Section(header: Text("其他").foregroundColor(theme.primaryColor)) {
                    NavigationLink(destination: SettingsAdvanceView()) {
                        HStack {
                            Text("高级设置")
                                .foregroundColor(theme.primaryColor)
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
                        Image("icon-x")
                            .renderingMode(.template)
                            .foregroundColor(theme.primaryColor)
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .contentShape(Rectangle())
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

        .sheet(isPresented: self.$displaySubscriptionView) {
                SubscriptionView()
            }
    }
}



#Preview {
    SettingsView()
}
