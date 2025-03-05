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
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager // 类型改为 CoreDataPlaylistManager
    @StateObject private var metronomeState = MetronomeState()
    
    var body: some View {
        VStack(spacing: 0) {
            MetronomeInfoView()
            .frame(maxHeight: .infinity)

            MetronomeControlView()
                .environmentObject(metronomeState)
                .aspectRatio(10/9, contentMode: .fit)
            
            MetronomeToolbarView()
                .environmentObject(playlistManager) // 确保传递 CoreDataPlaylistManager
                
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
        .environmentObject(ThemeManager())
}
