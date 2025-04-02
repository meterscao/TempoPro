//
//  MyController.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/2.
//

import SwiftUI

protocol MyControllerDelegate: AnyObject {
    func didTempoChange(_ tempo: Int)
    func didBeatsPerBarChange(_ beatsPerBar: Int)
    func didBeatUnitChange(_ beatUnit: Int)
    func didBeatStatusesChange(_ beatStatuses: [BeatStatus])
    func didSubdivisionPatternChange(_ subdivisionPattern: SubdivisionPattern)
    func didSoundSetChange(_ soundSet: SoundSet)
}

class MyController: ObservableObject {

    weak var delegate: MyControllerDelegate?

    private let settingsService: MySettingsRepositoryService

    private var tempo: Int
    private var beatsPerBar: Int
    private var beatUnit: Int
    private var beatStatuses: [BeatStatus]
    private var subdivisionPattern: SubdivisionPattern
    private var soundSet: SoundSet

    private let audioService: MetronomeAudioService
    private let timerService: MetronomeTimerService
    

    init(settingsService: MySettingsRepositoryService,
        audioService: MetronomeAudioService,
        timerService: MetronomeTimerService
    ) {
        self.settingsService = settingsService
        self.audioService = audioService
        self.timerService = timerService
        
        self.tempo = settingsService.loadTempo()
        self.beatsPerBar = settingsService.loadBeatsPerBar()
        self.beatUnit = settingsService.loadBeatUnit()
        self.beatStatuses = settingsService.loadBeatStatuses()
        self.subdivisionPattern = settingsService.loadSubdivisionPattern()
        self.soundSet = settingsService.loadSoundSet()
    }

    func updateTempo(_ tempo: Int) {
        // 验证和限制范围
        let validTempo = max(30, min(240, tempo))
        if self.tempo != validTempo {
            self.tempo = validTempo
            settingsService.saveTempo(validTempo)
            delegate?.didTempoChange(validTempo)
        }
    }

    func updateBeatsPerBar(_ beatsPerBar: Int) {
        let validBeatsPerBar = max(1, min(16, beatsPerBar))
        if self.beatsPerBar != validBeatsPerBar {
            self.beatsPerBar = validBeatsPerBar
            settingsService.saveBeatsPerBar(validBeatsPerBar)
            delegate?.didBeatsPerBarChange(validBeatsPerBar)    
        }
    }

    func updateBeatUnit(_ beatUnit: Int) {
        let validBeatUnit = max(1, min(16, beatUnit))
        if self.beatUnit != validBeatUnit {
            self.beatUnit = validBeatUnit
            settingsService.saveBeatUnit(validBeatUnit)
            delegate?.didBeatUnitChange(validBeatUnit)
        }
    }

    func updateBeatStatuses(_ beatStatuses: [BeatStatus]) {
        if self.beatStatuses != beatStatuses {
            self.beatStatuses = beatStatuses
            settingsService.saveBeatStatuses(beatStatuses)
            delegate?.didBeatStatusesChange(beatStatuses)
        }
    }

    func updateSubdivisionPattern(_ pattern: SubdivisionPattern) {
        // 使用 name 属性进行比较
        guard pattern.name != subdivisionPattern.name else { return }
        
        // 更新当前模式
        self.subdivisionPattern = pattern
        
        // 保存模式名称到 UserDefaults
        settingsService.saveSubdivisionPattern(pattern)
        delegate?.didSubdivisionPatternChange(pattern)
    }

    
    
    // 重命名为内部方法，只处理数据更新
    func updateSoundSet(_ newSoundSet: SoundSet) {
        // 使用 key 属性进行比较
        guard newSoundSet.key != soundSet.key else { return }
        
        // 更新当前音效集
        self.soundSet = newSoundSet
        
        // 保存设置到UserDefaults
        settingsService.saveSoundSet(newSoundSet)
        delegate?.didSoundSetChange(newSoundSet)
    }

    func getTempo() -> Int {
        return tempo
    }

    func getBeatsPerBar() -> Int {
        return beatsPerBar
    }

    func getBeatUnit() -> Int {
        return beatUnit
    }

    func getBeatStatuses() -> [BeatStatus] {
        return beatStatuses
    }

    func getSubdivisionPattern() -> SubdivisionPattern {
        return subdivisionPattern
    }

    func getSoundSet() -> SoundSet {
        return soundSet
    }
    
    
}

