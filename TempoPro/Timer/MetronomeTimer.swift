import Foundation
import UIKit

// MARK: - MetronomeTimer委托协议
protocol MetronomeTimerDelegate: AnyObject {
    // 当节拍完成时调用
    func timerDidCompleteBeat(beatIndex: Int)
    
    // 当小节的最后一拍完成时调用（在增加小节计数前）
    func timerWillCompleteBar(nextBarCount: Int)
    
    // 当小节完成时调用
    func timerDidCompleteBar()
    
    // 获取当前tempo
    func getCurrentTempo() -> Int
    
    // 获取拍子数量
    func getBeatsPerBar() -> Int
    
    // 获取当前拍号
    func getCurrentBeat() -> Int
    
    // 获取拍号单位
    func getBeatUnit() -> Int
    
    // 获取节拍状态
    func getBeatStatuses() -> [BeatStatus]
    
    // 获取当前切分模式
    func getSubdivisionPattern() -> SubdivisionPattern?
    
    // 获取当前音效集
    func getSoundSet() -> SoundSet
    
    // 获取已完成小节数
    func getCompletedBars() -> Int
    
    // 检查是否达到目标小节数
    func isTargetBarReached(barCount: Int) -> Bool
    
    // 完成练习
    func completePractice()
    
    // 音频相关委托方法
    
    // 确保音频引擎正在运行
    func ensureAudioEngineRunning()
    
    // 播放指定状态的拍子声音
    func playBeatSound(status: BeatStatus)
    
    // 播放切分音符声音
    func playSubdivisionSound(atTimeOffset timeOffset: TimeInterval, withStatus status: BeatStatus)
}

