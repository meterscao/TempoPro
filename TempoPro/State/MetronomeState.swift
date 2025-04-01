import Foundation
import Combine
import SwiftUI

// MARK: - 架构说明
// 该文件实现了节拍器的核心状态管理和事件分发
// 架构改进 (2025/04):
// 1. 引入了高级委托协议(AdvancedMetronomePlaybackDelegate)，增强事件系统精确度
// 2. 添加了小节完成前的预通知机制，使外部组件可以更精确地控制流程
// 3. 保持了向后兼容性，不破坏现有组件的功能
// 4. 优化了事件传递流程，使节拍完成和小节计数的时机更加合理
// 架构改进 (2025/06):
// 1. 拆分数据模型和控制层，将MetronomeState重构为纯数据模型
// 2. 创建MetronomeStateController作为控制层，处理事件分发和业务逻辑
// 3. 保持向下兼容性，不破坏现有功能

// 添加播放状态枚举
enum PlaybackState {
    case standby   // 默认状态/停止状态
    case playing   // 正在播放
    case paused    // 暂停状态
}

// 节拍器播放委托协议 - 用于通知外部组件
protocol MetronomePlaybackDelegate: AnyObject {
    func metronomeDidChangePlaybackState(_ state: PlaybackState)
    func metronomeDidCompleteBeat(beatIndex: Int, isLastBeat: Bool)
    func metronomeDidCompleteBar(barCount: Int)
}

// 高级节拍器播放委托协议 - 用于更精确的节拍控制和预先通知
protocol AdvancedMetronomePlaybackDelegate: MetronomePlaybackDelegate {
    // 小节即将完成事件（当最后一拍完成时触发，在实际增加小节计数之前）
    func metronomeWillCompleteBar(barCount: Int)
}

// MARK: - 纯数据模型
class MetronomeState: ObservableObject {
    // MARK: - 定义引用的键
    private enum Keys {
        static let tempo = AppStorageKeys.Metronome.tempo
        static let beatsPerBar = AppStorageKeys.Metronome.beatsPerBar
        static let beatUnit = AppStorageKeys.Metronome.beatUnit
        static let beatStatuses = AppStorageKeys.Metronome.beatStatuses
        static let currentBeat = AppStorageKeys.Metronome.currentBeat
        static let subdivisionType = AppStorageKeys.Metronome.subdivisionType
        static let soundSet = AppStorageKeys.Metronome.soundSet  // 音效集设置的键
    }
    
    // MARK: - 公开状态属性
    @Published private(set) var playbackState: PlaybackState = .standby
    @Published private(set) var currentBeat: Int = 0
    @Published private(set) var tempo: Int = 120
    @Published private(set) var beatsPerBar: Int = 4
    @Published private(set) var beatUnit: Int = 4
    @Published private(set) var beatStatuses: [BeatStatus] = []
    @Published private(set) var subdivisionPattern: SubdivisionPattern?
    @Published private(set) var soundSet: SoundSet = SoundSetManager.getDefaultSoundSet()
    @Published private(set) var completedBars: Int = 0
    
    // CoreData练习管理器 - 用于数据持久化
    @Published var practiceManager: CoreDataPracticeManager?
    
    // 练习协调器 - 用于协调节拍器与练习模式交互
    @Published var practiceCoordinator: PracticeCoordinator?
    
    // MARK: - 便捷计算属性
    // 添加便捷计算属性以保持向后兼容
    var isPlaying: Bool { return playbackState == .playing }
    var isPaused: Bool { return playbackState == .paused }
    
    // 获取当前正在播放的小节编号（从1开始计数）
    var currentBarNumber: Int { return completedBars + 1 }
    
    // 获取当前小节在当前拍子的进度（0.0-1.0）
    var currentBeatProgress: CGFloat {
        guard beatsPerBar > 0 else { return 0.0 }
        return CGFloat(currentBeat) / CGFloat(beatsPerBar)
    }
    
    // 检查是否在小节的最后一拍
    var isLastBeatOfBar: Bool { return currentBeat == beatsPerBar - 1 }
    
    // MARK: - 私有属性
    // 添加订阅管理
    private var cancellables = Set<AnyCancellable>()
    private let defaults = UserDefaults.standard
    
    // 获取当前切分模式的类型（兼容现有代码）
    var subdivisionType: SubdivisionType {
        return subdivisionPattern?.type ?? .whole
    }
    
    // MARK: - 初始化
    init() {
        // 从UserDefaults加载初始数据
        loadFromUserDefaults()
    }
    
