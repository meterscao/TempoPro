import AVFoundation
import Combine

class MetronomeAudioEngine: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    // 移除单独的缓冲区变量，统一使用缓存
    private var soundBufferCache: [String: AVAudioPCMBuffer] = [:]
    private var currentSoundSet: SoundSet = SoundSetManager.getDefaultSoundSet()
    
    // 预览专用播放器
    private var previewPlayer: AVAudioPlayerNode?
    // 保存预览播放器连接的格式
    private var previewPlayerFormat: AVAudioFormat?
    
    @Published private(set) var isInitialized: Bool = false
    
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
                
                // 先用标准格式连接，后续会根据实际音频格式重新连接
                let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
                engine.connect(player, to: engine.mainMixerNode, format: format)
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
            
            // 启动引擎
            try audioEngine?.start()
            print("【引擎初始化】音频引擎已启动")
            
            isInitialized = true
            print("【引擎初始化】音频引擎初始化完成 - 总耗时: \(Date().timeIntervalSince1970 - initStartTime)秒")
            
            // 初始化完成后加载默认音效集
            loadDefaultSoundSet()
        } catch {
            print("【引擎初始化错误】音频引擎初始化失败: \(error)")
        }
    }
    
    // 加载默认音效集
    private func loadDefaultSoundSet() {
        Task {
            do {
                // 获取默认音效集
                let defaultSoundSet = SoundSetManager.getDefaultSoundSet()
                print("【加载默认音效】开始加载默认音效: \(defaultSoundSet.displayName)")
                
                // 加载全套音效（包括强拍、中拍和弱拍）
                try await loadCompleteSoundSet(defaultSoundSet)
                
                // 设置为当前音效
                self.currentSoundSet = defaultSoundSet
                print("【加载默认音效】默认音效加载完成")
                
                // 如果播放器已连接，根据加载的音频格式重新连接
                if let engine = self.audioEngine, 
                   let player = self.playerNode, 
                   let buffer = self.soundBufferCache[defaultSoundSet.getStrongBeatFileName()] {
                    print("【加载默认音效】使用匹配格式重新连接主播放器节点")
                    engine.disconnectNodeOutput(player)
                    engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
                }
            } catch {
                print("【加载默认音效错误】加载默认音效失败: \(error)")
            }
        }
    }
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }
    
    // 加载完整的音效集（强拍、中拍和弱拍）
    private func loadCompleteSoundSet(_ soundSet: SoundSet) async throws {
        try await loadSoundFile(soundSet.getStrongBeatFileName(), withExtension: "wav")
        try await loadSoundFile(soundSet.getMediumBeatFileName(), withExtension: "wav")
        try await loadSoundFile(soundSet.getNormalBeatFileName(), withExtension: "wav")
    }
    
    // 加载单个音频文件
    private func loadSoundFile(_ fileName: String, withExtension ext: String) async throws {
        print("【加载音频】加载音频文件: \(fileName).\(ext)")
        
        // 如果已经缓存，则跳过
        if soundBufferCache[fileName] != nil {
            print("【加载音频】音频已在缓存中: \(fileName)")
            return
        }
        
        // 加载音频文件
        if let fileURL = Bundle.main.url(forResource: fileName, withExtension: ext) {
            let file = try AVAudioFile(forReading: fileURL)
            let format = file.processingFormat
            print("【加载音频】音频文件格式 - 采样率: \(format.sampleRate), 通道数: \(format.channelCount)")
            
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: buffer!)
            
            // 存入缓存
            soundBufferCache[fileName] = buffer
            print("【加载音频】音频已缓存: \(fileName)")
        } else {
            print("【加载音频错误】找不到音频文件: \(fileName).\(ext)")
            throw NSError(domain: "MetronomeAudioEngine", code: 404, userInfo: [NSLocalizedDescriptionKey: "音频文件不存在"])
        }
    }
    
    // 播放主节拍器的拍子（使用统一缓存）
    func playBeat(status: BeatStatus) {
        guard isInitialized, let player = playerNode, let engine = audioEngine else { return }
        
        let fileName: String? = switch status {
            case .strong: currentSoundSet.getStrongBeatFileName()
            case .medium: currentSoundSet.getMediumBeatFileName()
            case .normal: currentSoundSet.getNormalBeatFileName()
            case .muted: nil // 改为返回 nil 而不是 return
        }
        
        // 检查文件名是否为 nil (静音拍)
        guard let fileName = fileName else { return }
        
        if let buffer = soundBufferCache[fileName] {
            // 确保播放器连接使用正确的格式
            ensurePlayerConnected(player, withFormat: buffer.format, engine: engine)
            
            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            player.play()
        }
    }
    
    // 确保播放器连接了正确的格式
    private func ensurePlayerConnected(_ player: AVAudioPlayerNode, withFormat format: AVAudioFormat, engine: AVAudioEngine) {
        // 修复错误2: 使用可选绑定处理 outputFormat 可能为 nil 的情况
        if let currentFormat = player.outputFormat(forBus: 0) as? AVAudioFormat, 
           currentFormat.channelCount != format.channelCount || 
           currentFormat.sampleRate != format.sampleRate {
            print("【播放】重新连接播放器 - 旧格式: \(currentFormat.channelCount)通道, 新格式: \(format.channelCount)通道")
            engine.disconnectNodeOutput(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
    }
    
    // 设置当前音效集
    func setCurrentSoundSet(_ soundSet: SoundSet) {
        Task {
            // 先加载全套音效
            try? await loadCompleteSoundSet(soundSet)
            // 更新当前音效
            currentSoundSet = soundSet
        }
    }
    
    // 预加载所有音效的强拍
    func preloadAllSoundSets(soundSets: [SoundSet]) {
        print("【预加载】开始预加载所有音效，总数: \(soundSets.count)")
        Task {
            for soundSet in soundSets {
                print("【预加载】准备加载音效: \(soundSet.displayName)")
                do {
                    // 只加载强拍（预览用）
                    try await loadSoundFile(soundSet.getStrongBeatFileName(), withExtension: "wav")
                } catch {
                    print("【预加载错误】加载音效 \(soundSet.displayName) 失败: \(error)")
                }
            }
            print("【预加载】所有音效预加载完成，缓存大小: \(self.soundBufferCache.count)")
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
        if let buffer = soundBufferCache[strongFileName] {
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
                    try await loadSoundFile(strongFileName, withExtension: "wav")
                    print("【预览播放】加载完成，检查缓存")
                    
                    if let buffer = soundBufferCache[strongFileName] {
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