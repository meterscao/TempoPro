//
//  MyController.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/2.
//

import SwiftUI

// MARK: - Types

/// 节拍器播放状态
enum PlaybackState {
    /// 默认状态/停止状态
    case standby
    /// 正在播放状态
    case playing
    /// 暂停状态
    case paused
}

// MARK: - Protocols

/// 节拍器控制器代理协议
/// 用于向外部通知节拍器状态变化
protocol MyControllerDelegate: AnyObject {
    /// 当速度改变时调用
    /// - Parameter tempo: 新的速度值
    func didTempoChange(_ tempo: Int)
    
    /// 当每小节拍数改变时调用
    /// - Parameter beatsPerBar: 新的每小节拍数
    func didBeatsPerBarChange(_ beatsPerBar: Int)
    
    /// 当节拍单位改变时调用
    /// - Parameter beatUnit: 新的节拍单位
    func didBeatUnitChange(_ beatUnit: Int)
    
    /// 当节拍状态列表改变时调用
    /// - Parameter beatStatuses: 新的节拍状态列表
    func didBeatStatusesChange(_ beatStatuses: [BeatStatus])
    
    /// 当切分音符模式改变时调用
    /// - Parameter subdivisionPattern: 新的切分音符模式
    func didSubdivisionPatternChange(_ subdivisionPattern: SubdivisionPattern)
    
    /// 当音效集改变时调用
    /// - Parameter soundSet: 新的音效集
    func didSoundSetChange(_ soundSet: SoundSet)
    
    /// 当播放状态改变时调用
    /// - Parameter playbackState: 新的播放状态
    func didPlaybackStateChange(_ playbackState: PlaybackState)
    
    /// 当当前节拍改变时调用
    /// - Parameter currentBeat: 新的当前节拍索引
    func didCurrentBeatChange(_ currentBeat: Int)
}

// MARK: - Main Controller

/// 节拍器控制器
/// 负责协调节拍器的各个组件，管理播放状态和设置
class MyController {
    // MARK: - Properties
    
    /// 代理对象，用于向外部通知状态变化
    weak var delegate: MyControllerDelegate?

    // 节拍器基本参数
    private var tempo: Int
    private var beatsPerBar: Int
    private var beatUnit: Int
    private var beatStatuses: [BeatStatus]
    private var subdivisionPattern: SubdivisionPattern
    private var soundSet: SoundSet

    // 播放状态
    private var playbackState: PlaybackState = .standby
    private var currentBeat: Int = 0
    private var completedBars: Int = 0

    // 服务
    private let settingsService: MySettingsService
    private let audioService: MyAudioService
    private let timerService: MyTimerService


    // 回调
    var onBarCompleted: (() -> Void)?

    // MARK: - Initialization

    /// 初始化节拍器控制器
    /// 加载保存的设置并初始化各个服务
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

        // 初始化音频服务
        self.audioService = MyAudioService(defaultSoundSet: soundSet)