    // MARK: - 状态更新方法（由控制器调用）
    func updatePlaybackState(_ newState: PlaybackState) {
        playbackState = newState
        objectWillChange.send()
    }
    
    func updateCurrentBeat(_ newCurrentBeat: Int) {
        currentBeat = newCurrentBeat
        defaults.set(currentBeat, forKey: Keys.currentBeat)
    }
    
    func updateTempo(_ newTempo: Int) {
        let clampedTempo = max(30, min(240, newTempo))
        if tempo != clampedTempo {
            tempo = clampedTempo
            defaults.set(tempo, forKey: Keys.tempo)
        }
    }
    
    func updateBeatsPerBar(_ newBeatsPerBar: Int) {
        if beatsPerBar == newBeatsPerBar { return }
        
        // 创建新的节拍状态数组
        var newBeatStatuses = Array(repeating: BeatStatus.normal, count: newBeatsPerBar)
        
        // 复制现有节拍状态
        for i in 0..<min(beatStatuses.count, newBeatsPerBar) {
            newBeatStatuses[i] = beatStatuses[i]
        }
        
        // 更新状态
        beatStatuses = newBeatStatuses
        beatsPerBar = newBeatsPerBar
        
        // 保存到UserDefaults
        defaults.set(beatsPerBar, forKey: Keys.beatsPerBar)
        saveBeatStatuses()
    }
    
    func updateBeatUnit(_ newBeatUnit: Int) {
        if beatUnit == newBeatUnit { return }
        
        beatUnit = newBeatUnit
        defaults.set(beatUnit, forKey: Keys.beatUnit)
    }
    
    func updateBeatStatuses(_ newStatuses: [BeatStatus]) {
        beatStatuses = newStatuses
        saveBeatStatuses()
    }
    
    func updateSubdivisionPattern(_ pattern: SubdivisionPattern) {
        guard pattern.name != subdivisionPattern?.name else { return }
        
        // 更新当前模式
        subdivisionPattern = pattern
        
        // 保存模式名称到 UserDefaults
        defaults.set(pattern.name, forKey: Keys.subdivisionType)
    }
    
    // 重命名为内部方法，只处理数据更新
    func _updateSoundSetData(_ newSoundSet: SoundSet) {
        guard newSoundSet.key != soundSet.key else { return }
        
        // 更新当前音效集
        soundSet = newSoundSet
        
        // 保存设置到UserDefaults
        defaults.set(newSoundSet.key, forKey: Keys.soundSet)
    }
    
    func incrementCompletedBar() {
        completedBars += 1
        objectWillChange.send()
    }
    
    func resetCompletedBars() {
        if completedBars != 0 {
            completedBars = 0
            objectWillChange.send()
        }
    }
    
    // MARK: - 私有辅助方法
    private func loadFromUserDefaults() {
        // 读取速度值
        tempo = defaults.integer(forKey: Keys.tempo).nonZeroOr(120)
        
        // 读取拍号设置
        beatsPerBar = defaults.integer(forKey: Keys.beatsPerBar).nonZeroOr(4)
        beatUnit = defaults.integer(forKey: Keys.beatUnit).nonZeroOr(4)
        
        // 加载节拍状态
        loadBeatStatuses()
        
        // 加载切分音符模式
        loadSubdivisionPattern()
        
        // 加载音效设置
        loadSoundSet()
    }
    
    private func loadBeatStatuses() {
        // 精简的节拍状态加载逻辑
        if let savedStatusInts = defaults.array(forKey: Keys.beatStatuses) as? [Int] {
            self.beatStatuses = savedStatusInts.map { BeatStatus(rawValue: $0) ?? .normal }
        } else {
            initializeDefaultBeatStatuses()
        }
    }
    
    private func initializeDefaultBeatStatuses() {
        // 初始化默认节拍状态
        beatStatuses = Array(repeating: .normal, count: beatsPerBar)
        beatStatuses[0] = .strong
        if beatsPerBar > 2 {
            beatStatuses[2] = .medium
        }
        saveBeatStatuses()
    }
    
    private func loadSubdivisionPattern() {
        if let savedPatternName = defaults.string(forKey: Keys.subdivisionType),
           let pattern = SubdivisionManager.getSubdivisionPattern(byName: savedPatternName) {
            subdivisionPattern = pattern
        } else {
            setDefaultSubdivisionPattern()
        }
    }
    
    private func loadSoundSet() {
        // 加载音效设置
        if let savedSoundSetKey = defaults.string(forKey: Keys.soundSet),
           let savedSoundSet = SoundSetManager.availableSoundSets.first(where: { $0.key == savedSoundSetKey }) {
            soundSet = savedSoundSet
        } else {
            soundSet = SoundSetManager.getDefaultSoundSet()
        }
    }
    
