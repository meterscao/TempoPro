//
//  MyModel.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/2.
//

import SwiftUI

enum Keys {
    static let tempo = AppStorageKeys.Metronome.tempo
    static let beatsPerBar = AppStorageKeys.Metronome.beatsPerBar
    static let beatUnit = AppStorageKeys.Metronome.beatUnit
    static let beatStatuses = AppStorageKeys.Metronome.beatStatuses
    static let currentBeat = AppStorageKeys.Metronome.currentBeat
    static let subdivisionType = AppStorageKeys.Metronome.subdivisionType
    static let soundSet = AppStorageKeys.Metronome.soundSet
    static let dailyGoalMinutes = AppStorageKeys.Stats.dailyGoalMinutes
}

struct MySettings {
    var tempo: Int
    var beatsPerBar: Int
    var beatUnit: Int
    var beatStatuses: [BeatStatus]
    var subdivisionPattern: SubdivisionPattern
    var soundSet: SoundSet
    var dailyGoalMinutes: Int
}

protocol MySettingsProtocol {
    func loadTempo() -> Int
    func loadBeatsPerBar() -> Int
    func loadBeatUnit() -> Int
    func loadBeatStatuses() -> [BeatStatus]
    func loadSubdivisionPattern() -> SubdivisionPattern
    func loadSoundSet() -> SoundSet
    func loadDailyGoalMinutes() -> Int
    

    func saveTempo(_ tempo: Int)
    func saveBeatsPerBar(_ beatsPerBar: Int)
    func saveBeatUnit(_ beatUnit: Int)
    func saveBeatStatuses(_ beatStatuses: [BeatStatus])
    func saveSubdivisionPattern(_ subdivisionPattern: SubdivisionPattern)
    func saveSoundSet(_ soundSet: SoundSet)
    func saveDailyGoalMinutes(_ dailyGoalMinutes: Int)
}


