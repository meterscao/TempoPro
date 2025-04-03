import Foundation
import UIKit

// MARK: - 节拍器配置对象
/// 包含Timer所需的所有数据，避免多次调用方法获取数据
struct MyConfiguration {
    let tempo: Int
    let beatsPerBar: Int
    let currentBeat: Int
    let beatUnit: Int
    let beatStatuses: [BeatStatus]
    let subdivisionPattern: SubdivisionPattern?
    let soundSet: SoundSet
    let completedBars: Int
}

// MARK: - MetronomeTimer委托协议
/// 提供Timer所需的数据和业务逻辑判断
/// 注意：事件通知已迁移到回调函数模式，此协议仅包含数据和逻辑方法
protocol MyTimerDelegate: AnyObject {
    // 数据获取方法
    func getCurrentConfiguration() -> MyConfiguration

    // 逻辑判断方法
    func isTargetBarReached(barCount: Int) -> Bool

    // 完成练习
    func completePractice()
}

class MyTimerService {
    // MARK: - 属性
    
    // 委托对象 - 用于数据获取和逻辑判断
    private weak var delegate: MyTimerDelegate?
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: AppStorageKeys.QueueLabels.metronomeTimer, qos: .userInteractive)
    
    // 节拍计时相关的属性
    private var nextBeatTime: TimeInterval = 0
    
    // 切分音符播放相关属性
    private var subdivisionTimers: [DispatchSourceTimer] = []
    private var isPlayingSubdivisions: Bool = false
    
    // MARK: - 回调函数
    
    // 行为控制回调 - 用于请求执行操作
    /// 请求确保音频引擎正在运行
    var onEnsureAudioEngineRunningNeeded: (() -> Void)?
    /// 请求播放指定状态的节拍声音
    var onPlayBeatSoundNeeded: ((BeatStatus) -> Void)?
    /// 请求播放切分音符声音
    var onPlaySubdivisionSoundNeeded: ((TimeInterval, BeatStatus) -> Void)?
    
    // 事件通知回调 - 用于通知状态变化
    /// 通知节拍已完成，提供新的节拍索引
    var onBeatCompleted: ((Int) -> Void)?
    /// 通知小节即将完成，提供即将完成的小节编号
    var onBarWillComplete: ((Int) -> Void)?
    /// 通知小节已完成
    var onBarCompleted: (() -> Void)?
    
    // MARK: - 初始化方法
    
    /// 初始化节拍器定时器
    /// - Parameter delegate: 委托对象，用于提供数据和执行逻辑判断
    /// - Note: 完整功能需要设置回调函数和委托
    init(delegate: MyTimerDelegate? = nil) {
        self.delegate = delegate
    }
    
    /// 设置委托对象
    /// - Parameter delegate: 提供数据和逻辑判断的委托
    func setDelegate(_ delegate: MyTimerDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - 公共方法
    
    // 启动节拍器，不再需要传入状态数据
    func start() {
        // 停止已有定时器
        stop()
        
        // 计算开始时间
        let startTime = Date().timeIntervalSince1970
        nextBeatTime = startTime
        
        // 初始化音频引擎一次，避免反复调用
        onEnsureAudioEngineRunningNeeded?()
        
        // 播放首拍
        playCurrentBeat()
        
        // 计算下一拍时间
        let config = delegate?.getCurrentConfiguration()
        let tempo = config?.tempo ?? 120
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
        
        // 重置当前拍到第一拍 - 使用回调代替委托调用
        DispatchQueue.main.async {
            self.onBeatCompleted?(0)
        }
        
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
        
        // 重置当前拍到第一拍（小节的开始）- 使用回调代替委托调用
        DispatchQueue.main.async {
            self.onBeatCompleted?(0)
        }
        
        // 计算开始时间
        let startTime = Date().timeIntervalSince1970
        nextBeatTime = startTime
        
        // 确保音频引擎正在运行
        onEnsureAudioEngineRunningNeeded?()
        
        // 播放当前拍
        playCurrentBeat()
        
        // 计算下一拍时间
        let config = delegate?.getCurrentConfiguration()
        let tempo = config?.tempo ?? 120
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
        
        // 获取当前配置
        let config = delegate.getCurrentConfiguration()
        let currentBeat = config.currentBeat
        let beatStatuses = config.beatStatuses
        let beatsPerBar = config.beatsPerBar
        let beatUnit = config.beatUnit
        
        if currentBeat < beatStatuses.count {
            let status = beatStatuses[currentBeat]
            print("播放节拍 - 拍号: \(beatsPerBar)/\(beatUnit), 当前第 \(currentBeat + 1) 拍, 重音类型: \(status)")
            
            // 确保引擎运行
            onEnsureAudioEngineRunningNeeded?()
            
            // 只有非muted状态才播放
            if status != .muted {
                // 检查是否有切分模式
                if let pattern = config.subdivisionPattern, pattern.notes.count > 1 {
                    // 播放切分音符
                    playSubdivisionPattern(pattern, for: status)
                } else {
                    // 直接播放整拍
                    onPlayBeatSoundNeeded?(status)
                }
            } else {
                print("静音拍 - 跳过播放")
            }
        }
    }
    
    // 新方法：处理节拍，减少主线程负担
    private func handleBeat(at currentTime: TimeInterval) {
        guard let delegate = delegate else { return }
        
        // 获取当前配置
        let config = delegate.getCurrentConfiguration()
        
        // 获取当前状态信息
        let currentBeat = config.currentBeat
        let beatsPerBar = config.beatsPerBar
        let completedBars = config.completedBars
        
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
                
                // 通知委托小节即将完成 - 使用回调代替委托调用
                self.onBarWillComplete?(nextBarCount)
                
                // 检查是否达到目标小节数
                if self.delegate?.isTargetBarReached(barCount: nextBarCount) == true {
                    print("MetronomeTimer - 检测到达到目标小节数，取消播放下一拍")
                    shouldContinuePlaying = false
                    
                    // 完成练习 - 通过委托调用
                    self.delegate?.completePractice()
                }
                
                // 通知小节已完成 - 使用回调代替委托调用
                self.onBarCompleted?()
            }
            
            // 如果达到目标小节，不再继续播放
            if !shouldContinuePlaying {
                print("MetronomeTimer - 已达到目标，跳过播放下一拍")
                // 仍然计算下一拍时间，但不播放
                let tempo = config.tempo
                nextBeatTime += (60.0 / Double(tempo))
                return
            }
        }
        
        // 只有UI更新部分需要回到主线程
        DispatchQueue.main.async {
            // 通知当前拍更新 - 使用回调代替委托调用
            self.onBeatCompleted?(nextBeatNumber)
        }
        
        // 音频播放不需要主线程
        let beatStatuses = config.beatStatuses
        let nextBeatStatus = nextBeatNumber < beatStatuses.count ? beatStatuses[nextBeatNumber] : .normal
        if nextBeatStatus != .muted {
            // 检查是否有切分模式
            if let pattern = config.subdivisionPattern, pattern.notes.count > 1 {
                // 播放切分音符
                playSubdivisionPattern(pattern, for: nextBeatStatus)
            } else {
                // 没有切分模式，直接播放整拍
                onPlayBeatSoundNeeded?(nextBeatStatus)
            }
        }
        
        // 计算下一拍的绝对时间
        let tempo = config.tempo
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
        let config = delegate.getCurrentConfiguration()
        let tempo = config.tempo
        let beatDuration = 60.0 / Double(tempo)
        
        // 播放第一个音符（使用当前拍的强弱状态）
        if !pattern.notes.isEmpty && !pattern.notes[0].isMuted {
            onPlayBeatSoundNeeded?(beatStatus)
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
                
                // 通过回调播放切分音符
                self.onPlaySubdivisionSoundNeeded?(noteStartTime, .normal)
            }
            
            // 保存定时器并启动
            subdivisionTimers.append(timer)
            timer.resume()
        }
    }
} 
