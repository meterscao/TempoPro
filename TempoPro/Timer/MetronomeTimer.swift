import Foundation

class MetronomeTimer {
    private var timer: Timer?
    private let audioEngine: MetronomeAudioEngine
    
    var onBeatUpdate: ((Int) -> Void)?
    var currentBeat: Int = 0
    
    init(audioEngine: MetronomeAudioEngine) {
        self.audioEngine = audioEngine
    }
    
    func start(tempo: Double, beatsPerBar: Int, beatStatuses: [BeatStatus]) {
        let interval = 60.0 / tempo
        print("开始节拍器 - BPM: \(tempo), 间隔: \(interval)秒")
        currentBeat = 0
        
        let startTime = Date().timeIntervalSince1970
        print("首拍开始时间: \(startTime)")
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.audioEngine.playBeat(status: beatStatuses[self.currentBeat])
            
            self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    let beatTime = Date().timeIntervalSince1970
                    let timeSinceStart = beatTime - startTime
                    
                    self.currentBeat = (self.currentBeat + 1) % beatsPerBar
                    print("节拍更新 - 时间: \(beatTime), 距离开始: \(timeSinceStart)秒, 当前拍号: \(self.currentBeat)")
                    
                    self.audioEngine.playBeat(status: beatStatuses[self.currentBeat])
                    self.onBeatUpdate?(self.currentBeat)
                }
            }
            
            RunLoop.current.add(self.timer!, forMode: .common)
            RunLoop.current.run()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        currentBeat = 0
    }
} 