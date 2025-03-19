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
    
    
    // 获取订阅管理器
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    // 语言选项
    let languages = ["简体中文", "English", "日本語", "Español", "Français"]
    @State private var displaySubscriptionView = false
    
    
    var body: some View {
        NavigationView {
            List {
                
                Button(action: {
                    displaySubscriptionView = true
                }) {
                    Text(subscriptionManager.isProUser ? "已订阅" : "订阅")
                        
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                
                // 主题设置
                Section(header: Text("主题")) {
                    ThemeSelectionView()
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                
                .listRowBackground(Color("backgroundSecondaryColor"))

                Section(header: Text("iCloud")) {
                    Toggle("同步曲库与练习记录", isOn: $icloudSyncEnabled)
                        
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                // 音效设置
                Section(header: Text("音效")) {
                    NavigationLink(destination: SoundEffectsView()) {
                        Text("节奏音效")
                            
                    }
                    
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                
                
                // 其他设置
                Section(header: Text("其他")) {
                    NavigationLink(destination: SettingsAdvanceView()) {
                        HStack {
                            Text("高级设置")
                                
                        }
                    }
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
            }
            .foregroundColor(Color("textPrimaryColor"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon-x")
                            .renderingMode(.template)
                            
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .contentShape(Rectangle())
                }
            }
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar) 
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .listStyle(InsetGroupedListStyle())
            .background(Color("backgroundPrimaryColor"))
            .scrollContentBackground(.hidden)
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(Color("textPrimaryColor"))
        .preferredColorScheme(.dark)

        .sheet(isPresented: self.$displaySubscriptionView) {
            SubscriptionView()
        }
        
       
    }
}



#Preview {
    SettingsView()
}
