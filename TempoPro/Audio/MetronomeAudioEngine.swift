import AVFoundation
import Combine

class MetronomeAudioEngine: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var strongBeatBuffer: AVAudioPCMBuffer?
    private var mediumBeatBuffer: AVAudioPCMBuffer?
    private var normalBeatBuffer: AVAudioPCMBuffer?
    
    // 预览专用播放器
    private var previewPlayer: AVAudioPlayerNode?
    // 保存预览播放器连接的格式
    private var previewPlayerFormat: AVAudioFormat?
    
    @Published private(set) var isInitialized: Bool = false
    
    // 音效缓存 - 只存储强拍音效
    private var previewBufferCache: [String: AVAudioPCMBuffer] = [:]
    
     // 初始化引擎和播放节点
    func initialize() {
        guard !isInitialized else { return }
        
        let initStartTime = Date().timeIntervalSince1970
        print("【引擎初始化】开始初始化音频引擎 - 时间: \(initStartTime)")
        
        do {
            try configureAudioSession()
            print("【引擎初始化】音频会话配置完成")
            
            // 设置主音频引擎
            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            
            if let engine = audioEngine, let player = playerNode {
                engine.attach(player)
                print("【引擎初始化】主播放节点已附加到引擎")
            }
            
            // 设置预览专用播放器（使用同一个引擎）
            previewPlayer = AVAudioPlayerNode()
            if let engine = audioEngine, let previewNode = previewPlayer {
                engine.attach(previewNode)
                print("【引擎初始化】预览播放节点已附加到引擎")
                
                // 记录详细的音频格式信息
                let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
                print("【引擎初始化】预览播放器初始连接格式 - 采样率: \(format.sampleRate), 通道数: \(format.channelCount), 格式ID: \(format.streamDescription.pointee.mFormatID)")
                
                engine.connect(previewNode, to: engine.mainMixerNode, format: format)
                previewPlayerFormat = format
                print("【引擎初始化】预览播放器已连接到混音器")
            }
            
            try loadAudioBuffers()
            try audioEngine?.start()
            print("【引擎初始化】音频引擎已启动")
            
            isInitialized = true
            print("【引擎初始化】音频引擎初始化完成 - 总耗时: \(Date().timeIntervalSince1970 - initStartTime)秒")
        } catch {
            print("【引擎初始化错误】音频引擎初始化失败: \(error)")
        }
    }
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }
    
    private func loadAudioBuffers() throws {
        guard let engine = audioEngine, let player = playerNode else { return }
        
        if let strongURL = Bundle.main.url(forResource: "kada_hi", withExtension: "wav") {
            print("【加载主缓冲区】加载强拍音频文件")
            let file = try AVAudioFile(forReading: strongURL)
            let format = file.processingFormat
            print("【加载主缓冲区】音频文件格式 - 采样率: \(format.sampleRate), 通道数: \(format.channelCount)")
            
            engine.connect(player, to: engine.mainMixerNode, format: format)
            
            strongBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: strongBeatBuffer!)
            
            // 加载其他音频文件
            try loadMediumBeat(format: format)
            try loadNormalBeat(format: format)
        }
    }
    
    private func loadMediumBeat(format: AVAudioFormat) throws {
        if let mediumURL = Bundle.main.url(forResource: "kada_mid", withExtension: "wav") {
            print("【加载主缓冲区】加载中拍音频文件")
            let file = try AVAudioFile(forReading: mediumURL)
            mediumBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: mediumBeatBuffer!)
        }
    }
    
    private func loadNormalBeat(format: AVAudioFormat) throws {
        if let normalURL = Bundle.main.url(forResource: "kada_low", withExtension: "wav") {
            print("【加载主缓冲区】加载弱拍音频文件")
            let file = try AVAudioFile(forReading: normalURL)
            normalBeatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: normalBeatBuffer!)
        }
    }
    
    // 播放主节拍器的拍子
    func playBeat(status: BeatStatus) {
        guard isInitialized, let player = playerNode else { return }
        
        let buffer: AVAudioPCMBuffer? = switch status {
        case .strong: strongBeatBuffer
        case .medium: mediumBeatBuffer
        case .normal: normalBeatBuffer
        case .muted: nil
        }
        
        if let buffer = buffer {
            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            player.play()
        }
    }
    
    // 预加载所有音效的强拍
    func preloadAllSoundSets(soundSets: [SoundSet]) {
        print("【预加载】开始预加载所有音效，总数: \(soundSets.count)")
        Task {
            for soundSet in soundSets {
                print("【预加载】准备加载音效: \(soundSet.displayName)")
                do {
                    try await preloadSoundSet(soundSet)
                } catch {
                    print("【预加载错误】加载音效 \(soundSet.displayName) 失败: \(error)")
                }
            }
            print("【预加载】所有音效预加载完成，缓存大小: \(self.previewBufferCache.count)")
        }
    }
    
    // 预加载单个音效
    private func preloadSoundSet(_ soundSet: SoundSet) async throws {
        let strongFileName = soundSet.getStrongBeatFileName()
        print("【预加载】处理音效文件: \(strongFileName)")
        
        // 如果已经缓存，则跳过
        if previewBufferCache[strongFileName] != nil {
            print("【预加载】音效已在缓存中: \(strongFileName)")
            return
        }
        
        // 加载强拍音效
        if let strongURL = Bundle.main.url(forResource: strongFileName, withExtension: "wav") {
            print("【预加载】找到音效文件: \(strongFileName).wav")
            let file = try AVAudioFile(forReading: strongURL)
            let format = file.processingFormat
            print("【预加载】音频文件格式 - 采样率: \(format.sampleRate), 通道数: \(format.channelCount)")
            
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: buffer!)
            
            // 检查缓冲区与预览播放器格式是否匹配
            if let previewFormat = previewPlayerFormat {
                print("【预加载】格式比较 - 缓冲区: \(format.channelCount)通道, 播放器: \(previewFormat.channelCount)通道")
                if format.channelCount != previewFormat.channelCount {
                    print("【预加载警告】音频格式不匹配! 预览可能会崩溃")
                }
            }
            
            // 存入缓存
            previewBufferCache[strongFileName] = buffer
            print("【预加载】音效已缓存: \(soundSet.displayName)")
        } else {
            print("【预加载错误】找不到音效文件: \(strongFileName).wav")
        }
    }
    
    // 播放预览音效
    func previewSoundSet(_ soundSet: SoundSet) {
        guard isInitialized, let previewPlayer = self.previewPlayer, let engine = self.audioEngine else {
            print("【预览播放】预览引擎未初始化")
            return
        }
        
        print("【预览播放】开始预览音效: \(soundSet.displayName)")
        
        // 获取音效强拍文件名
        let strongFileName = soundSet.getStrongBeatFileName()
        print("【预览播放】音效文件名: \(strongFileName)")
        
        // 尝试从缓存获取
        if let buffer = previewBufferCache[strongFileName] {
            print("【预览播放】从缓存获取到缓冲区 - 通道数: \(buffer.format.channelCount)")
            
            // 重要修改: 在播放前断开并使用正确格式重新连接
            print("【预览播放】断开现有连接")
            engine.disconnectNodeOutput(previewPlayer)
            
            print("【预览播放】使用匹配的格式重新连接 - 通道数: \(buffer.format.channelCount)")
            engine.connect(previewPlayer, to: engine.mainMixerNode, format: buffer.format)
            previewPlayerFormat = buffer.format
            
            // 在转到主线程调度 UI 更新之前记录
            print("【预览播放】准备播放音效")
            DispatchQueue.main.async {
                print("【预览播放】主线程上调度缓冲区")
                self.previewPlayer?.scheduleBuffer(buffer, at: nil, options: [], completionHandler: {
                    print("【预览播放】播放完成")
                })
                print("【预览播放】开始播放")
                self.previewPlayer?.play()
            }
        } else {
            print("【预览播放】缓存中没有找到音效，尝试加载: \(strongFileName)")
            // 如果缓存中没有，尝试加载并播放
            Task {
                do {
                    print("【预览播放】开始加载音效")
                    try await preloadSoundSet(soundSet)
                    print("【预览播放】加载完成，检查缓存")
                    
                    if let buffer = previewBufferCache[strongFileName] {
                        print("【预览播放】找到新加载的缓冲区，准备播放")
                        DispatchQueue.main.async {
                            print("【预览播放】主线程上调度新加载的缓冲区")
                            self.previewPlayer?.scheduleBuffer(buffer, at: nil, options: [], completionHandler: {
                                print("【预览播放】播放完成")
                            })
                            print("【预览播放】开始播放新加载的音效")
                            self.previewPlayer?.play()
                        }
                    } else {
                        print("【预览播放错误】加载后仍未找到缓冲区")
                    }
                } catch {
                    print("【预览播放错误】加载音效失败: \(error)")
                }
            }
        }
    }
    
    func stop() {
        print("【停止播放】停止所有播放器")
        playerNode?.stop()
        previewPlayer?.stop()
    }
}