    private func saveBeatStatuses() {
        let statusInts = beatStatuses.map { $0.rawValue }
        defaults.set(statusInts, forKey: Keys.beatStatuses)
    }
    
    // 设置默认的切分模式
    private func setDefaultSubdivisionPattern() {
        if let pattern = SubdivisionManager.getSubdivisionPattern(forBeatUnit: beatUnit, type: .whole) {
            subdivisionPattern = pattern
            defaults.set(pattern.name, forKey: Keys.subdivisionType)
        }
    }
}

// MARK: - 控制器层
class MetronomeStateController {
    // 引用状态模型
    private let state: MetronomeState
    
    // 音频引擎
    private let audioEngine: MetronomeAudioEngine
    
    // 节拍器定时器
    private var metronomeTimer: MetronomeTimer?
    
    // 委托管理
    private var delegates = [MetronomePlaybackDelegate]()
    
    // 初始化
    init(state: MetronomeState) {
        self.state = state
        self.audioEngine = MetronomeAudioEngine.shared
        
        // 初始化音频引擎
        audioEngine.initialize(defaultSoundSet: state.soundSet)
        
        // 创建节拍定时器
        metronomeTimer = MetronomeTimer(state: state, audioEngine: audioEngine)
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

    func play() {
        print("MetronomeStateController - play")
        
        state.updatePlaybackState(.playing)
        state.resetCompletedBars() // 重置小节计数
        
        // 确保当前切分模式已更新
        updateCurrentSubdivisionPattern()
        
        // 开始练习会话 - 数据保存
        state.practiceManager?.startPracticeSession(bpm: state.tempo)
        
        // 直接启动定时器
        metronomeTimer?.start()
        
        // 通知状态变化
        notifyPlaybackStateChanged()
    }   

    func stop() {
        print("MetronomeStateController - stop")
        
        state.updatePlaybackState(.standby)
        
        // 结束练习会话 - 数据保存
        state.practiceManager?.endPracticeSession()
        
        // 停止定时器
        metronomeTimer?.stop()
        
        // 通知状态变化
        notifyPlaybackStateChanged()
    }   
    
    // 暂停节拍器 - 保留当前的小节计数和状态
    func pause() {
        print("MetronomeStateController - pause")
        
        if state.playbackState != .playing {
            return // 如果没有在播放，则不需要暂停
        }
        
        state.updatePlaybackState(.paused)
        
        // 暂停定时器
        metronomeTimer?.pause()
        
        // 通知观察者状态变化
        notifyPlaybackStateChanged()
    }
    
    // 恢复节拍器 - 从当前小节的第一拍开始
    func resume() {
        print("MetronomeStateController - resume")
        
        if state.playbackState == .playing {
            return // 如果已经在播放，则不需要恢复
        }
        
        state.updatePlaybackState(.playing)
        // 重置当前拍回到第一拍（小节的开始）
        state.updateCurrentBeat(0)
        
        // 恢复定时器
        metronomeTimer?.resume()
        
        // 通知观察者状态变化
        notifyPlaybackStateChanged()
    }
    
    // 使用切分类型更新切分模式
    func updateSubdivisionType(_ type: SubdivisionType) {
        print("MetronomeStateController - updateSubdivisionType: \(type.rawValue)")
        
        // 获取当前拍号单位下该类型的切分模式
        if let pattern = SubdivisionManager.getSubdivisionPattern(forBeatUnit: state.beatUnit, type: type) {
            state.updateSubdivisionPattern(pattern)
        }
    }
    
    // 更新音效设置
    func updateSoundSet(_ newSoundSet: SoundSet) {
        print("MetronomeStateController - updateSoundSet: \(state.soundSet.key) -> \(newSoundSet.key)")
        
        // 更新数据模型
        state._updateSoundSetData(newSoundSet)
        
        // 更新音频引擎的当前音效
        audioEngine.setCurrentSoundSet(newSoundSet)
        
        print("音效已更新为: \(newSoundSet.displayName)")
    }
    
    // MARK: - 内部调用方法 (timer可以调用)
    func onBeatCompleted(beatIndex: Int) {
        state.updateCurrentBeat(beatIndex)
        let isLastBeat = beatIndex == state.beatsPerBar - 1
        
        // 通知委托
        notifyBeatCompleted(beatIndex: beatIndex, isLastBeat: isLastBeat)
        
        // 如果是最后一拍，调用特殊处理方法
        if isLastBeat {
            onLastBeatOfBarCompleted()
        }
    }
    
    // 最后一拍完成时调用 - 用于在小节真正完成前发出通知
    func onLastBeatOfBarCompleted() {
        // 下一个小节将要是第几个小节
        let nextBarCount = state.completedBars + 1
        
        print("MetronomeStateController - 即将完成第\(nextBarCount)个小节，预先通知委托")
        
        // 通知委托小节即将完成事件
        delegates.forEach { delegate in
            if let advancedDelegate = delegate as? AdvancedMetronomePlaybackDelegate {
                advancedDelegate.metronomeWillCompleteBar(barCount: nextBarCount)
            }
        }
    }
    
    func onBarCompleted() {
        state.incrementCompletedBar()
        print("MetronomeStateController - 完成第\(state.completedBars)个小节，通知所有委托")
        notifyBarCompleted(barCount: state.completedBars)
    }
    
    // MARK: - 通知委托方法
    private func notifyPlaybackStateChanged() {
        delegates.forEach { $0.metronomeDidChangePlaybackState(state.playbackState) }
    }
    
    private func notifyBeatCompleted(beatIndex: Int, isLastBeat: Bool) {
        delegates.forEach { $0.metronomeDidCompleteBeat(beatIndex: beatIndex, isLastBeat: isLastBeat) }
    }
    
    private func notifyBarCompleted(barCount: Int) {
        delegates.forEach { $0.metronomeDidCompleteBar(barCount: barCount) }
    }
    
    // 清理资源
    func cleanup() {
        metronomeTimer?.stop()
        audioEngine.stop()
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

// MARK: - 为保持向下兼容的扩展 
// 这个扩展把控制器的方法直接暴露在状态模型上，使现有代码不需要修改
extension MetronomeState {
    // 延迟初始化控制器，确保只在需要时创建
    private static var controllersMap = [ObjectIdentifier: MetronomeStateController]()
    
    private var controller: MetronomeStateController {
        let id = ObjectIdentifier(self)
        if let existingController = MetronomeState.controllersMap[id] {
            return existingController
        } else {
            let newController = MetronomeStateController(state: self)
            MetronomeState.controllersMap[id] = newController
            return newController
        }
    }
    
    // 原先直接实现在MetronomeState中的方法，现在委托给控制器
    func togglePlayback() {
        controller.togglePlayback()
    }
    
    func play() {
        controller.play()
    }
    
    func stop() {
        controller.stop()
    }
    
    func pause() {
        controller.pause()
    }
    
    func resume() {
        controller.resume()
    }
    
    func updateSubdivisionType(_ type: SubdivisionType) {
        controller.updateSubdivisionType(type)
    }
    
    func updateSoundSet(_ newSoundSet: SoundSet) {
        // 内部数据更新
        _updateSoundSetData(newSoundSet)
        // 控制器处理音频引擎更新
        controller.updateSoundSet(newSoundSet)
    }
    
    func cleanup() {
        controller.cleanup()
        let id = ObjectIdentifier(self)
        MetronomeState.controllersMap.removeValue(forKey: id)
    }
    
    func addDelegate(_ delegate: MetronomePlaybackDelegate) {
        controller.addDelegate(delegate)
    }
    
    func removeDelegate(_ delegate: MetronomePlaybackDelegate) {
        controller.removeDelegate(delegate)
    }
    
    // 这些方法以前在MetronomeState中，现在从Controller中获取
    func onBeatCompleted(beatIndex: Int) {
        controller.onBeatCompleted(beatIndex: beatIndex)
    }
    
    func onLastBeatOfBarCompleted() {
        controller.onLastBeatOfBarCompleted()
    }
    
    func onBarCompleted() {
        controller.onBarCompleted()
    }
    
    func hasCompletedBars(_ targetBars: Int) -> Bool {
        return controller.hasCompletedBars(targetBars)
    }
    
    func getRemainingBars(target: Int) -> Int {
        return controller.getRemainingBars(target: target)
    }
    
    func getBarProgress(targetBars: Int) -> CGFloat {
        return controller.getBarProgress(targetBars: targetBars)
    }
}

// 辅助扩展
extension Int {
    fileprivate func nonZeroOr(_ defaultValue: Int) -> Int {
        return self != 0 ? self : defaultValue
    }
}

// BeatStatus 原始值支持
extension BeatStatus {
    var rawValue: Int {
        switch self {
        case .strong: return 0
        case .medium: return 1
        case .normal: return 2
        case .muted: return 3
        }
    }
    
    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .strong
        case 1: self = .medium
        case 2: self = .normal
        case 3: self = .muted
        default: return nil
        }
    }
}
