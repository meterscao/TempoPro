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
    }
    
    // 状态属性
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    @Published private(set) var tempo: Int = 90
    @Published private(set) var beatsPerBar: Int = 4
    @Published private(set) var beatUnit: Int = 4
    @Published var beatStatuses: [BeatStatus] = []
    
    private let audioEngine = MetronomeAudioEngine()
    private var metronomeTimer: MetronomeTimer?
    private var nextScheduledBeatTime: TimeInterval = 0
    
    // 添加订阅管理
    private var cancellables = Set<AnyCancellable>()
    private let defaults = UserDefaults.standard
    
    init() {
        // 从UserDefaults加载初始数据
        loadFromUserDefaults()
        
        // 初始化音频引擎
        audioEngine.initialize()
        metronomeTimer = MetronomeTimer(audioEngine: audioEngine)
        metronomeTimer?.onBeatUpdate = { [weak self] beat in
            self?.currentBeat = beat
        }
    }
    
    private func loadFromUserDefaults() {
        // 读取速度值
        let savedTempo = defaults.integer(forKey: Keys.tempo)
        self.tempo = savedTempo != 0 ? savedTempo : 90
        
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
            
            // 保存默认状态
            saveBeatStatuses()
        }
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
    
    // 更新速度
    func updateTempo(_ newTempo: Int) {
        let clampedTempo = max(30, min(240, newTempo))
        if tempo != clampedTempo {
            tempo = clampedTempo
            defaults.set(tempo, forKey: Keys.tempo)
            
            if isPlaying {
                metronomeTimer?.setTempo(tempo: tempo)
            }
        }
    }
    
    // 切换播放状态
    func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            currentBeat = 0
            nextScheduledBeatTime = Date().timeIntervalSince1970 + (60.0 / Double(tempo))
            metronomeTimer?.start(
                tempo: tempo,
                beatsPerBar: beatStatuses.count,
                beatStatuses: beatStatuses,
                beatUnit: beatUnit
            )
        } else {
            metronomeTimer?.stop()
            nextScheduledBeatTime = 0
        }
    }
    
    // 清理资源
    func cleanup() {
        metronomeTimer?.stop()
        audioEngine.stop()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    // 更新拍数
    func updateBeatsPerBar(_ newBeatsPerBar: Int) {
        print("MetronomeState - updateBeatsPerBar: \(beatsPerBar) -> \(newBeatsPerBar)")
        if beatsPerBar == newBeatsPerBar { return }
        
        // 保存当前播放状态
        let wasPlaying = isPlaying
        
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
        
        // 如果正在播放，重新启动节拍器
        if wasPlaying {
            let currentBeatToUse = currentBeat >= newBeatsPerBar ? 0 : currentBeat
            
            metronomeTimer?.stop()
            metronomeTimer?.start(
                tempo: tempo,
                beatsPerBar: newBeatsPerBar,
                beatStatuses: beatStatuses,
                currentBeat: currentBeatToUse
            )
        }
    }
    
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
    }
    
    // 更新节拍状态
    func updateBeatStatuses(_ newStatuses: [BeatStatus]) {
        beatStatuses = newStatuses
        saveBeatStatuses()
    }
} 
