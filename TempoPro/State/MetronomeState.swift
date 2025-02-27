import Foundation
import Combine

class MetronomeState: ObservableObject {
    @Published var tempo: Double = 80
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    @Published var beatStatuses: [BeatStatus]
    
    private let audioEngine = MetronomeAudioEngine()
    private var metronomeTimer: MetronomeTimer?
    
    init(beatsPerBar: Int = 3) {
        beatStatuses = Array(repeating: .normal, count: beatsPerBar)
        beatStatuses[0] = .strong
        
        audioEngine.initialize()
        metronomeTimer = MetronomeTimer(audioEngine: audioEngine)
        metronomeTimer?.onBeatUpdate = { [weak self] beat in
            self?.currentBeat = beat
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
    
    func updateTempo(_ newTempo: Double) {
        tempo = max(30, min(240, newTempo))
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
    
    func cleanup() {
        metronomeTimer?.stop()
        audioEngine.stop()
    }
} 