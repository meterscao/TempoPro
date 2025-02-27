//
//  MetronomeControlView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI
import AVFoundation

struct MetronomeControlView: View {
    private let dialSize: CGFloat = 300  // 表盘大小
    private let sensitivity: Double = 8 // 旋转灵敏度
    
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
    
    @State private var strongBeatPlayer: AVAudioPlayer?
    @State private var mediumBeatPlayer: AVAudioPlayer?
    @State private var normalBeatPlayer: AVAudioPlayer?
    @State private var timer: Timer?
    
    @State private var isAudioInitialized: Bool = false
    
    @State private var audioEngine: AVAudioEngine?
    @State private var strongBeatBuffer: AVAudioPCMBuffer?
    @State private var mediumBeatBuffer: AVAudioPCMBuffer?
    @State private var normalBeatBuffer: AVAudioPCMBuffer?
    @State private var playerNode: AVAudioPlayerNode?
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
            print("音频会话配置完成")
        } catch {
            print("音频会话配置失败: \(error)")
        }
    }
    
    private func initializeAudioPlayers() {
        guard !isAudioInitialized else { return }
        
        let initStartTime = Date().timeIntervalSince1970
        print("开始初始化音频播放器 - 时间: \(initStartTime)")
        
        configureAudioSession()
        
        do {
            if let strongURL = Bundle.main.url(forResource: "Metr_fl_hi", withExtension: "wav") {
                print("加载强拍音频文件")
                let loadStart = Date().timeIntervalSince1970
                strongBeatPlayer = try AVAudioPlayer(contentsOf: strongURL)
                strongBeatPlayer?.numberOfLoops = 0
                strongBeatPlayer?.volume = 1.0
                strongBeatPlayer?.prepareToPlay()
                strongBeatPlayer?.play()
                strongBeatPlayer?.stop()
                print("强拍音频加载完成 - 耗时: \(Date().timeIntervalSince1970 - loadStart)秒")
            }
            
            if let mediumURL = Bundle.main.url(forResource: "Metr_fl_mid", withExtension: "wav") {
                print("加载中拍音频文件")
                let loadStart = Date().timeIntervalSince1970
                mediumBeatPlayer = try AVAudioPlayer(contentsOf: mediumURL)
                mediumBeatPlayer?.numberOfLoops = 0
                mediumBeatPlayer?.volume = 1.0
                mediumBeatPlayer?.prepareToPlay()
                mediumBeatPlayer?.play()
                mediumBeatPlayer?.stop()
                print("中拍音频加载完成 - 耗时: \(Date().timeIntervalSince1970 - loadStart)秒")
            }
            
            if let normalURL = Bundle.main.url(forResource: "Metr_fl_low", withExtension: "wav") {
                print("加载弱拍音频文件")
                let loadStart = Date().timeIntervalSince1970
                normalBeatPlayer = try AVAudioPlayer(contentsOf: normalURL)
                normalBeatPlayer?.numberOfLoops = 0
                normalBeatPlayer?.volume = 1.0
                normalBeatPlayer?.prepareToPlay()
                normalBeatPlayer?.play()
                normalBeatPlayer?.stop()
                print("弱拍音频加载完成 - 耗时: \(Date().timeIntervalSince1970 - loadStart)秒")
            }
            
            isAudioInitialized = true
            print("音频初始化完成 - 总耗时: \(Date().timeIntervalSince1970 - initStartTime)秒")
        } catch {
            print("音频文件加载失败: \(error)")
        }
    }
    
    private func initializeAudioEngine() {
        guard !isAudioInitialized else { return }
        
        let initStartTime = Date().timeIntervalSince1970
        print("开始初始化音频引擎 - 时间: \(initStartTime)")
        
        do {
            // 配置音频会话
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
            
            // 创建音频引擎
            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            
            if let engine = audioEngine, let player = playerNode {
                engine.attach(player)
                
                // 加载音频文件并获取格式
                if let strongURL = Bundle.main.url(forResource: "Metr_fl_hi", withExtension: "wav") {
                    print("加载强拍音频文件")
                    let file = try AVAudioFile(forReading: strongURL)
                    let format = file.processingFormat
                    engine.connect(player, to: engine.mainMixerNode, format: format)
                    
                    strongBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
                    try file.read(into: strongBeatBuffer!)
                    
                    // 使用相同的格式加载其他音频文件
                    if let mediumURL = Bundle.main.url(forResource: "Metr_fl_mid", withExtension: "wav") {
                        print("加载中拍音频文件")
                        let mediumFile = try AVAudioFile(forReading: mediumURL)
                        mediumBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(mediumFile.length))
                        try mediumFile.read(into: mediumBeatBuffer!)
                    }
                    
                    if let normalURL = Bundle.main.url(forResource: "Metr_fl_low", withExtension: "wav") {
                        print("加载弱拍音频文件")
                        let normalFile = try AVAudioFile(forReading: normalURL)
                        normalBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(normalFile.length))
                        try normalFile.read(into: normalBeatBuffer!)
                    }
                }
                
                try engine.start()
                isAudioInitialized = true
                print("音频引擎初始化完成 - 总耗时: \(Date().timeIntervalSince1970 - initStartTime)秒")
            }
        } catch {
            print("音频引擎初始化失败: \(error)")
        }
    }
    
    private func playBeat(status: BeatStatus) {
        if !isAudioInitialized {
            initializeAudioEngine()
        }
        
        let timestamp = Date().timeIntervalSince1970
        print("开始播放节拍 - 时间戳: \(timestamp), 当前拍号: \(currentBeat), 状态: \(status)")
        
        guard let player = playerNode else { return }
        
        let beforePlay = Date().timeIntervalSince1970
        
        switch status {
        case .strong:
            if let buffer = strongBeatBuffer {
                player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                player.play()
                print("强拍播放延迟: \(Date().timeIntervalSince1970 - beforePlay)秒")
            }
        case .medium:
            if let buffer = mediumBeatBuffer {
                player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                player.play()
                print("中拍播放延迟: \(Date().timeIntervalSince1970 - beforePlay)秒")
            }
        case .normal:
            if let buffer = normalBeatBuffer {
                player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                player.play()
                print("弱拍播放延迟: \(Date().timeIntervalSince1970 - beforePlay)秒")
            }
        case .muted:
            print("静音拍")
        }
    }
    
    private func startMetronome() {
        let interval = 60.0 / tempo
        print("开始节拍器 - BPM: \(tempo), 间隔: \(interval)秒")
        currentBeat = 0
        
        let startTime = Date().timeIntervalSince1970
        print("首拍开始时间: \(startTime)")
        
        DispatchQueue.global(qos: .userInteractive).async {
            playBeat(status: beatStatuses[currentBeat])
            
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                DispatchQueue.main.async {
                    let beatTime = Date().timeIntervalSince1970
                    let timeSinceStart = beatTime - startTime
                    
                    currentBeat = (currentBeat + 1) % beatsPerBar
                    print("节拍更新 - 时间: \(beatTime), 距离开始: \(timeSinceStart)秒, 当前拍号: \(currentBeat)")
                    
                    playBeat(status: beatStatuses[currentBeat])
                }
            }
            
            RunLoop.current.add(timer!, forMode: .common)
            RunLoop.current.run()
        }
    }
    
    private func stopMetronome() {
        print("停止节拍器")
        timer?.invalidate()
        timer = nil
        currentBeat = 0
        playerNode?.stop()
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
            print("更新节拍器 - 新的速度: \(tempo) BPM")
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
        .onAppear {
            initializeAudioEngine()
        }
        .onChange(of: tempo) { _ in
            updateMetronome()
        }
        .onDisappear {
            stopMetronome()
            audioEngine?.stop()
        }
    }
}

#Preview {
    MetronomeControlView(tempo: .constant(120), isPlaying: .constant(false), currentBeat: .constant(0), beatStatuses: .constant([.normal, .normal, .normal, .normal]), beatsPerBar: 4)
} 
