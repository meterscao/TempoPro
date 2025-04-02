//
//  MySettingRepository.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/2.
//

import SwiftUI

class MySettingsRepositoryService: MySettingsRepositoryProtocol {
    private let defaults = UserDefaults.standard
    
    // MARK: - 加载方法
    func loadTempo() -> Int {
        return defaults.integer(forKey: Keys.tempo).nonZeroOr(120)
    }
    
    func loadBeatsPerBar() -> Int {
        return defaults.integer(forKey: Keys.beatsPerBar).nonZeroOr(4)
    }
    
    func loadBeatUnit() -> Int {
        return defaults.integer(forKey: Keys.beatUnit).nonZeroOr(4)
    }
    
    func loadBeatStatuses() -> [BeatStatus] {
        if let savedStatusInts = defaults.array(forKey: Keys.beatStatuses) as? [Int] {
            return savedStatusInts.map { BeatStatus(rawValue: $0) ?? .normal }
        } else {
            // 如果没有保存的状态，返回默认状态
            var defaultStatuses = Array(repeating: BeatStatus.normal, count: loadBeatsPerBar())
            if !defaultStatuses.isEmpty {
                defaultStatuses[0] = .strong
                if defaultStatuses.count > 2 {
                    defaultStatuses[2] = .medium
                }
            }
            return defaultStatuses
        }
    }
    
    func loadSubdivisionPattern() -> SubdivisionPattern {
        if let savedPatternName = defaults.string(forKey: Keys.subdivisionType),
           let pattern = SubdivisionManager.getSubdivisionPattern(byName: savedPatternName) {
            return pattern
        } else {
            // 如果没有保存的模式，返回默认模式
            if let defaultPattern = SubdivisionManager.getSubdivisionPattern(forBeatUnit: loadBeatUnit(), type: .whole) {
                return defaultPattern
            }
            // 如果获取默认模式失败，创建一个基本的整拍模式
            return SubdivisionPattern(
                name: "quarter_whole",
                displayName: "整拍",
                type: .whole,
                notes: [
                    SubdivisionNote(length: 1.0, isMuted: false, noteValue: 4)
                ],
                beatUnit: loadBeatUnit(),
                order: 0
            )
        }
    }
    
    func loadSoundSet() -> SoundSet {
        if let savedSoundSetKey = defaults.string(forKey: Keys.soundSet),
           let savedSoundSet = SoundSetManager.availableSoundSets.first(where: { $0.key == savedSoundSetKey }) {
            return savedSoundSet
        } else {
            return SoundSetManager.getDefaultSoundSet()
        }
    }
    
    // MARK: - 保存方法
    func saveTempo(_ tempo: Int) {
        defaults.set(tempo, forKey: Keys.tempo)
    }
    
    func saveBeatsPerBar(_ beatsPerBar: Int) {
        defaults.set(beatsPerBar, forKey: Keys.beatsPerBar)
    }
    
    func saveBeatUnit(_ beatUnit: Int) {
        defaults.set(beatUnit, forKey: Keys.beatUnit)
    }
    
    func saveBeatStatuses(_ beatStatuses: [BeatStatus]) {
        let statusInts = beatStatuses.map { $0.rawValue }
        defaults.set(statusInts, forKey: Keys.beatStatuses)
    }
    
    func saveSubdivisionPattern(_ subdivisionPattern: SubdivisionPattern) {
        defaults.set(subdivisionPattern.name, forKey: Keys.subdivisionType)
    }
    
    func saveSoundSet(_ soundSet: SoundSet) {
        defaults.set(soundSet.key, forKey: Keys.soundSet)
    }
}

// 辅助扩展
private extension Int {
    func nonZeroOr(_ defaultValue: Int) -> Int {
        return self != 0 ? self : defaultValue
    }
}
