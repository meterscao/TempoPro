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
        GridItem(.adaptive(minimum: 48, maximum: 48), spacing: 10)
    ]
    
    var body: some View {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(themeManager.availableThemes, id: \.self) { themeName in
                    Button(action: {
                        themeManager.switchTheme(to: themeName)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themeManager.themeColor(for: themeName))
                                .frame(width: 48, height: 48)
                            if themeName == themeManager.currentThemeName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }
            .frame(alignment: .leading)
            .padding()
        
    }
}

