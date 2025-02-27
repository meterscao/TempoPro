import Foundation

class MetronomeTimer {
    private var timer: DispatchSourceTimer?
    private let audioEngine: MetronomeAudioEngine
    private var tempo: Double = 60.0
    private var interval: TimeInterval = 1.0
    private var beatsPerBar: Int = 4
    private var beatStatuses: [BeatStatus] = []
    private let timerQueue = DispatchQueue(label: "com.tempopro.metronome.timer", qos: .userInteractive)
    
    var onBeatUpdate: ((Int) -> Void)?
    var currentBeat: Int = 0
    private var lastBeatTime: TimeInterval = 0
    
    init(audioEngine: MetronomeAudioEngine) {
        self.audioEngine = audioEngine
    }
    
    func start(tempo: Double, beatsPerBar: Int, beatStatuses: [BeatStatus], currentBeat: Int = 0) {
        self.tempo = tempo
        self.interval = 60.0 / tempo
        self.beatsPerBar = beatsPerBar
        self.beatStatuses = beatStatuses
        
        // 仅当明确传入值或未指定时才重置当前拍
        if self.currentBeat != currentBeat {
            self.currentBeat = currentBeat
        }
        
        let startTime = Date().timeIntervalSince1970
        lastBeatTime = startTime
        print("开始节拍器 - BPM: \(tempo), 间隔: \(interval)秒")
        print("首拍开始时间: \(startTime)")
        
        // 停止已有定时器
        stopTimer()
        
        // 播放首拍
        playCurrentBeat()
        
        // 创建新的定时器
        createAndStartTimer()
    }
    
    private func createAndStartTimer() {
        // 在专用队列中创建定时器
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.schedule(deadline: .now() + interval, repeating: interval)
        
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let beatTime = Date().timeIntervalSince1970
                let timeSinceLastBeat = beatTime - self.lastBeatTime
                self.lastBeatTime = beatTime
                
                self.currentBeat = (self.currentBeat + 1) % self.beatsPerBar
                print("节拍更新 - 时间: \(beatTime), 距离上次: \(timeSinceLastBeat)秒, 当前拍号: \(self.currentBeat)")
                
                self.playCurrentBeat()
                self.onBeatUpdate?(self.currentBeat)
            }
        }
        
        timer?.resume()
    }
    
    private func stopTimer() {
        if let timer = timer {
            timer.cancel()
            self.timer = nil
        }
    }
    
    private func playCurrentBeat() {
        if currentBeat < beatStatuses.count {
            audioEngine.playBeat(status: beatStatuses[currentBeat])
        }
    }

    func setTempo(tempo: Double) {
        self.tempo = tempo
        self.interval = 60.0 / tempo
        print("更新速度 - 新BPM: \(tempo), 新间隔: \(interval)秒")
        
        // 重新创建定时器以应用新的间隔
        if timer != nil {
            stopTimer()
            createAndStartTimer()
        }
    }
    
    func stop() {
        stopTimer()
        currentBeat = 0
    }
} 