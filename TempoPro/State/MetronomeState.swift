import Foundation
import Combine
import UIKit  // 添加UIKit导入
import SwiftUI // 添加SwiftUI导入以使用AppStorage

// 添加切分音符类型枚举（同TimeSignatureView.swift中的定义）
enum SubdivisionType: String, CaseIterable, Identifiable, Codable {
    case whole = "整拍"
    case duple = "二等分"
    case dotted = "附点节奏"
    case triplet = "三连音"
    case quadruple = "四等分"
    case dupleTriplet = "二连三连音"
    
    var id: String { self.rawValue }
    
    // 获取描述文本
    func getDescription(forBeatUnit beatUnit: Int) -> String {
        switch self {
        case .whole:
            return "1个\(beatUnit)分音符"
        case .duple:
            return "2个\(beatUnit*2)分音符"
        case .dotted:
            return "空+1个\(beatUnit*2)分音符"
        case .triplet:
            return "\(beatUnit*2)分音符3连音"
        case .quadruple:
            return "4个\(beatUnit*4)分音符"
        case .dupleTriplet:
            return "2个\"\(beatUnit*2)分音符3连音\""
        }
    }
}

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
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    @Published private(set) var tempo: Int = 0
    @Published private(set) var beatsPerBar: Int = 0
    @Published private(set) var beatUnit: Int = 0
    @Published var beatStatuses: [BeatStatus] = []
    @Published private(set) var subdivisionType: SubdivisionType = .whole
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
            self.beatStatuses[2] = .medium
            
            // 保存默认状态
            saveBeatStatuses()
        }
        
        // 加载切分音符类型
        if let savedSubdivisionTypeString = defaults.string(forKey: Keys.subdivisionType),
           let savedType = SubdivisionType(rawValue: savedSubdivisionTypeString) {
            self.subdivisionType = savedType
        } else {
            // 默认为整拍
            self.subdivisionType = .whole
            defaults.set(subdivisionType.rawValue, forKey: Keys.subdivisionType)
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
    
    // 简化的播放控制方法
    func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            // 开始练习会话
            practiceManager?.startPracticeSession(bpm: tempo)
            // 直接启动定时器，无需传递参数
            metronomeTimer?.start()
        } else {
            // 结束练习会话
            practiceManager?.endPracticeSession()
            // 停止定时器
            metronomeTimer?.stop()
        }
    }
    
    // 更新速度 - 无需特殊处理，Timer会在下一拍自动使用新值
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
        
        // // 如果正在播放，重新启动节拍器
        // if wasPlaying {
        //     // 先停止
        //     metronomeTimer?.stop()
        //     isPlaying = false
            
        //     // 然后重新开始
        //     isPlaying = true
        //     metronomeTimer?.start()
        // }
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
    
    // 添加更新切分音符类型的方法
    func updateSubdivisionType(_ newType: SubdivisionType) {
        print("MetronomeState - updateSubdivisionType: \(subdivisionType.rawValue) -> \(newType.rawValue)")
        if subdivisionType == newType { return }
        
        subdivisionType = newType
        defaults.set(subdivisionType.rawValue, forKey: Keys.subdivisionType)
    }
    
    // 添加辅助方法，将beatStatuses转换为字符串形式
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
}
