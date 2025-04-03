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
// 架构改进 (2025/07):
// 1. 采用MVVM架构模式:
//   - Model: MetronomeState类保持为纯数据模型，负责数据存储
//   - ViewModel: MetronomeState扩展中的兼容方法作为ViewModel层，提供UI绑定接口
//   - Controller: MetronomeStateController作为业务逻辑控制器，处理核心业务逻辑
//   - View: SwiftUI视图通过MetronomeState(ViewModel)或直接访问Controller



// 节拍器播放委托协议 - 用于通知外部组件
protocol MetronomePlaybackDelegate: AnyObject {
    func metronomeDidChangePlaybackState(_ state: PlaybackState)
    func metronomeDidCompleteBeat(beatIndex: Int, isLastBeat: Bool)
    func metronomeDidCompleteBar(barCount: Int)
    
    // 通知播放状态变化（简化版，只传递是否播放）
    func metronomePlaybackDidChangeState(isPlaying: Bool)
}

// 高级节拍器播放委托协议 - 用于更精确的节拍控制和预先通知
protocol AdvancedMetronomePlaybackDelegate: MetronomePlaybackDelegate {
    // 小节即将完成事件（当最后一拍完成时触发，在实际增加小节计数之前）
    func metronomeWillCompleteBar(barCount: Int)
}

// MARK: - 纯数据模型
class MetronomeState: ObservableObject, Hashable {
    // 实现 Hashable 协议
    static func == (lhs: MetronomeState, rhs: MetronomeState) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
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



// MARK: - ViewModel层 - MetronomeState扩展作为ViewModel提供UI接口
extension MetronomeState {
    // MARK: - 静态缓存控制器
    private static var controllers = [MetronomeState: MetronomeController]()
    
    // 获取此状态对应的控制器
    func getController() -> MetronomeController {
        if let controller = MetronomeState.controllers[self] {
            return controller
        }
        let controller = MetronomeController(state: self)
        MetronomeState.controllers[self] = controller
        return controller
    }
    
    // MARK: - ViewModel - 播放控制方法（用于视图绑定）
    
    /// 切换播放状态（暂停/继续）
    /// - 视图层方法：用于播放/暂停按钮绑定
    func togglePlayback() {
        let controller = getController()
        if isPlaying {
            controller.pause()
        } else {
            controller.play()
        }
    }
    
    /// 开始播放
    /// - 视图层方法：用于播放按钮绑定
    func play() {
        getController().play()
    }
    
    /// 停止播放
    /// - 视图层方法：用于停止按钮绑定
    func stop() {
        getController().stop()
    }
    
    /// 暂停播放
    /// - 视图层方法：用于暂停按钮绑定
    func pause() {
        getController().pause()
    }
    
    /// 恢复播放
    /// - 视图层方法：用于恢复按钮绑定
    func resume() {
        getController().resume()
    }
    
    // MARK: - ViewModel - 音效设置方法
    
    /// 更新音效集
    /// - 视图层方法：用于音效选择界面
    /// - Parameter soundSet: 新的音效集
    func updateSoundSet(_ soundSet: SoundSet) {
        // 更新模型数据
        self._updateSoundSetData(soundSet)
        // 通知控制器更新音频引擎
        getController().updateSoundSet(soundSet)
    }
    
    // MARK: - ViewModel - 委托管理方法
    
    /// 添加播放状态改变委托
    /// - 视图层方法：用于注册播放状态监听器
    /// - Parameter delegate: 播放状态委托
    func addDelegate(_ delegate: MetronomePlaybackDelegate) {
        getController().addDelegate(delegate)
    }
    
    /// 移除播放状态改变委托
    /// - 视图层方法：用于取消注册播放状态监听器
    /// - Parameter delegate: 播放状态委托
    func removeDelegate(_ delegate: MetronomePlaybackDelegate) {
        getController().removeDelegate(delegate)
    }
    
    /// 清理资源
    /// - 视图层方法：用于视图销毁时清理资源
    func cleanup() {
        // 清理控制器资源
        if let controller = MetronomeState.controllers[self] {
            controller.cleanup()
            // 从静态控制器映射中移除
            MetronomeState.controllers.removeValue(forKey: self)
        }
    }
    
    // MARK: - ViewModel - 节拍设置方法
    
    /// 更新拍子划分类型
    /// - 视图层方法：用于拍子划分设置界面
    /// - Parameter type: 新的划分类型
    func updateSubdivisionType(_ type: SubdivisionType) {
        getController().updateSubdivisionType(type)
    }
    
    // MARK: - ViewModel - 练习辅助方法
    
    /// 是否完成了指定数量的小节
    /// - 视图层方法：用于练习进度显示
    /// - Parameter targetBars: 目标小节数
    /// - Returns: 是否已完成指定小节数
    func hasCompletedBars(_ targetBars: Int) -> Bool {
        return getController().hasCompletedBars(targetBars)
    }
    
    /// 获取剩余小节数
    /// - 视图层方法：用于练习剩余时间显示
    /// - Parameter target: 目标小节数
    /// - Returns: 剩余小节数
    func getRemainingBars(target: Int) -> Int {
        return getController().getRemainingBars(target: target)
    }
    
    /// 获取小节进度比例
    /// - 视图层方法：用于进度条显示
    /// - Parameter targetBars: 目标小节数
    /// - Returns: 当前进度（0.0-1.0）
    func getBarProgress(targetBars: Int) -> CGFloat {
        return getController().getBarProgress(targetBars: targetBars)
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
