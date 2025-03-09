import Foundation
import Combine
import UIKit  // 添加UIKit导入
import SwiftUI // 添加SwiftUI导入以使用AppStorage


class MetronomeState: ObservableObject {
    // 定义引用的键
    private enum Keys {
        static let tempo = AppStorageKeys.Metronome.tempo
        static let beatsPerBar = AppStorageKeys.Metronome.beatsPerBar
        static let beatUnit = AppStorageKeys.Metronome.beatUnit
        static let beatStatuses = AppStorageKeys.Metronome.beatStatuses
        static let currentBeat = AppStorageKeys.Metronome.currentBeat
        static let subdivisionType = AppStorageKeys.Metronome.subdivisionType
    }
    
    // 状态属性
    @Published private(set) var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    @Published private(set) var tempo: Int = 0
    @Published private(set) var beatsPerBar: Int = 0
    @Published private(set) var beatUnit: Int = 0
    @Published private(set) var beatStatuses: [BeatStatus] = []
    @Published private(set) var subdivisionPattern: SubdivisionPattern?
    @Published var practiceManager: CoreDataPracticeManager?
    
    // 直接使用单例引擎
    private let audioEngine = MetronomeAudioEngine.shared
    private var metronomeTimer: MetronomeTimer?
    
    // 添加订阅管理
    private var cancellables = Set<AnyCancellable>()
    private let defaults = UserDefaults.standard
    
    init() {
        // 从UserDefaults加载初始数据
        loadFromUserDefaults()
        
        // 初始化音频引擎
        audioEngine.initialize()
        
        // 创建节拍定时器，传入self引用
        metronomeTimer = MetronomeTimer(state: self, audioEngine: audioEngine)
    }
    
    private func loadFromUserDefaults() {
        // 读取速度值
        let savedTempo = defaults.integer(forKey: Keys.tempo)
        self.tempo = savedTempo != 0 ? savedTempo : 120
        
        // 读取拍号设置
        let savedBeatsPerBar = defaults.integer(forKey: Keys.beatsPerBar)
        self.beatsPerBar = savedBeatsPerBar != 0 ? savedBeatsPerBar : 4
        
        let savedBeatUnit = defaults.integer(forKey: Keys.beatUnit)
        self.beatUnit = savedBeatUnit != 0 ? savedBeatUnit : 4
        
        // 加载节拍状态
        if let savedStatusInts = defaults.array(forKey: Keys.beatStatuses) as? [Int] {
            self.beatStatuses = savedStatusInts.map { statusInt -> BeatStatus in
                switch statusInt {
                case 0: return .strong
                case 1: return .medium
                case 2: return .normal
                case 3: return .muted
                default: return .normal
                }
            }
        } else {
            // 初始化默认节拍状态
            self.beatStatuses = Array(repeating: .normal, count: self.beatsPerBar)
            self.beatStatuses[0] = .strong
            if self.beatsPerBar > 2 {
                self.beatStatuses[2] = .medium
            }
            
            // 保存默认状态
            saveBeatStatuses()
        }
        
        // 加载切分音符模式
        if let savedPatternName = defaults.string(forKey: Keys.subdivisionType) {
            // 尝试从名称获取切分模式
            if let pattern = SubdivisionManager.getSubdivisionPattern(byName: savedPatternName) {
                self.subdivisionPattern = pattern
            } else {
                // 如果找不到对应模式，使用当前拍号单位的默认模式
                setDefaultSubdivisionPattern()
            }
        } else {
            // 默认使用整拍模式
            setDefaultSubdivisionPattern()
        }
    }
    
    // 设置默认的切分模式
    private func setDefaultSubdivisionPattern() {
        // 获取当前拍号单位下的整拍模式
        if let pattern = SubdivisionManager.getSubdivisionPattern(forBeatUnit: beatUnit, type: .whole) {
            self.subdivisionPattern = pattern
            // 保存模式名称到 UserDefaults
            defaults.set(pattern.name, forKey: Keys.subdivisionType)
        } else {
            // 回退到4分音符整拍
            if let fallbackPattern = SubdivisionManager.getSubdivisionPattern(forBeatUnit: 4, type: .whole) {
                self.subdivisionPattern = fallbackPattern
                defaults.set(fallbackPattern.name, forKey: Keys.subdivisionType)
            }
        }
    }
    
    // 更新当前切分模式
    private func updateCurrentSubdivisionPattern() {
        guard let currentPattern = subdivisionPattern else {
            setDefaultSubdivisionPattern()
            return
        }
        
        // 检查当前模式是否适用于当前拍号单位
        if currentPattern.beatUnit != beatUnit {
            // 直接使用当前模式的type获取适合新拍号单位的模式
            if let newPattern = SubdivisionManager.getSubdivisionPattern(forBeatUnit: beatUnit, type: currentPattern.type) {
                // 更新到新的模式
                subdivisionPattern = newPattern
                defaults.set(newPattern.name, forKey: Keys.subdivisionType)
                print("切分模式已适配当前拍号单位: \(currentPattern.type.rawValue) -> \(newPattern.name)")
            } else {
                // 如果找不到适配当前拍号单位的相同类型模式，使用默认整拍模式
                print("未找到适配当前拍号单位的\(currentPattern.type.rawValue)类型模式，使用默认模式")
                setDefaultSubdivisionPattern()
            }
        }
        
        print("当前切分模式: \(subdivisionPattern?.detailedDescription ?? "未知")")
    }
    
