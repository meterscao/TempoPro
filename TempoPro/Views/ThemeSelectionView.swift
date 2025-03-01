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
    let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(themeManager.availableThemes, id: \.self) { themeName in
                        Button(action: {
                            themeManager.switchTheme(to: themeName)
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(themeManager.themeColor(for: themeName))
                                    .frame(width: 50, height: 50)
                                    .shadow(radius: 2)
                                
                                if themeName == themeManager.currentThemeName {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 1)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("选择主题").navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
        }
    }
}
