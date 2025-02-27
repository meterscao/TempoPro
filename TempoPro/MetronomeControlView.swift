//
//  MetronomeControlView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI
import AVFoundation

struct MetronomeControlView: View {
    @Binding var tempo: Double
    @Binding var isPlaying: Bool
    @Binding var currentBeat: Int
    @Binding var beatStatuses: [BeatStatus]
    let beatsPerBar: Int
    
    @State private var rotation: Double = 0
    
    private let sensitivity: Double = 8
    private let dialSize: CGFloat = 280
    @State private var lastAngle: Double = 0
    @State private var totalRotation: Double = 0
    @State private var startTempo: Double = 0
    @State private var isDragging: Bool = false
    
    @State private var strongBeatPlayer: AVAudioPlayer?
    @State private var mediumBeatPlayer: AVAudioPlayer?
    @State private var normalBeatPlayer: AVAudioPlayer?
    @State private var timer: Timer?
    
    init(tempo: Binding<Double>, isPlaying: Binding<Bool>, currentBeat: Binding<Int>, beatStatuses: Binding<[BeatStatus]>, beatsPerBar: Int) {
        self._tempo = tempo
        self._isPlaying = isPlaying
        self._currentBeat = currentBeat
        self._beatStatuses = beatStatuses
        self.beatsPerBar = beatsPerBar
        
        do {
            if let strongURL = Bundle.main.url(forResource: "Metr_fl_hi", withExtension: "wav") {
                let player = try AVAudioPlayer(contentsOf: strongURL)
                _strongBeatPlayer = State(initialValue: player)
                player.prepareToPlay()
            }
            
            if let mediumURL = Bundle.main.url(forResource: "Metr_fl_mid", withExtension: "wav") {
                let player = try AVAudioPlayer(contentsOf: mediumURL)
                _mediumBeatPlayer = State(initialValue: player)
                player.prepareToPlay()
            }
            
            if let normalURL = Bundle.main.url(forResource: "Metr_fl_low", withExtension: "wav") {
                let player = try AVAudioPlayer(contentsOf: normalURL)
                _normalBeatPlayer = State(initialValue: player)
                player.prepareToPlay()
            }
        } catch {
            print("音频文件加载失败: \(error)")
        }
    }
    
    private func playBeat(status: BeatStatus) {
        switch status {
        case .strong:
            strongBeatPlayer?.currentTime = 0
            strongBeatPlayer?.play()
        case .medium:
            mediumBeatPlayer?.currentTime = 0
            mediumBeatPlayer?.play()
        case .normal:
            normalBeatPlayer?.currentTime = 0
            normalBeatPlayer?.play()
        case .muted:
            break // 不播放声音
        }
    }
    
    private func startMetronome() {
        let interval = 60.0 / tempo
        currentBeat = 0  // 重置为第一拍
        
        // 立即播放第一拍
        playBeat(status: beatStatuses[currentBeat])
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            // 先更新当前拍子
            currentBeat = (currentBeat + 1) % beatsPerBar
            
            // 再播放对应节拍的音频
            playBeat(status: beatStatuses[currentBeat])
        }
    }
    
    private func stopMetronome() {
        timer?.invalidate()
        timer = nil
        currentBeat = 0  // 重置当前拍子
    }
    
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
            stopMetronome()
            startMetronome()
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
                        startMetronome()
                    } else {
                        stopMetronome()
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
                    }
                    .onEnded { _ in
                        isDragging = false
                        totalRotation = 0
                    }
            )
            .frame(width: geometry.size.width, height: geometry.size.width)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .onChange(of: tempo) { _ in
            updateMetronome()
        }
        .onDisappear {
            stopMetronome()
        }
    }
}

#Preview {
    MetronomeControlView(tempo: .constant(120), isPlaying: .constant(false), currentBeat: .constant(0), beatStatuses: .constant([.normal, .normal, .normal, .normal]), beatsPerBar: 4)
} 
