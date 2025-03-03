//
//  ContentView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var metronomeState = MetronomeState()
    
    var body: some View {
        VStack(spacing: 0) {
            MetronomeInfoView()
            .frame(maxHeight: .infinity)

            MetronomeControlView()
                .environmentObject(metronomeState)
                .aspectRatio(10/9, contentMode: .fit) // 设置宽高比为5:4（相当于高度为宽度的80%）
            
            MetronomeToolbarView()
                
        }
        .ignoresSafeArea(edges: .top)
        .statusBar(hidden: true)
        .preferredColorScheme(.light)
        .background(
            Image("bg-noise")
                .resizable(resizingMode: .tile)
                .opacity(0.06)
                .ignoresSafeArea()
        )
        .background(theme.primaryColor.ignoresSafeArea())
        
        .onDisappear {
            metronomeState.cleanup()
        }
        .environmentObject(metronomeState)
    }
}

#Preview {
    ContentView()
}
