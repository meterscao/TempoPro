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
    
    // 定义网格布局
    // 创建一个自适应网格布局,每个网格项的最小和最大宽度都是48点,网格项之间的间距是10点
    // 这样可以让网格根据屏幕宽度自动调整每行显示的主题数量
    let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 60), spacing: 10)
    ]
    
    var body: some View {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(themeManager.availableThemes, id: \.self) { themeName in
                    Button(action: {
                        themeManager.switchTheme(to: themeName)
                    }) {
                        ZStack(alignment: .bottomTrailing) {
                            themeManager.themeSets(for: themeName).primaryColor
                            .cornerRadius(8)
                            

                            VStack (alignment: .leading){
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(themeManager.themeSets(for: themeName).beatBarColor)
                                    .frame(width: 20, height: 20)
                                
                            }
                            .background(themeManager.themeSets(for: themeName).backgroundColor  )
                            .cornerRadius(8)
                            if themeName == themeManager.currentThemeName {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        
                                }
                            }
                            .frame(width: 60, height: 60)
                            
                            
                    }.buttonStyle(.plain)
                }
            }
            .frame(alignment: .leading)
    }
}

