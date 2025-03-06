import AVFoundation
import Combine

class MetronomeAudioEngine: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var strongBeatBuffer: AVAudioPCMBuffer?
    private var mediumBeatBuffer: AVAudioPCMBuffer?
    private var normalBeatBuffer: AVAudioPCMBuffer?
    
    @Published private(set) var isInitialized: Bool = false
    
    func initialize() {
        guard !isInitialized else { return }
        
        let initStartTime = Date().timeIntervalSince1970
        print("开始初始化音频引擎 - 时间: \(initStartTime)")
        
        do {
            try configureAudioSession()
            try setupAudioEngine()
            try loadAudioBuffers()
            
            try audioEngine?.start()
            isInitialized = true
            print("音频引擎初始化完成 - 总耗时: \(Date().timeIntervalSince1970 - initStartTime)秒")
        } catch {
            print("音频引擎初始化失败: \(error)")
        }
    }
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback)
        try session.setActive(true)
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        if let engine = audioEngine, let player = playerNode {
            engine.attach(player)
        }
    }
    
    private func loadAudioBuffers() throws {
        guard let engine = audioEngine, let player = playerNode else { return }
        
        if let strongURL = Bundle.main.url(forResource: "Metr_fl_hi", withExtension: "wav") {
            print("加载强拍音频文件")
            let file = try AVAudioFile(forReading: strongURL)
            let format = file.processingFormat
            engine.connect(player, to: engine.mainMixerNode, format: format)
            
            strongBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: strongBeatBuffer!)
            
            // 加载其他音频文件
            try loadMediumBeat(format: format)
            try loadNormalBeat(format: format)
        }
    }
    
    private func loadMediumBeat(format: AVAudioFormat) throws {
        if let mediumURL = Bundle.main.url(forResource: "Metr_fl_mid", withExtension: "wav") {
            print("加载中拍音频文件")
            let file = try AVAudioFile(forReading: mediumURL)
            mediumBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: mediumBeatBuffer!)
        }
    }
    
    private func loadNormalBeat(format: AVAudioFormat) throws {
        if let normalURL = Bundle.main.url(forResource: "Metr_fl_low", withExtension: "wav") {
            print("加载弱拍音频文件")
            let file = try AVAudioFile(forReading: normalURL)
            normalBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: normalBeatBuffer!)
        }
    }
    
    func playBeat(status: BeatStatus) {
        guard isInitialized, let player = playerNode else { return }
        
        let timestamp = Date().timeIntervalSince1970
        print("开始播放节拍 - 时间戳: \(timestamp), 状态: \(status)")
        
        let beforePlay = Date().timeIntervalSince1970
        
        let buffer: AVAudioPCMBuffer? = switch status {
        case .strong: strongBeatBuffer
        case .medium: mediumBeatBuffer
        case .normal: normalBeatBuffer
        case .muted: nil
        }
        
        if let buffer = buffer {
            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            player.play()
            print("\(status)拍播放延迟: \(Date().timeIntervalSince1970 - beforePlay)秒")
        }
    }
    
    func stop() {
        playerNode?.stop()
        audioEngine?.stop()
    }
} 
