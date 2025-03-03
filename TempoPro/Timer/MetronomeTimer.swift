import Foundation

class MetronomeTimer {
    private var timer: DispatchSourceTimer?
    private let audioEngine: MetronomeAudioEngine
    private var tempo: Int = 60
    private var beatsPerBar: Int = 4
    private var beatStatuses: [BeatStatus] = []
    private let timerQueue = DispatchQueue(label: AppStorageKeys.QueueLabels.metronomeTimer, qos: .userInteractive)
    
    var onBeatUpdate: ((Int) -> Void)?
    var currentBeat: Int = 0
    
    // 新增变量
    private var nextBeatTime: TimeInterval = 0
    private var isTempoChangedBeforeNextBeat: Bool = false
    private var beatUnit: Int = 4 // 添加拍号单位，默认为4
    
    init(audioEngine: MetronomeAudioEngine) {
        self.audioEngine = audioEngine
    }
    
    // 添加缺失的辅助方法
    private func stopTimer() {
        if let timer = timer {
            timer.cancel()
            self.timer = nil
        }
    }
    
    func start(tempo: Int, beatsPerBar: Int, beatStatuses: [BeatStatus], currentBeat: Int = 0, beatUnit: Int = 4) {
        self.tempo = tempo
        self.beatsPerBar = beatsPerBar
        self.beatStatuses = beatStatuses
        self.beatUnit = beatUnit
        
        // 仅当明确传入值或未指定时才重置当前拍
        if self.currentBeat != currentBeat {
            self.currentBeat = currentBeat
        }
        
        let startTime = Date().timeIntervalSince1970
        nextBeatTime = startTime
        print("开始节拍器 - BPM: \(tempo), 拍号: \(beatsPerBar)/\(beatUnit), 间隔: \(60.0 / Double(tempo))秒")
        print("首拍开始时间: \(startTime)")
        
        // 停止已有定时器
        stopTimer()
        
        // 播放首拍
        playCurrentBeat()
        
        // 计算下一拍的时间
        nextBeatTime = startTime + (60.0 / Double(tempo))
        
        // 创建新的定时器
        scheduleNextBeat()
    }
    
    private func scheduleNextBeat() {
        // 停止现有定时器
        if let timer = timer {
            timer.cancel()
        }
        
        // 计算到下一拍的时间间隔
        let now = Date().timeIntervalSince1970
        let timeUntilNextBeat = max(0.001, nextBeatTime - now)
        
        // 创建一次性定时器
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.schedule(deadline: .now() + timeUntilNextBeat)
        
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let currentTime = Date().timeIntervalSince1970
                let nextBeatNumber = (self.currentBeat + 1) % self.beatsPerBar
                let nextBeatStatus = nextBeatNumber < self.beatStatuses.count ? self.beatStatuses[nextBeatNumber] : .normal
                
                print("节拍更新 - 拍号: \(self.beatsPerBar)/\(self.beatUnit), 即将播放第 \(nextBeatNumber + 1) 拍, 重音类型: \(nextBeatStatus)")
                print("节拍更新 - 计划时间: \(self.nextBeatTime), 实际时间: \(currentTime), 误差: \(currentTime - self.nextBeatTime)秒")
                
                // 更新当前拍号
                self.currentBeat = nextBeatNumber
                
                // 播放当前拍
                self.playCurrentBeat()
                self.onBeatUpdate?(self.currentBeat)
                
                // 计算下一拍的绝对时间
                self.nextBeatTime += (60.0 / Double(self.tempo))
                
                // 重置 tempo 变更标志
                self.isTempoChangedBeforeNextBeat = false
                
                // 调度下一拍
                self.scheduleNextBeat()
            }
        }
        
        timer?.resume()
    }
    
    private func playCurrentBeat() {
        if currentBeat < beatStatuses.count {
            let status = beatStatuses[currentBeat]
            print("播放节拍 - 拍号: \(beatsPerBar)/\(beatUnit), 当前第 \(currentBeat + 1) 拍, 重音类型: \(status)")
            
            // 只有非muted状态才播放
            if status != .muted {
                audioEngine.playBeat(status: status)
            } else {
                print("静音拍 - 跳过播放")
            }
        }
    }

    func setTempo(tempo: Int) {
        let oldTempo = self.tempo
        self.tempo = tempo
        print("更新速度 - 旧BPM: \(oldTempo), 新BPM: \(tempo)")
        
        // 标记 tempo 已变更，但不重新调度已计划的下一拍
        isTempoChangedBeforeNextBeat = true
    }
    
    func setBeatUnit(beatUnit: Int) {
        self.beatUnit = beatUnit
        print("更新拍号单位 - 新拍号: \(beatsPerBar)/\(beatUnit)")
    }
    
    func stop() {
        if let timer = timer {
            timer.cancel()
            self.timer = nil
        }
        currentBeat = 0
        nextBeatTime = 0
    }
} 