    // 保存节拍状态到UserDefaults
    private func saveBeatStatuses() {
        let statusInts = beatStatuses.map { status -> Int in
            switch status {
            case .strong: return 0
            case .medium: return 1
            case .normal: return 2
            case .muted: return 3
            }
        }
        defaults.set(statusInts, forKey: Keys.beatStatuses)
    }
    
    // 播放控制方法
    func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            // 确保当前切分模式已更新
            updateCurrentSubdivisionPattern()
            
            // 开始练习会话
            practiceManager?.startPracticeSession(bpm: tempo)
            
            // 直接启动定时器
            metronomeTimer?.start()
        } else {
            // 结束练习会话
            practiceManager?.endPracticeSession()
            
            // 停止定时器
            metronomeTimer?.stop()
        }
    }
    
    // 使用切分类型更新切分模式
    func updateSubdivisionType(_ type: SubdivisionType) {
        print("MetronomeState - updateSubdivisionType: \(type.rawValue)")
        
        // 获取当前拍号单位下该类型的切分模式
        if let pattern = SubdivisionManager.getSubdivisionPattern(forBeatUnit: beatUnit, type: type) {
            updateSubdivisionPattern(pattern)
        }
    }
    
    // 更新速度
    func updateTempo(_ newTempo: Int) {
        let clampedTempo = max(30, min(240, newTempo))
        if tempo != clampedTempo {
            tempo = clampedTempo
            defaults.set(tempo, forKey: Keys.tempo)
            
            // 不需要通知Timer，它会直接使用新值
        }
    }
    
    // 更新拍数方法
    func updateBeatsPerBar(_ newBeatsPerBar: Int) {
        print("MetronomeState - updateBeatsPerBar: \(beatsPerBar) -> \(newBeatsPerBar)")
        if beatsPerBar == newBeatsPerBar { return }
        
        // 创建新的节拍状态数组
        var newBeatStatuses = Array(repeating: BeatStatus.normal, count: newBeatsPerBar)
        
        // 复制现有节拍状态
        for i in 0..<min(beatStatuses.count, newBeatsPerBar) {
            newBeatStatuses[i] = beatStatuses[i]
        }
        
        // 确保第一拍是强拍
        if newBeatStatuses.count > 0 {
            newBeatStatuses[0] = .strong
        }
        
        // 更新状态
        beatStatuses = newBeatStatuses
        beatsPerBar = newBeatsPerBar
        
        // 保存到UserDefaults
        defaults.set(beatsPerBar, forKey: Keys.beatsPerBar)
        saveBeatStatuses()
        
        
    }
    
    // 更新当前拍
    func updateCurrentBeat(_ newCurrentBeat: Int) {
        currentBeat = newCurrentBeat
        defaults.set(currentBeat, forKey: Keys.currentBeat)
    }   
    
    // 更新拍号单位
    func updateBeatUnit(_ newBeatUnit: Int) {
        print("MetronomeState - updateBeatUnit: \(beatUnit) -> \(newBeatUnit)")
        if beatUnit == newBeatUnit { return }
        
        beatUnit = newBeatUnit
        defaults.set(beatUnit, forKey: Keys.beatUnit)
        
        // 更新当前切分模式
        updateCurrentSubdivisionPattern()
        
        
    }
    
    // 更新节拍状态
    func updateBeatStatuses(_ newStatuses: [BeatStatus]) {
        beatStatuses = newStatuses
        saveBeatStatuses()
        
        // 如果正在播放，可能需要重新启动节拍器
        // 但这里不做重启，因为状态变化对当前节拍影响不大
    }
    
    // 更新切分模式
    func updateSubdivisionPattern(_ pattern: SubdivisionPattern) {
        guard pattern.name != subdivisionPattern?.name else { return }
        
        print("MetronomeState - updateSubdivisionPattern: \(subdivisionPattern?.name ?? "nil") -> \(pattern.name)")
        
        // 更新当前模式
        subdivisionPattern = pattern
        
        // 保存模式名称到 UserDefaults
        defaults.set(pattern.name, forKey: Keys.subdivisionType)
        
        
    }
    
    
    
    // 获取节拍状态字符串
    private func getBeatStatusString() -> String {
        let statusInts = beatStatuses.map { status -> Int in
            switch status {
            case .strong: return 0
            case .medium: return 1
            case .normal: return 2
            case .muted: return 3
            }
        }
        return "\(beatsPerBar)/\(beatUnit): \(statusInts.map {String($0)}.joined(separator: ","))"
    }
    
    // 清理资源
    func cleanup() {
        metronomeTimer?.stop()
        audioEngine.stop()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    // 获取当前切分模式的类型（兼容现有代码）
    var subdivisionType: SubdivisionType {
        return subdivisionPattern?.type ?? .whole
    }
}
