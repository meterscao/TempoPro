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
    @AppStorage(AppStorageKeys.Metronome.beatsPerBar) private var beatsPerBar: Int = 4 {
        didSet {
            print("ContentView - beatsPerBar didSet: \(oldValue) -> \(beatsPerBar)")
            metronomeState.updateBeatsPerBar(beatsPerBar)
        }
    }
    @AppStorage(AppStorageKeys.Metronome.beatUnit) private var beatUnit: Int = 4 {
        didSet {
            print("ContentView - beatUnit didSet: \(oldValue) -> \(beatUnit)")
            metronomeState.updateBeatUnit(beatUnit)
        }
    }
    @State private var showingKeypad = false
    @State private var showingTimeSignature = false
    
    var body: some View {
        VStack(spacing: 0) {
            MetronomeInfoView(
                tempo: Binding(
                    get: { metronomeState.tempo },
                    set: { metronomeState.updateTempo($0) }
                ),
                showingKeypad: $showingKeypad,
                beatStatuses: $metronomeState.beatStatuses,
                currentBeat: metronomeState.currentBeat,
                isPlaying: metronomeState.isPlaying
            )
            .frame(maxHeight: .infinity)

            MetronomeControlView(
                tempo: Binding(
                    get: { metronomeState.tempo },
                    set: { metronomeState.updateTempo($0) }
                ),
                isPlaying: Binding(
                    get: { metronomeState.isPlaying },
                    set: { _ in metronomeState.togglePlayback() }
                ),
                beatsPerBar: beatsPerBar
            )
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
        
        .sheet(isPresented: $showingKeypad) {
            BPMKeypadView(
                isPresented: $showingKeypad,
                tempo: Binding(
                    get: { metronomeState.tempo },
                    set: { metronomeState.updateTempo($0) }
                )
            )
            .ignoresSafeArea()
            .presentationDetents([.height(400)])
            
        }
        .sheet(isPresented: $showingTimeSignature) {
            TimeSignatureView()
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
        }
        .onDisappear {
            metronomeState.cleanup()
        }
    }
}

#Preview {
    ContentView()
}
