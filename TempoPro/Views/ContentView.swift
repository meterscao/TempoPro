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
    
    @State private var completionDuration: TimeInterval = 0
    @State private var completionTempo: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            MetronomeInfoView()
            .frame(maxHeight: .infinity)

            MetronomeControlView()
                .aspectRatio(16/16, contentMode: .fit)
            
            MetronomeToolbarView()
                
        }
        .ignoresSafeArea(edges: .all)
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .background(
            Image("bg-noise")
                .resizable(resizingMode: .tile)
                .opacity(0.06)
                .ignoresSafeArea()
        )
        .background(theme.primaryColor.ignoresSafeArea())
        

    }
}