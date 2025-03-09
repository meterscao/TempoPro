import Foundation

class MetronomeTimer {
    // 弱引用 State，避免循环引用
    private weak var state: MetronomeState?
    private let audioEngine: MetronomeAudioEngine
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: AppStorageKeys.QueueLabels.metronomeTimer, qos: .userInteractive)
    
    // 节拍计时相关的属性
    private var nextBeatTime: TimeInterval = 0
    
    // 切分音符播放相关属性
    private var subdivisionTimers: [DispatchSourceTimer] = []
    private var isPlayingSubdivisions: Bool = false
    
    init(state: MetronomeState, audioEngine: MetronomeAudioEngine) {
        self.state = state
        self.audioEngine = audioEngine
    }
    
    // 启动节拍器，不再需要传入状态数据
    func start() {
        guard let state = state else { return }
        
        // 计算开始时间
        let startTime = Date().timeIntervalSince1970
        nextBeatTime = startTime
        
        print("开始节拍器 - BPM: \(state.tempo), 拍号: \(state.beatsPerBar)/\(state.beatUnit), 间隔: \(60.0 / Double(state.tempo))秒")
        print("首拍开始时间: \(startTime)")
        
        // 停止已有定时器
        stop()
        
        // 播放首拍
        playCurrentBeat()
        
        // 计算下一拍的时间
        nextBeatTime = startTime + (60.0 / Double(state.tempo))
        
        // 调度下一拍
        scheduleNextBeat()
    }
    
    // 停止定时器
    func stop() {
        if let timer = timer {
            timer.cancel()
            self.timer = nil
        }
        
        // 取消所有切分音符的定时器
        cancelSubdivisionTimers()
        
        // 重置当前拍到第一拍
        state?.updateCurrentBeat(0)
        
        // 重置切分播放状态
        isPlayingSubdivisions = false
    }
    
    // 取消所有切分音符的定时器
    private func cancelSubdivisionTimers() {
        for timer in subdivisionTimers {
            timer.cancel()
        }
        subdivisionTimers.removeAll()
    }
    
    // 播放当前拍
    private func playCurrentBeat() {
        guard let state = state else { return }
        
        let currentBeat = state.currentBeat
        if currentBeat < state.beatStatuses.count {
            let status = state.beatStatuses[currentBeat]
            print("播放节拍 - 拍号: \(state.beatsPerBar)/\(state.beatUnit), 当前第 \(currentBeat + 1) 拍, 重音类型: \(status)")
            
            // 确保引擎运行
            audioEngine.ensureEngineRunning()
            
            // 只有非muted状态才播放
            if status != .muted {
                // 检查是否有切分模式
                if let subdivisionPattern = state.subdivisionPattern, subdivisionPattern.notes.count > 1 {
                    // 播放切分音符
                    playSubdivisionPattern(subdivisionPattern, for: status)
                } else {
                    // 直接播放整拍
                    audioEngine.playBeat(status: status)
                }
            } else {
                print("静音拍 - 跳过播放")
            }
        }
    }
    
    // 播放切分音符模式
    private func playSubdivisionPattern(_ pattern: SubdivisionPattern, for beatStatus: BeatStatus) {
        guard let state = state else { return }
        
        // 取消任何可能正在进行的切分播放
        cancelSubdivisionTimers()
        
        // 标记当前正在播放切分
        isPlayingSubdivisions = true
        
        // 获取当前拍的总持续时间（秒）
        let beatDuration = 60.0 / Double(state.tempo)
        
        // 获取音效集
        let soundSet = state.soundSet
        
        // 播放第一个音符（使用当前拍的强弱状态）
        if !pattern.notes.isEmpty && !pattern.notes[0].isMuted {
            audioEngine.playBeat(status: beatStatus)
        }
        
        // 调度剩余的音符
        var currentTime: TimeInterval = 0
        
        for index in 1..<pattern.notes.count {
            let note = pattern.notes[index]
            
            // 跳过静音音符
            if note.isMuted {
                continue
            }
            
            // 计算该音符开始的时间
            let previousNotesLength = pattern.notes[0..<index].reduce(0.0) { $0 + $1.length }
            let noteStartTime = beatDuration * previousNotesLength
            
            // 创建定时器播放此音符
            let timer = DispatchSource.makeTimerSource(queue: timerQueue)
            timer.schedule(deadline: .now() + noteStartTime)
            timer.setEventHandler { [weak self, weak state] in
                guard let self = self, let state = state, self.isPlayingSubdivisions else { return }
                
                DispatchQueue.main.async {
                    // 对于切分音符中的后续音符，总是使用弱拍声音
                    self.audioEngine.playBeat(status: .normal)
                }
            }
            
            // 保存定时器并启动
            subdivisionTimers.append(timer)
            timer.resume()
        }
    }
    
    // 调度下一拍
    private func scheduleNextBeat() {
        guard let state = state else { return }
        
        // 计算到下一拍的时间间隔
        let now = Date().timeIntervalSince1970
        let timeUntilNextBeat = max(0.001, nextBeatTime - now)
        
        // 创建一次性定时器
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.schedule(deadline: .now() + timeUntilNextBeat)
        
        timer?.setEventHandler { [weak self, weak state] in
            guard let self = self, let state = state else { return }
            
            DispatchQueue.main.async {
                // 取消所有切分音符的定时器
                self.cancelSubdivisionTimers()
                self.isPlayingSubdivisions = false
                
                let currentTime = Date().timeIntervalSince1970
                let nextBeatNumber = (state.currentBeat + 1) % state.beatsPerBar
                let nextBeatStatus = nextBeatNumber < state.beatStatuses.count ? state.beatStatuses[nextBeatNumber] : .normal
                
                print("节拍更新 - 拍号: \(state.beatsPerBar)/\(state.beatUnit), 即将播放第 \(nextBeatNumber + 1) 拍, 重音类型: \(nextBeatStatus)")
                print("节拍更新 - 计划时间: \(self.nextBeatTime), 实际时间: \(currentTime), 误差: \(currentTime - self.nextBeatTime)秒")
                
                // 更新当前拍号
                state.updateCurrentBeat(nextBeatNumber) 
                
                // 播放当前拍
                self.playCurrentBeat()
                
                // 计算下一拍的绝对时间（使用state中的最新tempo）
                self.nextBeatTime += (60.0 / Double(state.tempo))
                
                // 调度下一拍
                self.scheduleNextBeat()
            }
        }
        
        timer?.resume()
    }
} 
