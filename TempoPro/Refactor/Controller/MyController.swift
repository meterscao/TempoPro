//
//  MyController.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/2.
//

import SwiftUI


// 添加播放状态枚举
enum PlaybackState {
    case standby   // 默认状态/停止状态
    case playing   // 正在播放
    case paused    // 暂停状态
}

protocol MyControllerDelegate: AnyObject {
    func didTempoChange(_ tempo: Int)
    func didBeatsPerBarChange(_ beatsPerBar: Int)
    func didBeatUnitChange(_ beatUnit: Int)
    func didBeatStatusesChange(_ beatStatuses: [BeatStatus])
    func didSubdivisionPatternChange(_ subdivisionPattern: SubdivisionPattern)
    func didSoundSetChange(_ soundSet: SoundSet)
    func didPlaybackStateChange(_ playbackState: PlaybackState)
    func didCurrentBeatChange(_ currentBeat: Int)
}

class MyController {

    weak var delegate: MyControllerDelegate?

    

    private var tempo: Int
    private var beatsPerBar: Int
    private var beatUnit: Int
    private var beatStatuses: [BeatStatus]
    private var subdivisionPattern: SubdivisionPattern
    private var soundSet: SoundSet


    // 添加播放状态
    private var playbackState: PlaybackState = .standby
    private var currentBeat: Int = 0
    private var completedBars: Int = 0

    private var settingsService: MySettingsService
    private var audioService: MyAudioService
    private var timerService: MyTimerService
    

    init() {
        // 初始化设置服务
        self.settingsService = MySettingsService()
        
        // 从设置服务加载初始值
        self.tempo = settingsService.loadTempo()
        self.beatsPerBar = settingsService.loadBeatsPerBar()
        self.beatUnit = settingsService.loadBeatUnit()
        self.beatStatuses = settingsService.loadBeatStatuses()
        self.subdivisionPattern = settingsService.loadSubdivisionPattern()
        self.soundSet = settingsService.loadSoundSet()

        // 初始化音频服务，传入默认音效集
        self.audioService = MyAudioService(defaultSoundSet: soundSet)

        // 初始化定时器服务
        self.timerService = MyTimerService()
        // 设置委托
        self.timerService.setDelegate(self)
        // 设置回调
        self.setupTimerCallbacks()
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
            var newBeatStatuses = Array(repeating: BeatStatus.normal, count: validBeatsPerBar)
            // 复制现有节拍状态
            for i in 0..<min(beatStatuses.count, validBeatsPerBar) {
                newBeatStatuses[i] = beatStatuses[i]
            }
            settingsService.saveBeatsPerBar(validBeatsPerBar)
            settingsService.saveBeatStatuses(newBeatStatuses)
            delegate?.didBeatsPerBarChange(validBeatsPerBar)    
            delegate?.didBeatStatusesChange(newBeatStatuses)
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

    func getPlaybackState() -> PlaybackState {
        return playbackState
    }

    func getCurrentBeat() -> Int {
        return currentBeat
    }
}


extension MyController {
    func notifyPlaybackStateChanged() {
        delegate?.didPlaybackStateChange(playbackState)
    }

    func play() {
        if(playbackState == .standby) {
            timerService.start()
            playbackState = .playing
            notifyPlaybackStateChanged()
        }
    }

    func stop() {
        if(playbackState == .playing) {
            timerService.stop()
            playbackState = .standby
            notifyPlaybackStateChanged()
        }
    }

    func pause() {
        if(playbackState == .playing) {
            timerService.pause()
            playbackState = .paused

            notifyPlaybackStateChanged()
        }
    }
    func resume() {
        if(playbackState == .paused) {
            timerService.resume()
            playbackState = .playing
            notifyPlaybackStateChanged()
        }
    }
}


extension MyController: MyTimerDelegate {

    func getCurrentConfiguration() -> MyConfiguration {
        // 确保返回正确的配置
        return MyConfiguration(
            tempo: tempo,
            beatsPerBar: beatsPerBar,
            currentBeat: currentBeat,
            beatUnit: beatUnit,
            beatStatuses: beatStatuses,
            subdivisionPattern: subdivisionPattern,
            soundSet: soundSet,
            completedBars: completedBars
        )
    }

    func setupTimerCallbacks() {
        // 播放节拍声音
        timerService.onBeatNeeded = { [weak self] status in
            guard let self = self else { return }
            self.audioService.playBeat(status: status)
        }

        // 播放切分音符声音
        timerService.onSubdivisionNeeded = { [weak self] timeOffset, status in
            guard let self = self else { return }
            self.audioService.playBeat(status: status)
        }

        // 节拍完成回调
        timerService.onBeatCompleted = { [weak self] beatIndex in
            guard let self = self else { return }
            self.currentBeat = beatIndex
            self.delegate?.didCurrentBeatChange(beatIndex)
        }

        // 小节即将完成回调
        timerService.onBarWillComplete = { [weak self] nextBarCount in
            guard let self = self else { return }
            print("即将完成第\(nextBarCount)小节")
        }

        // 小节完成回调
        timerService.onBarCompleted = { [weak self] in
            guard let self = self else { return }
            self.completedBars += 1
        }
    }
}
