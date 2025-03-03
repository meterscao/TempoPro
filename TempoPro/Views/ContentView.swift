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
    
    @StateObject private var metronomeState: MetronomeState
    @State private var beatsPerBar: Int = 4 {
        didSet {
            print("ContentView - beatsPerBar didSet: \(oldValue) -> \(beatsPerBar)")
            metronomeState.updateBeatsPerBar(beatsPerBar)
        }
    }
    @State private var beatUnit: Int = 4 {
        didSet {
            print("ContentView - beatUnit didSet: \(oldValue) -> \(beatUnit)")
            metronomeState.updateBeatUnit(beatUnit)
        }
    }
    @State private var showingKeypad = false
    
    init() {
        // 使用与 MetronomeState 相同的键名
        let beatsPerBarKey = "com.tempopro.beatsPerBar"
        let beatUnitKey = "com.tempopro.beatUnit"
        
        // 从 UserDefaults 读取保存的值
        let savedBeatsPerBar = UserDefaults.standard.integer(forKey: beatsPerBarKey)
        let savedBeatUnit = UserDefaults.standard.integer(forKey: beatUnitKey)
        
        print("ContentView - 初始化: 从 UserDefaults 读取值 - beatsPerBar: \(savedBeatsPerBar), beatUnit: \(savedBeatUnit)")
        
        // 如果没有保存的值，使用默认值
        _beatsPerBar = State(initialValue: savedBeatsPerBar != 0 ? savedBeatsPerBar : 4)
        _beatUnit = State(initialValue: savedBeatUnit != 0 ? savedBeatUnit : 4)
        
        // 使用保存的拍数初始化 MetronomeState
        _metronomeState = StateObject(wrappedValue: MetronomeState(beatsPerBar: savedBeatsPerBar != 0 ? savedBeatsPerBar : 3))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            MetronomeInfoView(
                tempo: Binding(
                    get: { metronomeState.tempo },
                    set: { metronomeState.updateTempo($0) }
                ),
                beatsPerBar: beatsPerBar,
                beatUnit: beatUnit,
                showingKeypad: $showingKeypad,
                beatStatuses: $metronomeState.beatStatuses,
                currentBeat: metronomeState.currentBeat,
                isPlaying: metronomeState.isPlaying,
                beatsPerBarBinding: $beatsPerBar,
                beatUnitBinding: $beatUnit
            )
            .frame(maxHeight: .infinity)
//            .background(.red)
//            .layoutPriority(1) // 提高布局优先级
            
            
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
//            .background(.green)
            
            MetronomeToolbarView()
//                .background(.purple)
                
        }
        .ignoresSafeArea(edges: .top)
        .statusBar(hidden: true)
        .preferredColorScheme(.light)
        .background(
            Image("bg-noise")
                .opacity(0.2)
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
        .onDisappear {
            metronomeState.cleanup()
        }
    }
}

#Preview {
    ContentView()
}
