//
//  ThemeSelectionView.swift
//  TempoPro
//
//  Created by Meters on 28/2/2025.
//

import SwiftUI

struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(themeManager.availableThemes, id: \.self) { themeName in
                        Button(action: {
                            themeManager.switchTheme(to: themeName)
                        }) {
                            ZStack(alignment:.top) {
                                Image("icon-app-primary")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundStyle(themeManager.themeSets(for: themeName).primaryColor)
                                    .frame(maxWidth: .infinity,maxHeight: .infinity)
                                
                                Image("icon-app-black")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundStyle(themeManager.themeSets(for: themeName).backgroundColor)
                                    .frame(maxWidth: .infinity,maxHeight: .infinity)
                                
                                Image("icon-app-beat-default")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundStyle(themeManager.themeSets(for: themeName).beatBarColor)
                                    .frame(maxWidth: .infinity,maxHeight: .infinity)
                                
                                Image("icon-app-beat-mute")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundStyle(themeManager.themeSets(for: themeName).beatBarColor.opacity(0.4))
                                    .frame(maxWidth: .infinity,maxHeight: .infinity)    
                                    
                                
                                if themeName == themeManager.currentThemeName {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 64, height: 64)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
    }
}

#Preview {
    ThemeSelectionView()
        .environmentObject(ThemeManager()) // 添加 ThemeManager 环境对象
}
