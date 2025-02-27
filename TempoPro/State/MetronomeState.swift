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
    
    // 先声明属性，但不立即设置 didSet
    @Published private(set) var tempo: Double
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
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
    
    init(beatsPerBar: Int = 3) {
        // 1. 首先初始化所有存储属性
        let savedTempo = UserDefaults.standard.double(forKey: UserDefaultsKeys.tempo)
        self.tempo = savedTempo != 0 ? savedTempo : 80
        
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
    }
    
    // 提供更新方法而不是直接使用 didSet
    func updateTempo(_ newTempo: Double) {
        tempo = max(30, min(240, newTempo))
        UserDefaults.standard.set(tempo, forKey: UserDefaultsKeys.tempo)
        
        if isPlaying {
            currentBeat = 0
            metronomeTimer?.stop()
            metronomeTimer?.start(
                tempo: tempo,
                beatsPerBar: beatStatuses.count,
                beatStatuses: beatStatuses
            )
        }
    }
    
    func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            currentBeat = 0
            metronomeTimer?.start(
                tempo: tempo,
                beatsPerBar: beatStatuses.count,
                beatStatuses: beatStatuses
            )
        } else {
            metronomeTimer?.stop()
        }
    }
    
    func cleanup() {
        metronomeTimer?.stop()
        audioEngine.stop()
    }
} 