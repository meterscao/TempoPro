import Foundation

class MetronomeTimer {
    private var timer: Timer?
    private let audioEngine: MetronomeAudioEngine
    private var tempo: Double = 60.0
    private var interval: TimeInterval = 1.0
    private var beatsPerBar: Int = 4
    private var beatStatuses: [BeatStatus] = []
    
    var onBeatUpdate: ((Int) -> Void)?
    var currentBeat: Int = 0
    
    init(audioEngine: MetronomeAudioEngine) {
        self.audioEngine = audioEngine
    }
    
    func start(tempo: Double, beatsPerBar: Int, beatStatuses: [BeatStatus]) {
        self.tempo = tempo
        self.interval = 60.0 / tempo
        self.beatsPerBar = beatsPerBar
        self.beatStatuses = beatStatuses
        
        print("开始节拍器 - BPM: \(tempo), 间隔: \(interval)秒")
        currentBeat = 0
        
        let startTime = Date().timeIntervalSince1970
        print("首拍开始时间: \(startTime)")
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.playCurrentBeat()
            
            self.timer = Timer.scheduledTimer(withTimeInterval: self.interval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    let beatTime = Date().timeIntervalSince1970
                    let timeSinceStart = beatTime - startTime
                    
                    self.currentBeat = (self.currentBeat + 1) % self.beatsPerBar
                    print("节拍更新 - 时间: \(beatTime), 距离开始: \(timeSinceStart)秒, 当前拍号: \(self.currentBeat)")
                    
                    self.playCurrentBeat()
                    self.onBeatUpdate?(self.currentBeat)
                }
            }
            
            RunLoop.current.add(self.timer!, forMode: .common)
            RunLoop.current.run()
        }
    }
    
    private func playCurrentBeat() {
        if currentBeat < beatStatuses.count {
            audioEngine.playBeat(status: beatStatuses[currentBeat])
        }
    }

    func updateTempo(tempo: Double, currentTime: TimeInterval, nextBeatTime: TimeInterval) {
        self.tempo = tempo
        self.interval = 60.0 / tempo
        
        // 取消当前的定时器
        timer?.invalidate()
        
        // 计算到下一拍的剩余时间
        let remainingTime = max(0.01, nextBeatTime - currentTime)
        
        // 使用新的间隔创建定时器，但第一次触发使用剩余时间
        timer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.currentBeat = (self.currentBeat + 1) % self.beatsPerBar
                self.playCurrentBeat()
                self.onBeatUpdate?(self.currentBeat)
                self.startRegularTimer()
            }
        }
        
        // 确保定时器在正确的线程上运行
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func startRegularTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.currentBeat = (self.currentBeat + 1) % self.beatsPerBar
                self.playCurrentBeat()
                self.onBeatUpdate?(self.currentBeat)
            }
        }
        
        // 确保定时器在正确的线程上运行
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        currentBeat = 0
    }
} 