class MetronomeTimer {
    // 委托对象
    private weak var delegate: MetronomeTimerDelegate?
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: AppStorageKeys.QueueLabels.metronomeTimer, qos: .userInteractive)
    
    // 节拍计时相关的属性
    private var nextBeatTime: TimeInterval = 0
    
    // 切分音符播放相关属性
    private var subdivisionTimers: [DispatchSourceTimer] = []
    private var isPlayingSubdivisions: Bool = false
    
    init(delegate: MetronomeTimerDelegate? = nil) {
        self.delegate = delegate
    }
    
    // 设置委托
    func setDelegate(_ delegate: MetronomeTimerDelegate) {
        self.delegate = delegate
    }
    
    // 启动节拍器，不再需要传入状态数据
    func start() {
        // 停止已有定时器
        stop()
        
        // 计算开始时间
        let startTime = Date().timeIntervalSince1970
        nextBeatTime = startTime
        
        // 初始化音频引擎一次，避免反复调用
        delegate?.ensureAudioEngineRunning()
        
        // 播放首拍
        playCurrentBeat()
        
        // 计算下一拍时间
        let tempo = delegate?.getCurrentTempo() ?? 120
        nextBeatTime = startTime + (60.0 / Double(tempo))
        
        // 使用单一长期运行的定时器替代一次性定时器
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        // 对于高精度需求，考虑使用更短的重复间隔进行校正
        timer?.schedule(deadline: .now(), repeating: 0.01)  // 10ms检查一次
        
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            let now = Date().timeIntervalSince1970
            // 只有当到达下一拍时间才执行
            if now >= self.nextBeatTime {
                // 关键改进：不必每次都回到主线程，只在必要时更新UI
                self.handleBeat(at: now)
            }
        }
        
        timer?.resume()
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
        delegate?.timerDidCompleteBeat(beatIndex: 0)
        
        // 重置切分播放状态
        isPlayingSubdivisions = false
    }
    
    // 暂停定时器 - 保留当前状态
    func pause() {
        if let timer = timer {
            timer.cancel()
            self.timer = nil
        }
        
        // 取消所有切分音符的定时器
        cancelSubdivisionTimers()
        
        // 不重置当前拍，保留当前小节状态
        // 不重置isPlayingSubdivisions标志
    }
    
    // 恢复定时器 - 从当前小节的第一拍开始
    func resume() {
        // 确保当前没有正在运行的定时器
        if timer != nil {
            timer?.cancel()
            timer = nil
        }
        
        // 重置当前拍到第一拍（小节的开始）
        delegate?.timerDidCompleteBeat(beatIndex: 0)
        
        // 计算开始时间
        let startTime = Date().timeIntervalSince1970
        nextBeatTime = startTime
        
        // 确保音频引擎正在运行
        delegate?.ensureAudioEngineRunning()
        
        // 播放当前拍
        playCurrentBeat()
        
        // 计算下一拍时间
        let tempo = delegate?.getCurrentTempo() ?? 120
        nextBeatTime = startTime + (60.0 / Double(tempo))
        
        // 创建新的定时器
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.schedule(deadline: .now(), repeating: 0.01)
        
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            let now = Date().timeIntervalSince1970
            if now >= self.nextBeatTime {
                self.handleBeat(at: now)
            }
        }
        
        timer?.resume()
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
        guard let delegate = delegate else { return }
        
        let currentBeat = delegate.getCurrentBeat()
        let beatStatuses = delegate.getBeatStatuses()
        let beatsPerBar = delegate.getBeatsPerBar()
        let beatUnit = delegate.getBeatUnit()
        
        if currentBeat < beatStatuses.count {
            let status = beatStatuses[currentBeat]
            print("播放节拍 - 拍号: \(beatsPerBar)/\(beatUnit), 当前第 \(currentBeat + 1) 拍, 重音类型: \(status)")
            
            // 确保引擎运行
            delegate.ensureAudioEngineRunning()
            
            // 只有非muted状态才播放
            if status != .muted {
                // 检查是否有切分模式
                if let pattern = delegate.getSubdivisionPattern(), pattern.notes.count > 1 {
                    // 播放切分音符
                    playSubdivisionPattern(pattern, for: status)
                } else {
                    // 直接播放整拍
                    delegate.playBeatSound(status: status)
                }
            } else {
                print("静音拍 - 跳过播放")
            }
        }
    }
    
    // 新方法：处理节拍，减少主线程负担
    private func handleBeat(at currentTime: TimeInterval) {
        guard let delegate = delegate else { return }
        
        // 获取当前状态信息
        let currentBeat = delegate.getCurrentBeat()
        let beatsPerBar = delegate.getBeatsPerBar()
        let completedBars = delegate.getCompletedBars()
        
        // 计算偏差
        let deviation = currentTime - nextBeatTime
        
        // 取消所有切分音符定时器
        cancelSubdivisionTimers()
        isPlayingSubdivisions = false
        
        let nextBeatNumber = (currentBeat + 1) % beatsPerBar
        
        // 检测小节完成：当节拍回到第一拍(0)，且当前不是第一拍，说明完成了一个小节
        if nextBeatNumber == 0 && currentBeat > 0 {
            // 小节即将完成，先通知外部组件
            var shouldContinuePlaying = true
            
            // 设置一个小节完成标志，用于检查是否应该停止
            DispatchQueue.main.sync {
                print("MetronomeTimer - 检测到小节即将完成，当前拍: \(currentBeat), 下一拍: \(nextBeatNumber)")
                
                // 当前节拍是小节的最后一拍，即将完成一个小节
                // 计算将要完成的小节编号
                let nextBarCount = completedBars + 1
                
                // 通知委托小节即将完成
                self.delegate?.timerWillCompleteBar(nextBarCount: nextBarCount)
                
                // 检查是否达到目标小节数
                if self.delegate?.isTargetBarReached(barCount: nextBarCount) == true {
                    print("MetronomeTimer - 检测到达到目标小节数，取消播放下一拍")
                    shouldContinuePlaying = false
                    
                    // 完成练习 - 通过委托调用
                    self.delegate?.completePractice()
                }
                
                // 通知小节已完成
                self.delegate?.timerDidCompleteBar()
            }
            
            // 如果达到目标小节，不再继续播放
            if !shouldContinuePlaying {
                print("MetronomeTimer - 已达到目标，跳过播放下一拍")
                // 仍然计算下一拍时间，但不播放
                let tempo = delegate.getCurrentTempo()
                nextBeatTime += (60.0 / Double(tempo))
                return
            }
        }
        
        // 只有UI更新部分需要回到主线程
        DispatchQueue.main.async {
            // 通知当前拍更新
            self.delegate?.timerDidCompleteBeat(beatIndex: nextBeatNumber)
        }
        
        // 音频播放不需要主线程
        let beatStatuses = delegate.getBeatStatuses()
        let nextBeatStatus = nextBeatNumber < beatStatuses.count ? beatStatuses[nextBeatNumber] : .normal
        if nextBeatStatus != .muted {
            // 检查是否有切分模式
            if let pattern = delegate.getSubdivisionPattern(), pattern.notes.count > 1 {
                // 播放切分音符
                playSubdivisionPattern(pattern, for: nextBeatStatus)
            } else {
                // 没有切分模式，直接播放整拍
                delegate.playBeatSound(status: nextBeatStatus)
            }
        }
        
        // 计算下一拍的绝对时间
        let tempo = delegate.getCurrentTempo()
        nextBeatTime += (60.0 / Double(tempo))
    }
    
    // 改进切分音符播放，减少创建的定时器数量
    private func playSubdivisionPattern(_ pattern: SubdivisionPattern, for beatStatus: BeatStatus) {
        guard let delegate = delegate else { return }
        
        // 取消任何可能正在进行的切分播放
        cancelSubdivisionTimers()
        
        // 标记当前正在播放切分
        isPlayingSubdivisions = true
        
        // 获取当前拍的总持续时间（秒）
        let tempo = delegate.getCurrentTempo()
        let beatDuration = 60.0 / Double(tempo)
        
        // 播放第一个音符（使用当前拍的强弱状态）
        if !pattern.notes.isEmpty && !pattern.notes[0].isMuted {
            delegate.playBeatSound(status: beatStatus)
        }
        
        // 调度剩余的音符
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
            timer.setEventHandler { [weak self] in
                guard let self = self, self.isPlayingSubdivisions else { return }
                
                // 通过委托播放切分音符
                self.delegate?.playSubdivisionSound(atTimeOffset: noteStartTime, withStatus: .normal)
            }
            
            // 保存定时器并启动
            subdivisionTimers.append(timer)
            timer.resume()
        }
    }
} 
