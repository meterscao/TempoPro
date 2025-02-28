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
        NavigationView {
            List {
                ForEach(themeManager.availableThemes, id: \.self) { themeName in
                    Button(action: {
                        themeManager.switchTheme(to: themeName)
                    }) {
                        HStack {
                            Text(themeName.capitalized)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if themeName == themeManager.currentThemeName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择主题")
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
        }
    }
}
