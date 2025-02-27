//
//  ContentView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var metronomeState: MetronomeState
    @State private var beatsPerBar: Int {
        didSet {
            UserDefaults.standard.set(beatsPerBar, forKey: "com.tempopro.beatsPerBar")
        }
    }
    @State private var beatUnit: Int {
        didSet {
            UserDefaults.standard.set(beatUnit, forKey: "com.tempopro.beatUnit")
        }
    }
    @State private var showingKeypad = false
    
    init() {
        // 从 UserDefaults 读取保存的值
        let savedBeatsPerBar = UserDefaults.standard.integer(forKey: "com.tempopro.beatsPerBar")
        let savedBeatUnit = UserDefaults.standard.integer(forKey: "com.tempopro.beatUnit")
        
        // 如果没有保存的值，使用默认值
        _beatsPerBar = State(initialValue: savedBeatsPerBar != 0 ? savedBeatsPerBar : 3)
        _beatUnit = State(initialValue: savedBeatUnit != 0 ? savedBeatUnit : 4)
        
        // 使用保存的拍数初始化 MetronomeState
        _metronomeState = StateObject(wrappedValue: MetronomeState(beatsPerBar: savedBeatsPerBar != 0 ? savedBeatsPerBar : 3))
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
