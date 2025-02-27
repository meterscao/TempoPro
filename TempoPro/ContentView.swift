//
//  ContentView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var metronomeState: MetronomeState
    @State private var beatsPerBar: Int = 3
    @State private var beatUnit: Int = 4
    @State private var showingKeypad = false
    
    init() {
        // 使用正确的拍数初始化 MetronomeState
        _metronomeState = StateObject(wrappedValue: MetronomeState(beatsPerBar: 3))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            MetronomeInfoView(
                tempo: metronomeState.tempo,
                beatsPerBar: beatsPerBar,
                beatUnit: beatUnit,
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
            
            MetronomeToolbarView()
                .frame(maxWidth: .infinity)
        }
        .statusBar(hidden: true)
        .preferredColorScheme(.light)
        .background(Color(UIColor.systemGray6))
        .sheet(isPresented: $showingKeypad) {
            BPMKeypadView(
                isPresented: $showingKeypad,
                tempo: Binding(
                    get: { metronomeState.tempo },
                    set: { metronomeState.updateTempo($0) }
                )
            )
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
