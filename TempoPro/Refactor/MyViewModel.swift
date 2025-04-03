//
//  MyViewModel.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/2.
//

import SwiftUI

class MyViewModel: ObservableObject {
    
    @Published var tempo: Int
    @Published var beatsPerBar: Int
    @Published var beatUnit: Int
    @Published var beatStatuses: [BeatStatus]
    @Published var subdivisionPattern: SubdivisionPattern
    @Published var soundSet: SoundSet
    @Published var playbackState: PlaybackState
    
    @Published var isPlaying: Bool
    @Published var currentBeat: Int
    private let controller: MyController

    init(controller: MyController) {
        self.controller = controller

        self.tempo = controller.getTempo()
        self.beatsPerBar = controller.getBeatsPerBar()
        self.beatUnit = controller.getBeatUnit()
        self.beatStatuses = controller.getBeatStatuses()
        self.subdivisionPattern = controller.getSubdivisionPattern()
        self.soundSet = controller.getSoundSet()
        self.playbackState = controller.getPlaybackState()
        self.isPlaying = controller.getPlaybackState() == .playing
        self.currentBeat = controller.getCurrentBeat()
        controller.delegate = self
    }

    

    func updateTempo(_ tempo: Int) {
        controller.updateTempo(tempo)
    }

    func updateBeatsPerBar(_ beatsPerBar: Int) {
        controller.updateBeatsPerBar(beatsPerBar)
    }

    func updateBeatUnit(_ beatUnit: Int) {
        controller.updateBeatUnit(beatUnit)
    }

    func updateSubdivisionPattern(_ subdivisionPattern: SubdivisionPattern) {
        controller.updateSubdivisionPattern(subdivisionPattern)
    }

    func updateSoundSet(_ soundSet: SoundSet) {
        controller.updateSoundSet(soundSet)
    }

    func updateBeatStatuses(_ beatStatuses: [BeatStatus]) {
        controller.updateBeatStatuses(beatStatuses)
    }

    func play() {
        controller.play()
    }

    func pause() {
        controller.pause()
    }

    func stop() {
        controller.stop()
    }

    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }

    
}

extension MyViewModel :MyControllerDelegate{
    func didTempoChange(_ tempo: Int) {
        DispatchQueue.main.async {
            self.tempo = tempo
        }
    }

    func didBeatsPerBarChange(_ beatsPerBar: Int) {
        DispatchQueue.main.async {
            self.beatsPerBar = beatsPerBar
        }
    }

    func didBeatUnitChange(_ beatUnit: Int) {
        DispatchQueue.main.async {
            self.beatUnit = beatUnit
        }
    }

    func didBeatStatusesChange(_ beatStatuses: [BeatStatus]) {
        DispatchQueue.main.async {
            self.beatStatuses = beatStatuses
        }
    }
    
    func didSubdivisionPatternChange(_ subdivisionPattern: SubdivisionPattern) {
        DispatchQueue.main.async {
            self.subdivisionPattern = subdivisionPattern
        }
    }
    
    func didSoundSetChange(_ soundSet: SoundSet) {
        DispatchQueue.main.async {
            self.soundSet = soundSet
        }
    }

    func didPlaybackStateChange(_ playbackState: PlaybackState) {
        DispatchQueue.main.async {
            self.playbackState = playbackState
            self.isPlaying = playbackState == .playing
        }
    }

    func didCurrentBeatChange(_ currentBeat: Int) {
        DispatchQueue.main.async {
            self.currentBeat = currentBeat
        }
    }
}
