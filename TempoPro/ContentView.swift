//
//  ContentView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var tempo: Double = 120
    @State private var beatsPerBar: Int = 3  // 每小节的拍数
    @State private var beatUnit: Int = 4      // 以几分音符为一拍
    @State private var isPlaying = false
    @State private var showingKeypad = false
    @State private var currentBeat: Int = 0  // 添加当前拍子的状态
    @State private var beatStatuses: [BeatStatus] = [
        .strong,  // 第一拍：强拍
        .normal,  // 第二拍：弱拍
        .normal,  // 第三拍：弱拍
        .normal   // 第四拍：弱拍
    ]
    
    var body: some View {
        
            VStack(spacing: 0) {
                    MetronomeInfoView(
                        tempo: tempo,
                        beatsPerBar: beatsPerBar,
                        beatUnit: beatUnit,
                        showingKeypad: $showingKeypad,
                        beatStatuses: $beatStatuses,
                        currentBeat: currentBeat,
                        isPlaying: isPlaying  // 传递 isPlaying 状态
                    )
                    
                    
                    .frame(maxHeight: .infinity)  // 使用相对高度
                
                
                MetronomeControlView(
                    tempo: $tempo,
                    isPlaying: $isPlaying,
                    currentBeat: $currentBeat,
                    beatStatuses: $beatStatuses,  // 传入 beatStatuses
                    beatsPerBar: beatsPerBar
                )
                    
                
                MetronomeToolbarView()
                    .frame(maxWidth: .infinity)
                    .background(.red)
            }
        
        .statusBar(hidden: true)
        .preferredColorScheme(.light)
        .background(Color(UIColor.systemGray6))
        .sheet(isPresented: $showingKeypad) {
            BPMKeypadView(isPresented: $showingKeypad, tempo: $tempo)
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ContentView()
}
