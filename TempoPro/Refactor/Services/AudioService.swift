//
//  AudioService.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/31.
//
import AVFoundation


// 音频服务
class AudioService {
    private let engine = AVAudioEngine()
    private var players: [MetronomeModel.BeatPattern: AVAudioPlayer] = [:]
    private var subdivisionPlayers: [AVAudioPlayer] = []
    
    init() {
        setupAudioSession()
    }
    
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    func loadSoundSet(_ soundSet: MetronomeModel.SoundSet) {
        // 清除现有音效
        players.removeAll()
        
        // 加载新音效集的所有类型音效
        for beatPattern in MetronomeModel.BeatPattern.allCases {
            let soundName = "\(soundSet.rawValue)_\(beatPattern.rawValue)"
            if let url = Bundle.main.url(forResource: soundName, withExtension: "wav"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[beatPattern] = player
            }
        }
    }
    
    func playSound(for beatPattern: MetronomeModel.BeatPattern) {
        guard let player = players[beatPattern] else { return }
        
        // 复位并播放
        player.currentTime = 0
        player.play()
    }
}
