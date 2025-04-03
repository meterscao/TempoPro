import AVFoundation
import Combine

class MyAudioService: ObservableObject {
    // 核心音频引擎组件
    private var audioEngine: AVAudioEngine?      // 音频引擎，管理音频节点和连接
    private var playerNode: AVAudioPlayerNode?   // 主播放节点，用于播放节拍器声音
    
    // 统一的音效缓存系统，存储所有已加载的音频缓冲区
    // 键为音频文件名(如"wood_hi")，值为对应的音频缓冲区
    private var soundBufferCache: [String: AVAudioPCMBuffer] = [:]
    
    // 当前使用的音效集
    private var currentSoundSet: SoundSet
    
    // 专门用于预览音效的播放器节点
    private var previewPlayer: AVAudioPlayerNode?
    // 记录预览播放器当前连接的音频格式
    private var previewPlayerFormat: AVAudioFormat?
    
    // 标记引擎是否已初始化
    @Published private(set) var isInitialized: Bool = false
    
    // 用于管理异步加载任务
    private var loadingTask: Task<Void, Never>? = nil
    
    // 音频会话操作锁，防止并发修改音频会话
    private let audioSessionLock = NSLock()
    
    init(defaultSoundSet: SoundSet = SoundSetManager.getDefaultSoundSet()) {
        self.currentSoundSet = defaultSoundSet
        initialize(defaultSoundSet: defaultSoundSet)
    }
    
