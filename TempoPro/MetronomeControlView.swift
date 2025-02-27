//
//  MetronomeControlView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct MetronomeControlView: View {
    private let dialSize: CGFloat = 300  // 表盘大小
    private let sensitivity: Double = 1.0 // 旋转灵敏度
    
    @Binding var tempo: Double
    @Binding var isPlaying: Bool
    @Binding var currentBeat: Int
    @Binding var beatStatuses: [BeatStatus]
    let beatsPerBar: Int
    
    @State private var rotation: Double = 0
    @State private var lastAngle: Double = 0
    @State private var totalRotation: Double = 0
    @State private var startTempo: Double = 0
    @State private var isDragging: Bool = false
    
    // 使用新的音频引擎和定时器
    @StateObject private var audioEngine = MetronomeAudioEngine()
    @State private var metronomeTimer: MetronomeTimer?
    
    private func createTicks() -> some View {
        ZStack {
            ForEach(0..<60) { i in
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 1, height: 10)
                    .offset(y: -(dialSize/2 - 10))
                    .rotationEffect(.degrees(Double(i) * 6))
            }
            ForEach(0..<12) { i in
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: 20)
                    .offset(y: -(dialSize/2 - 15))
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
    }
    
    private func calculateAngle(location: CGPoint, in frame: CGRect) -> Double {
        let centerX = frame.width / 2
        let centerY = frame.height / 2
        let deltaX = location.x - centerX
        let deltaY = location.y - centerY
        
        var angle = atan2(deltaY, deltaX) * (180 / .pi)
        if angle < 0 {
            angle += 360
        }
        return angle
    }
    
    private func updateMetronome() {
        if isPlaying {
            metronomeTimer?.stop()
            metronomeTimer?.start(tempo: tempo, beatsPerBar: beatsPerBar, beatStatuses: beatStatuses)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                
                Circle()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: geometry.size.width*0.8, height: geometry.size.width*0.8)
                    .rotationEffect(.degrees(rotation))
                
                createTicks()
                    .rotationEffect(.degrees(rotation))
                
                Button(action: {
                    isPlaying.toggle()
                    if isPlaying {
                        metronomeTimer?.start(tempo: tempo, beatsPerBar: beatsPerBar, beatStatuses: beatStatuses)
                    } else {
                        metronomeTimer?.stop()
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.black)
                }
            }
            .frame(width: geometry.size.width*0.8, height: geometry.size.width*0.8)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            lastAngle = calculateAngle(
                                location: value.location,
                                in: CGRect(x: 0, y: 0, width: geometry.size.width*0.8, height: geometry.size.width*0.8)
                            )
                            startTempo = tempo
                        }
                        
                        let currentAngle = calculateAngle(
                            location: value.location,
                            in: CGRect(x: 0, y: 0, width: geometry.size.width*0.8, height: geometry.size.width*0.8)
                        )
                        
                        var angleDiff = currentAngle - lastAngle
                        
                        if angleDiff > 180 {
                            angleDiff -= 360
                        } else if angleDiff < -180 {
                            angleDiff += 360
                        }
                        
                        totalRotation += angleDiff
                        rotation += angleDiff
                        
                        let tempoChange = round(totalRotation / sensitivity)
                        let targetTempo = max(30, min(240, startTempo + tempoChange))
                        
                        tempo = targetTempo
                        lastAngle = currentAngle
                        
                        updateMetronome()
                    }
                    .onEnded { _ in
                        isDragging = false
                        totalRotation = 0
                    }
            )
            .frame(width: geometry.size.width, height: geometry.size.width)
        }
        .onAppear {
            // 初始化音频引擎
            audioEngine.initialize()
            // 创建定时器并设置回调
            let timer = MetronomeTimer(audioEngine: audioEngine)
            timer.onBeatUpdate = { beat in
                currentBeat = beat
            }
            metronomeTimer = timer
        }
        .onDisappear {
            metronomeTimer?.stop()
            audioEngine.stop()
        }
    }
}

#Preview {
    MetronomeControlView(tempo: .constant(120), isPlaying: .constant(false), currentBeat: .constant(0), beatStatuses: .constant([.normal, .normal, .normal, .normal]), beatsPerBar: 4)
} 
