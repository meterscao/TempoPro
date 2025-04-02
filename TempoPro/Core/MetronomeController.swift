//
//  MetronomeStateController.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/1.
//
import SwiftUI

// MARK: - 控制器层
class MetronomeController: MetronomeTimerDelegate {
    // 引用状态模型
    private let state: MetronomeState
    
    // 音频引擎
    private let audioService: MetronomeAudioService
    
    // 节拍器定时器
    private var timerService: MetronomeTimerService?
    
    // 委托管理
    private var delegates = [MetronomePlaybackDelegate]()
    
    // 初始化
    init(state: MetronomeState) {
        self.state = state
        self.audioService = MetronomeAudioService.shared
        
        // 初始化音频引擎
        audioService.initialize(defaultSoundSet: state.soundSet)
        
        // 创建节拍定时器
        timerService = MetronomeTimerService(delegate: self)
        
        // 设置回调函数
        timerService?.onEnsureAudioEngineRunningNeeded = { [weak self] in
            self?.audioService.ensureEngineRunning()
        }
        
        timerService?.onPlayBeatSoundNeeded = { [weak self] status in
            self?.audioService.playBeat(status: status)
        }
        
        timerService?.onPlaySubdivisionSoundNeeded = { [weak self] timeOffset, status in
            DispatchQueue.main.async {
                self?.audioService.playBeat(status: status)
            }
        }
        
        // 设置事件通知回调
        timerService?.onBeatCompleted = { [weak self] beatIndex in
            guard let self = self else { return }
            self.state.updateCurrentBeat(beatIndex)
            let isLastBeat = beatIndex == self.state.beatsPerBar - 1
            
            // 通知委托
            self.notifyBeatCompleted(beatIndex: beatIndex, isLastBeat: isLastBeat)
        }
        
        timerService?.onBarWillComplete = { [weak self] nextBarCount in
            guard let self = self else { return }
            print("MetronomeStateController - 即将完成第\(nextBarCount)个小节，预先通知委托")
            
            // 通知委托小节即将完成事件
            self.delegates.forEach { delegate in
                if let advancedDelegate = delegate as? AdvancedMetronomePlaybackDelegate {
                    advancedDelegate.metronomeWillCompleteBar(barCount: nextBarCount)
                }
            }
        }
        
        timerService?.onBarCompleted = { [weak self] in
            guard let self = self else { return }
            self.state.incrementCompletedBar()
            print("MetronomeStateController - 完成第\(self.state.completedBars)个小节，通知所有委托")
            self.notifyBarCompleted(barCount: self.state.completedBars)
        }
    }
    
    // MARK: - 播放控制方法
    
    /// 开始播放
    func play() {
        if !state.isPlaying {
            state.updatePlaybackState(.playing)
            timerService?.start()
            
            // 通知委托播放状态变化
            notifyPlaybackStateChanged()
        }
    }
    
    /// 停止播放
    func stop() {
        if state.isPlaying {
            state.updatePlaybackState(.standby)
            timerService?.stop()
            
            // 重置状态
            state.updateCurrentBeat(0)
            state.resetCompletedBars()
            
            // 通知委托播放状态变化
            notifyPlaybackStateChanged()
        }
    }
    
    /// 暂停播放
    func pause() {
        if state.isPlaying {
            state.updatePlaybackState(.paused)
            timerService?.pause()
            
            // 通知委托播放状态变化
            notifyPlaybackStateChanged()
        }
    }
    
    /// 恢复播放
    func resume() {
        if !state.isPlaying {
            state.updatePlaybackState(.playing)
            timerService?.resume()
            
            // 通知委托播放状态变化
            notifyPlaybackStateChanged()
        }
    }
    
    // MARK: - 其他控制方法
    
    /// 更新音效集
    func updateSoundSet(_ soundSet: SoundSet) {
        // 更新音频引擎
        audioService.setCurrentSoundSet(soundSet)
    }
    
    // MARK: - 内部辅助方法
    
    /// 通知所有委托节拍完成事件
    private func notifyBeatCompleted(beatIndex: Int, isLastBeat: Bool) {
        delegates.forEach { delegate in
            delegate.metronomeDidCompleteBeat(beatIndex: beatIndex, isLastBeat: isLastBeat)
        }
    }
    
    /// 通知所有委托小节完成事件
    private func notifyBarCompleted(barCount: Int) {
        delegates.forEach { delegate in
            delegate.metronomeDidCompleteBar(barCount: barCount)
        }
    }
    