    // 初始化音频引擎及相关组件
    private func initialize(defaultSoundSet: SoundSet = SoundSetManager.getDefaultSoundSet()) {
        // 避免重复初始化
        guard !isInitialized else { return }
        
        let initStartTime = Date().timeIntervalSince1970
        print("【引擎初始化】开始初始化音频引擎 - 时间: \(initStartTime)")
        
        do {
            // 配置音频会话
            try configureAudioSession()
            print("【引擎初始化】音频会话配置完成")
            
            // 创建主音频引擎和播放节点
            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            
            if let engine = audioEngine, let player = playerNode {
                // 将播放节点附加到引擎
                engine.attach(player)
                print("【引擎初始化】主播放节点已附加到引擎")
                
                // 使用标准格式进行初始连接，后续会根据实际音频格式动态调整
                let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
                engine.connect(player, to: engine.mainMixerNode, format: format)
            }
            
            // 设置预览专用播放器
            previewPlayer = AVAudioPlayerNode()
            if let engine = audioEngine, let previewNode = previewPlayer {
                engine.attach(previewNode)
                print("【引擎初始化】预览播放节点已附加到引擎")
                
                // 初始化预览播放器连接
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
            
            // 加载默认音效集
            loadDefaultSoundSet(defaultSoundSet: defaultSoundSet)

            // 添加中断处理
            setupInterruptionHandling()
        } catch {
            print("【引擎初始化错误】音频引擎初始化失败: \(error)")
        }
    }

    
    // 加载默认音效集
    private func loadDefaultSoundSet(defaultSoundSet: SoundSet) {
        
        Task {
            
            do {
                let loadStartTime = Date().timeIntervalSince1970
                // 获取默认音效
                print("【加载默认音效】开始加载默认音效: \(defaultSoundSet.displayName)")
                
                // 加载全套音效（强拍、中拍、弱拍）
                try await loadCompleteSoundSet(defaultSoundSet)
                
                // 更新当前音效
                self.currentSoundSet = defaultSoundSet
                print("【加载默认音效】默认音效加载完成")
                
                // 根据加载的音频格式重新连接主播放器
                if let engine = self.audioEngine, 
                let player = self.playerNode, 
                let buffer = self.soundBufferCache[defaultSoundSet.getStrongBeatFileName()] {
                    print("【加载默认音效】使用匹配格式重新连接主播放器节点")
                    engine.disconnectNodeOutput(player)
                    engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
                }
                // 打下日志音频加载的耗时
                let loadTime = Date().timeIntervalSince1970 - loadStartTime
                print("【加载默认音效】默认音效加载完成 - 总耗时: \(loadTime)秒")
            } catch {
                print("【加载默认音效错误】加载默认音效失败: \(error)")
            }
        }
        
    }

    // 加载完整的音效集（强拍、中拍和弱拍）
    private func loadCompleteSoundSet(_ soundSet: SoundSet) async throws {
        try await loadSoundFile(soundSet.getStrongBeatFileName(), withExtension: "wav")
        try await loadSoundFile(soundSet.getMediumBeatFileName(), withExtension: "wav")
        try await loadSoundFile(soundSet.getNormalBeatFileName(), withExtension: "wav")
    }

    // 加载单个音频文件并缓存
    private func loadSoundFile(_ fileName: String, withExtension ext: String) async throws {
        print("【加载音频】加载音频文件: \(fileName).\(ext)")
        
        // 如果已缓存则跳过
        if soundBufferCache[fileName] != nil {
            print("【加载音频】音频已在缓存中: \(fileName)")
            return
        }
        
        // 从Bundle加载音频文件
        if let fileURL = Bundle.main.url(forResource: fileName, withExtension: ext) {
            let file = try AVAudioFile(forReading: fileURL)
            let format = file.processingFormat
            print("【加载音频】音频文件格式 - 采样率: \(format.sampleRate), 通道数: \(format.channelCount)")
            
            // 创建缓冲区并读取文件内容
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
    
    // 配置音频会话，设置为播放模式并激活
    private func configureAudioSession() throws {
        // 加锁确保线程安全
        audioSessionLock.lock()
        defer { audioSessionLock.unlock() }
        
        let session = AVAudioSession.sharedInstance()
        // 设置为播放类别，允许与其他应用混音
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }
    

    
    // 播放主节拍器的拍子
    func playBeat(status: BeatStatus) {
        // 确保引擎运行
        ensureEngineRunning()
        
        guard isInitialized, let player = playerNode, let engine = audioEngine else { return }
        
        // 根据节拍状态确定要播放的音频文件
        let fileName: String? = switch status {
            case .strong: currentSoundSet.getStrongBeatFileName()  // 强拍
            case .medium: currentSoundSet.getMediumBeatFileName()  // 中拍
            case .normal: currentSoundSet.getNormalBeatFileName()  // 弱拍
            case .muted: nil  // 静音拍，不播放
        }
        
        // 检查文件名是否为nil（静音拍）
        guard let fileName = fileName else { return }
        
        // 从缓存获取音频缓冲区
        if let buffer = soundBufferCache[fileName] {
            // 确保播放器连接使用正确的音频格式
            ensurePlayerConnected(player, withFormat: buffer.format, engine: engine)
            
            // 调度缓冲区播放，使用.interrupts选项自动中断当前播放内容
            player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
            player.play()
        }
    }
    
    // 确保播放器使用正确的格式连接到引擎
    private func ensurePlayerConnected(_ player: AVAudioPlayerNode, withFormat format: AVAudioFormat, engine: AVAudioEngine) {
        // 检查当前输出格式是否与目标格式一致
        if let currentFormat = player.outputFormat(forBus: 0) as? AVAudioFormat, 
        currentFormat.channelCount != format.channelCount || 
        currentFormat.sampleRate != format.sampleRate {
            print("【播放】重新连接播放器 - 旧格式: \(currentFormat.channelCount)通道, 新格式: \(format.channelCount)通道")
            // 不一致则重新连接
            engine.disconnectNodeOutput(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
    }
    
    // 设置当前音效集
    func setCurrentSoundSet(_ soundSet: SoundSet) {
        Task {
            // 先加载全套音效
            // try? await loadCompleteSoundSet(soundSet)
            // 更新当前音效
            currentSoundSet = soundSet
        }
    }
    
    // 预加载所有音效的完整套装（强拍、中拍和弱拍）
    func preloadAllSoundSets(soundSets: [SoundSet]) {
        print("【预加载】开始预加载所有音效，总数: \(soundSets.count)")
        
        // 取消之前的加载任务
        loadingTask?.cancel()
        
        // 创建新的加载任务
        loadingTask = Task {
            for soundSet in soundSets {
                // 检查任务是否被取消
                if Task.isCancelled {
                    print("【预加载】任务已取消，停止加载")
                    return
                }
                
                print("【预加载】准备加载音效: \(soundSet.displayName)")
                do {
                    try await loadCompleteSoundSet(soundSet)
                    print("【预加载】音效 \(soundSet.displayName) 的全套文件加载完成")
                } catch {
                    print("【预加载错误】加载音效 \(soundSet.displayName) 失败: \(error)")
                }
            }
            print("【预加载】所有音效预加载完成，缓存大小: \(self.soundBufferCache.count)")
        }
    }
 
    // 预览音效（用于设置页面）
    func previewSoundSet(_ soundSet: SoundSet) {
        guard isInitialized, let previewPlayer = self.previewPlayer, let engine = self.audioEngine else {
            print("【预览播放】预览引擎未初始化")
            return
        }
        
        print("【预览播放】开始预览音效: \(soundSet.displayName)")
        
        // 获取强拍文件名用于预览
        let strongFileName = soundSet.getStrongBeatFileName()
        print("【预览播放】音效文件名: \(strongFileName)")
        
        // 从缓存获取音频缓冲区
        if let buffer = soundBufferCache[strongFileName] {
            print("【预览播放】从缓存获取到缓冲区 - 通道数: \(buffer.format.channelCount)")
            
            // 断开并重新连接预览播放器，使用正确的格式
            print("【预览播放】断开现有连接")
            engine.disconnectNodeOutput(previewPlayer)
            
            print("【预览播放】使用匹配的格式重新连接 - 通道数: \(buffer.format.channelCount)")
            engine.connect(previewPlayer, to: engine.mainMixerNode, format: buffer.format)
            previewPlayerFormat = buffer.format
            
            // 主线程上播放音频
            print("【预览播放】准备播放音效")
            DispatchQueue.main.async {
                print("【预览播放】主线程上调度缓冲区")
                self.previewPlayer?.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: {
                    print("【预览播放】播放完成")
                })
                print("【预览播放】开始播放")
                self.previewPlayer?.play()
            }
        } else {
            // 缓存中找不到时，异步加载并播放
            print("【预览播放】缓存中没有找到音效，尝试加载: \(strongFileName)")
            Task {
                do {
                    print("【预览播放】开始加载音效")
                    try await loadSoundFile(strongFileName, withExtension: "wav")
                    print("【预览播放】加载完成，检查缓存")
                    
                    if let buffer = soundBufferCache[strongFileName] {
                        print("【预览播放】找到新加载的缓冲区，准备播放")
                        DispatchQueue.main.async {
                            print("【预览播放】主线程上调度新加载的缓冲区")
                            self.previewPlayer?.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: {
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
    // 停止所有播放
    func stop() {
        print("【停止播放】停止所有播放器")
        playerNode?.stop()
        previewPlayer?.stop()
    }

    // 资源清理（在视图消失时调用）
    func cleanupBeforeDestroy() {
        print("【资源清理】准备清理音频资源")
        
        // 取消异步加载任务
        loadingTask?.cancel()
        loadingTask = nil
        
        // 停止播放
        stop()
        
        // 断开预览播放器连接
        if let engine = audioEngine, let previewNode = previewPlayer {
            print("【资源清理】断开预览播放器连接")
            engine.disconnectNodeOutput(previewNode)
        }
        
        // 重置预览状态，但保留缓存
        previewPlayerFormat = nil
        
        print("【资源清理】音频资源清理完成")
    }

    // 确保引擎正在运行（在播放前调用）
    func ensureEngineRunning() {
        if let engine = audioEngine, !engine.isRunning {
            print("【引擎检查】发现引擎未运行，尝试重启")
            do {
                try engine.start()
                print("【引擎检查】引擎重启成功")
            } catch {
                print("【引擎检查】引擎重启失败: \(error)")
            }
        }
    }
    
    // 设置音频中断监听
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    // 处理音频中断（如来电、其他应用播放音频等）
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            // 中断开始
            print("【音频中断】音频会话被中断")
        } else if type == .ended {
            // 中断结束
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
            AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                print("【音频中断】中断结束，尝试恢复音频引擎")
                ensureEngineRunning()
            }
        }
    }
    
    
}
