import Foundation
import UIKit

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
        
        // 停止已有定时器
        stop()
        
        // 计算开始时间
        let startTime = Date().timeIntervalSince1970
        nextBeatTime = startTime
        
        // 初始化音频引擎一次，避免反复调用
        audioEngine.ensureEngineRunning()
        
        // 播放首拍
        playCurrentBeat()
        
        // 计算下一拍时间
        nextBeatTime = startTime + (60.0 / Double(state.tempo))
        
        // 使用单一长期运行的定时器替代一次性定时器
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        // 对于高精度需求，考虑使用更短的重复间隔进行校正
        timer?.schedule(deadline: .now(), repeating: 0.01)  // 10ms检查一次
        
        timer?.setEventHandler { [weak self, weak state] in
            guard let self = self, let state = state else { return }
            
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
        state?.updateCurrentBeat(0)
        
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
        state?.updateCurrentBeat(0)
        
        // 计算开始时间
        let startTime = Date().timeIntervalSince1970
        nextBeatTime = startTime
        
        // 确保音频引擎正在运行
        audioEngine.ensureEngineRunning()
        
        // 播放当前拍
        playCurrentBeat()
        
        // 计算下一拍时间
        guard let state = state else { return }
        nextBeatTime = startTime + (60.0 / Double(state.tempo))
        
        // 创建新的定时器
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.schedule(deadline: .now(), repeating: 0.01)
        
        timer?.setEventHandler { [weak self, weak state] in
            guard let self = self, let state = state else { return }
            
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
    
    // 新方法：处理节拍，减少主线程负担
    private func handleBeat(at currentTime: TimeInterval) {
        guard let state = state else { return }
        
        // 计算偏差
        let deviation = currentTime - nextBeatTime
        
        // 取消所有切分音符定时器
        cancelSubdivisionTimers()
        isPlayingSubdivisions = false
        
        let nextBeatNumber = (state.currentBeat + 1) % state.beatsPerBar
        
        // 检测小节完成：当节拍回到第一拍(0)，且当前不是第一拍，说明完成了一个小节
        if nextBeatNumber == 0 && state.currentBeat > 0 {
            // 小节即将完成，先通知外部组件
            var shouldContinuePlaying = true
            
            // 设置一个小节完成标志，用于检查是否应该停止
            DispatchQueue.main.sync {
                print("MetronomeTimer - 检测到小节即将完成，当前拍: \(state.currentBeat), 下一拍: \(nextBeatNumber)")
                
                // 当前节拍是小节的最后一拍，即将完成一个小节
                // 计算将要完成的小节编号
                let nextBarCount = state.completedBars + 1
                
                // 调用onLastBeatOfBarCompleted触发高级通知
                state.onLastBeatOfBarCompleted()
                
                // 如果练习协调器存在，检查是否需要停止
                if let coordinator = state.practiceCoordinator,
                   coordinator.isTargetBarReached(barCount: nextBarCount) {
                    print("MetronomeTimer - 检测到达到目标小节数，取消播放下一拍")
                    shouldContinuePlaying = false
                    
                    // 直接调用completePractice而不是异步调用
                    coordinator.completePractice()
                }
                
                // 然后再调用onBarCompleted增加小节计数
                state.onBarCompleted()
            }
            
            // 如果达到目标小节，不再继续播放
            if !shouldContinuePlaying {
                print("MetronomeTimer - 已达到目标，跳过播放下一拍")
                // 仍然计算下一拍时间，但不播放
                nextBeatTime += (60.0 / Double(state.tempo))
                return
            }
        }
        
        // 只有UI更新部分需要回到主线程
        DispatchQueue.main.async {
            // 更新当前拍号（UI操作）
            state.updateCurrentBeat(nextBeatNumber)
        }
        
        // 音频播放不需要主线程
        let nextBeatStatus = nextBeatNumber < state.beatStatuses.count ? state.beatStatuses[nextBeatNumber] : .normal
        if nextBeatStatus != .muted {
            // 检查是否有切分模式
            if let subdivisionPattern = state.subdivisionPattern, subdivisionPattern.notes.count > 1 {
                // 播放切分音符
                playSubdivisionPattern(subdivisionPattern, for: nextBeatStatus)
            } else {
                // 没有切分模式，直接播放整拍
                audioEngine.playBeat(status: nextBeatStatus)
            }
        }
        
        // 计算下一拍的绝对时间（使用state中的最新tempo）
        nextBeatTime += (60.0 / Double(state.tempo))
    }
    
    // 改进切分音符播放，减少创建的定时器数量
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
        
        // 考虑使用单一定时器和预先计算的时间点数组来处理所有切分
        // 而不是为每个切分创建一个定时器
        
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
} 
