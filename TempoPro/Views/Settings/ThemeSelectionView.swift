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
                            VStack(spacing:5){
                                ZStack(alignment:.top) {
                                    themeManager.themeSets(for: themeName).primaryColor
                                    
                                    Image("ui-preview-elements")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        
                                        .foregroundStyle(themeManager.themeSets(for: themeName).backgroundColor)
                                        .frame(maxWidth: .infinity,maxHeight: .infinity)
                                    
                                    Image("ui-preview-numbers")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        
                                        .foregroundStyle(themeManager.themeSets(for: themeName).primaryColor)
                                        .frame(maxWidth: .infinity,maxHeight: .infinity)
                                    
                                    Image("ui-preview-bars")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        
                                        .foregroundStyle(themeManager.themeSets(for: themeName).beatBarColor)
                                        .frame(maxWidth: .infinity,maxHeight: .infinity)
                                }
                                .frame(height: 180)
                                .cornerRadius(12)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.themeSets(for: themeName).backgroundColor.opacity(0.5), lineWidth: 1)
                                        
                                }
                                
                                Circle().fill(themeName == themeManager.currentThemeName ? .green : .clear).frame(width:5,height:5)
                            }
                            .frame(alignment: .top)
                            
                            
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
    }
}