    // MARK: - MetronomeTimerDelegate 协议实现
    
    // 获取当前配置
    func getCurrentConfiguration() -> MetronomeConfiguration {
        return MetronomeConfiguration(
            tempo: state.tempo,
            beatsPerBar: state.beatsPerBar,
            currentBeat: state.currentBeat,
            beatUnit: state.beatUnit,
            beatStatuses: state.beatStatuses,
            subdivisionPattern: state.subdivisionPattern,
            soundSet: state.soundSet,
            completedBars: state.completedBars
        )
    }
    
    func isTargetBarReached(barCount: Int) -> Bool {
        if let coordinator = state.practiceCoordinator {
            return coordinator.isTargetBarReached(barCount: barCount)
        }
        return false
    }
    
    func completePractice() {
        if let coordinator = state.practiceCoordinator {
            coordinator.completePractice()
        }
    }
    
    // MARK: - 委托管理
    func addDelegate(_ delegate: MetronomePlaybackDelegate) {
        if !delegates.contains(where: { $0 === delegate }) {
            delegates.append(delegate)
        }
    }
    
    func removeDelegate(_ delegate: MetronomePlaybackDelegate) {
        delegates.removeAll(where: { $0 === delegate })
    }
    
    // MARK: - 播放控制方法
    func togglePlayback() {
        switch state.playbackState {
        case .playing:
            stop()
        case .standby, .paused:
            play()
        }
    }
    
    // MARK: - 使用切分类型更新切分模式
    func updateSubdivisionType(_ type: SubdivisionType) {
        print("MetronomeStateController - updateSubdivisionType: \(type.rawValue)")
        
        // 获取当前拍号单位下该类型的切分模式
        if let pattern = SubdivisionManager.getSubdivisionPattern(forBeatUnit: state.beatUnit, type: type) {
            state.updateSubdivisionPattern(pattern)
        }
    }
    
    // MARK: - 通知委托方法
    private func notifyPlaybackStateChanged() {
        delegates.forEach { 
            $0.metronomeDidChangePlaybackState(state.playbackState)
            // 为兼容isPlaying参数，同时通知播放状态变化
            $0.metronomePlaybackDidChangeState(isPlaying: state.isPlaying)
        }
    }
    
    // 清理资源
    func cleanup() {
        timerService?.stop()
        audioService.stop()
        delegates.removeAll()
    }
    
    // MARK: - 小节和拍子管理方法
    // 是否完成了指定数量的小节（针对练习用例）
    func hasCompletedBars(_ targetBars: Int) -> Bool {
        return state.completedBars >= targetBars
    }
    
    // 获取剩余小节数（考虑到当前正在播放的小节）
    func getRemainingBars(target: Int) -> Int {
        let current = state.currentBarNumber
        if current <= target {
            return target - current + 1 // 包括当前正在播放的小节
        } else {
            return 0
        }
    }
    
    // 获取小节占比进度（针对练习进度计算）
    func getBarProgress(targetBars: Int) -> CGFloat {
        guard targetBars > 0 else { return 0.0 }
        
        // 已完成小节数，不包括当前正在播放的小节
        let completedBarCount = state.completedBars
        return min(CGFloat(completedBarCount) / CGFloat(targetBars), 1.0)
    }
    
    // MARK: - 私有辅助方法
    private func updateCurrentSubdivisionPattern() {
        guard let currentPattern = state.subdivisionPattern else {
            setDefaultSubdivisionPattern()
            return
        }
        
        // 检查当前模式是否适用于当前拍号单位
        if currentPattern.beatUnit != state.beatUnit {
            if let newPattern = SubdivisionManager.getSubdivisionPattern(forBeatUnit: state.beatUnit, type: currentPattern.type) {
                state.updateSubdivisionPattern(newPattern)
                print("切分模式已适配当前拍号单位: \(currentPattern.type.rawValue) -> \(newPattern.name)")
            } else {
                // 如果找不到适配当前拍号单位的相同类型模式，使用默认整拍模式
                print("未找到适配当前拍号单位的\(currentPattern.type.rawValue)类型模式，使用默认模式")
                setDefaultSubdivisionPattern()
            }
        }
    }
    
    // 设置默认的切分模式
    private func setDefaultSubdivisionPattern() {
        if let pattern = SubdivisionManager.getSubdivisionPattern(forBeatUnit: state.beatUnit, type: .whole) {
            state.updateSubdivisionPattern(pattern)
        }
    }
}