        // 初始化定时器服务
        self.timerService = MyTimerService()
        self.timerService.setDelegate(self)
        self.setupTimerCallbacks()
    }

    // MARK: - Private Methods

    /// 设置定时器回调
    /// 配置定时器服务的各种回调函数，处理节拍和小节的播放逻辑
    private func setupTimerCallbacks() {
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
            self.onBarCompleted?()
        }
    }

    // MARK: - Playback Control

    /// 开始播放
    /// 从停止状态开始播放节拍器
    func play() {
        if(playbackState == .standby) {
            timerService.start()
            playbackState = .playing
            delegate?.didPlaybackStateChange(playbackState)
        }
    }

    /// 停止播放
    /// 停止节拍器并重置状态
    func stop() {
        if(playbackState == .playing) {
            timerService.stop()
            playbackState = .standby
            delegate?.didPlaybackStateChange(playbackState)
        }
    }

    /// 暂停播放
    /// 暂时停止播放，但保持当前状态
    func pause() {
        if(playbackState == .playing) {
            timerService.pause()
            playbackState = .paused
            delegate?.didPlaybackStateChange(playbackState)
        }
    }

    /// 恢复播放
    /// 从暂停状态恢复播放
    func resume() {
        if(playbackState == .paused) {
            timerService.resume()
            playbackState = .playing
            delegate?.didPlaybackStateChange(playbackState)
        }
    }

    // MARK: - Settings Update Methods

    /// 更新速度
    /// - Parameter tempo: 新的速度值（30-240）
    func updateTempo(_ tempo: Int) {
        let validTempo = max(30, min(240, tempo))
        if self.tempo != validTempo {
            self.tempo = validTempo
            settingsService.saveTempo(validTempo)
            delegate?.didTempoChange(validTempo)
        }
    }

    /// 更新每小节拍数
    /// - Parameter beatsPerBar: 新的每小节拍数（1-16）
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

    /// 更新节拍单位
    /// - Parameter beatUnit: 新的节拍单位（1-16）
    func updateBeatUnit(_ beatUnit: Int) {
        let validBeatUnit = max(1, min(16, beatUnit))
        if self.beatUnit != validBeatUnit {
            self.beatUnit = validBeatUnit
            settingsService.saveBeatUnit(validBeatUnit)
            delegate?.didBeatUnitChange(validBeatUnit)
        }
    }

    /// 更新节拍状态列表
    /// - Parameter beatStatuses: 新的节拍状态列表
    func updateBeatStatuses(_ beatStatuses: [BeatStatus]) {
        if self.beatStatuses != beatStatuses {
            self.beatStatuses = beatStatuses
            settingsService.saveBeatStatuses(beatStatuses)
            delegate?.didBeatStatusesChange(beatStatuses)
        }
    }

    /// 更新切分音符模式
    /// - Parameter pattern: 新的切分音符模式
    func updateSubdivisionPattern(_ pattern: SubdivisionPattern) {
        guard pattern.name != subdivisionPattern.name else { return }
        self.subdivisionPattern = pattern
        settingsService.saveSubdivisionPattern(pattern)
        delegate?.didSubdivisionPatternChange(pattern)
    }

    /// 更新音效集
    /// - Parameter newSoundSet: 新的音效集
    func updateSoundSet(_ newSoundSet: SoundSet) {
        guard newSoundSet.key != soundSet.key else { return }
        self.soundSet = newSoundSet
        settingsService.saveSoundSet(newSoundSet)
        delegate?.didSoundSetChange(newSoundSet)
    }

    // MARK: - State Access Methods
    
    /// 获取当前速度
    /// - Returns: 当前速度值
    func getTempo() -> Int {
        return tempo
    }
    
    /// 获取每小节拍数
    /// - Returns: 当前每小节拍数
    func getBeatsPerBar() -> Int {
        return beatsPerBar
    }
    
    /// 获取节拍单位
    /// - Returns: 当前节拍单位
    func getBeatUnit() -> Int {
        return beatUnit
    }
    
    /// 获取节拍状态列表
    /// - Returns: 当前节拍状态列表
    func getBeatStatuses() -> [BeatStatus] {
        return beatStatuses
    }
    
    /// 获取切分音符模式
    /// - Returns: 当前切分音符模式
    func getSubdivisionPattern() -> SubdivisionPattern {
        return subdivisionPattern
    }
    
    /// 获取音效集
    /// - Returns: 当前音效集
    func getSoundSet() -> SoundSet {
        return soundSet
    }
    
    /// 获取播放状态
    /// - Returns: 当前播放状态
    func getPlaybackState() -> PlaybackState {
        return playbackState
    }
    
    /// 获取当前节拍
    /// - Returns: 当前节拍索引
    func getCurrentBeat() -> Int {
        return currentBeat
    }
}

// MARK: - MyTimerDelegate

extension MyController: MyTimerDelegate {
    /// 获取当前节拍器配置
    /// - Returns: 包含所有当前设置的配置对象
    func getCurrentConfiguration() -> MyConfiguration {
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
}
