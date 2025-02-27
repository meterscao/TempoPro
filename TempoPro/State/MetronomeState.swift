import Foundation
import Combine

class MetronomeState: ObservableObject {
    // 定义 UserDefaults 的键
    private enum UserDefaultsKeys {
        static let tempo = "com.tempopro.tempo"
        static let beatsPerBar = "com.tempopro.beatsPerBar"
        static let beatUnit = "com.tempopro.beatUnit"
        static let beatStatuses = "com.tempopro.beatStatuses"
    }
    
    @Published private(set) var tempo: Double
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    @Published private(set) var beatsPerBar: Int {
        didSet {
            UserDefaults.standard.set(beatsPerBar, forKey: UserDefaultsKeys.beatsPerBar)
        }
    }
    @Published private(set) var beatUnit: Int {
        didSet {
            UserDefaults.standard.set(beatUnit, forKey: UserDefaultsKeys.beatUnit)
        }
    }
    @Published var beatStatuses: [BeatStatus] {
        didSet {
            // 当 beatStatuses 被修改时，自动保存到 UserDefaults
            let statusInts = beatStatuses.map { status -> Int in
                switch status {
                case .strong: return 0
                case .medium: return 1
                case .normal: return 2
                case .muted: return 3
                }
            }
            UserDefaults.standard.set(statusInts, forKey: UserDefaultsKeys.beatStatuses)
        }
    }
    
    private let audioEngine = MetronomeAudioEngine()
    private var metronomeTimer: MetronomeTimer?
    
    private var nextScheduledBeatTime: TimeInterval = 0
    
    init(beatsPerBar: Int = 3) {
        // 1. 首先初始化所有存储属性
        let savedTempo = UserDefaults.standard.double(forKey: UserDefaultsKeys.tempo)
        let savedBeatsPerBar = UserDefaults.standard.integer(forKey: UserDefaultsKeys.beatsPerBar)
        let savedBeatUnit = UserDefaults.standard.integer(forKey: UserDefaultsKeys.beatUnit)
        
        print("MetronomeState - 初始化: 从 UserDefaults 读取值 - tempo: \(savedTempo), beatsPerBar: \(savedBeatsPerBar), beatUnit: \(savedBeatUnit)")
        
        self.tempo = savedTempo != 0 ? savedTempo : 80
        self.beatsPerBar = savedBeatsPerBar != 0 ? savedBeatsPerBar : beatsPerBar
        self.beatUnit = savedBeatUnit != 0 ? savedBeatUnit : 4
        
        if let savedStatusInts = UserDefaults.standard.array(forKey: UserDefaultsKeys.beatStatuses) as? [Int] {
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
            self.beatStatuses = Array(repeating: .normal, count: beatsPerBar)
            self.beatStatuses[0] = .strong
        }
        
        // 2. 完成基本初始化
        audioEngine.initialize()
        metronomeTimer = MetronomeTimer(audioEngine: audioEngine)
        metronomeTimer?.onBeatUpdate = { [weak self] beat in
            self?.currentBeat = beat
        }
        
        // 3. 保存初始值
        UserDefaults.standard.set(self.tempo, forKey: UserDefaultsKeys.tempo)
        UserDefaults.standard.set(self.beatsPerBar, forKey: UserDefaultsKeys.beatsPerBar)
        UserDefaults.standard.set(self.beatUnit, forKey: UserDefaultsKeys.beatUnit)
    }
    
    // 提供更新方法而不是直接使用 didSet
    func updateTempo(_ newTempo: Double) {
        let currentTime = Date().timeIntervalSince1970
        tempo = max(30, min(240, newTempo))
        UserDefaults.standard.set(tempo, forKey: UserDefaultsKeys.tempo)
        
        if isPlaying {
            // 如果是首次开始或已经播放完当前拍，直接开始新的节奏
            if nextScheduledBeatTime == 0 || currentTime >= nextScheduledBeatTime {
                currentBeat = 0
                metronomeTimer?.stop()
                metronomeTimer?.start(
                    tempo: tempo,
                    beatsPerBar: beatStatuses.count,
                    beatStatuses: beatStatuses
                )
                nextScheduledBeatTime = currentTime + (60.0 / tempo)
            } else {
                // 否则，让当前拍完成后再更新速度
                metronomeTimer?.updateTempo(
                    tempo: tempo,
                    currentTime: currentTime,
                    nextBeatTime: nextScheduledBeatTime
                )
            }
        }
    }
    
    func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            currentBeat = 0
            nextScheduledBeatTime = Date().timeIntervalSince1970 + (60.0 / tempo)
            metronomeTimer?.start(
                tempo: tempo,
                beatsPerBar: beatStatuses.count,
                beatStatuses: beatStatuses
            )
        } else {
            metronomeTimer?.stop()
            nextScheduledBeatTime = 0
        }
    }
    
    func cleanup() {
        metronomeTimer?.stop()
        audioEngine.stop()
    }
    
    // 添加更新拍数的方法
    func updateBeatsPerBar(_ newBeatsPerBar: Int) {
        print("MetronomeState - updateBeatsPerBar: \(beatsPerBar) -> \(newBeatsPerBar)")
        // 保存当前的节拍状态模式
        let wasPlaying = isPlaying
        if wasPlaying {
            togglePlayback() // 暂停播放
        }
        
        // 创建新的 beatStatuses 数组
        var newBeatStatuses = Array(repeating: BeatStatus.normal, count: newBeatsPerBar)
        
        // 复制现有的节拍状态，确保不会越界
        for i in 0..<min(beatStatuses.count, newBeatsPerBar) {
            newBeatStatuses[i] = beatStatuses[i]
        }
        
        // 确保第一拍是强拍
        if newBeatStatuses.count > 0 {
            newBeatStatuses[0] = .strong
        }
        
        // 更新 beatStatuses 和 beatsPerBar
        beatStatuses = newBeatStatuses
        beatsPerBar = newBeatsPerBar
        
        // 手动保存到 UserDefaults 并强制同步
        UserDefaults.standard.set(newBeatsPerBar, forKey: UserDefaultsKeys.beatsPerBar)
        UserDefaults.standard.synchronize()
        
        // 验证是否保存到UserDefaults
        let saved = UserDefaults.standard.integer(forKey: UserDefaultsKeys.beatsPerBar)
        print("MetronomeState - UserDefaults中的beatsPerBar: \(saved)")
        
        // 如果之前在播放，则恢复播放
        if wasPlaying {
            togglePlayback()
        }
    }
    
    // 添加更新拍号单位的方法
    func updateBeatUnit(_ newBeatUnit: Int) {
        print("MetronomeState - updateBeatUnit: \(beatUnit) -> \(newBeatUnit)")
        beatUnit = newBeatUnit
        
        // 手动保存到 UserDefaults 并强制同步
        UserDefaults.standard.set(newBeatUnit, forKey: UserDefaultsKeys.beatUnit)
        UserDefaults.standard.synchronize()
        
        // 验证是否保存到UserDefaults
        let saved = UserDefaults.standard.integer(forKey: UserDefaultsKeys.beatUnit)
        print("MetronomeState - UserDefaults中的beatUnit: \(saved)")
    }
} 