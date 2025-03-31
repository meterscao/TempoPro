//
//  MetronomeController.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/31.
//
import SwiftUI


class MetronomeController {
    // 依赖
    private var model: MetronomeModel
    private let timingService: TimingService
    private let audioService: AudioService
    private let storageService: UserDefaultsStorageService
    
    // 回调
    var onModelChanged: ((MetronomeModel) -> Void)?
    var onPracticeModeProgress: ((Double, String, Int) -> Void)?
    var onPracticeModeCompleted: (() -> Void)?
    
    // 练习模式计时
    private var practiceTimer: Timer?
    
    init(model: MetronomeModel,
         timingService: TimingService,
         audioService: AudioService,
         storageService: UserDefaultsStorageService) {
        self.model = model
        self.timingService = timingService
        self.audioService = audioService
        self.storageService = storageService
        
        // 加载音效
        audioService.loadSoundSet(model.soundSet)
        
        // 设置计时回调
        setupTimingCallbacks()
    }
    
    private func setupTimingCallbacks() {
        timingService.onBeatTriggered = { [weak self] beatIndex in
            guard let self = self else { return }
            
            // 更新模型
            var updatedModel = self.model
            updatedModel.currentBeat = beatIndex
            self.model = updatedModel
            
            // 通知视图模型
            self.onModelChanged?(self.model)
            
            // 播放音效
            if beatIndex < self.model.beatPatterns.count {
                let pattern = self.model.beatPatterns[beatIndex]
                if pattern != .muted {
                    self.audioService.playSound(for: pattern)
                }
            }
        }
        
        timingService.onBarCompleted = { [weak self] in
            guard let self = self else { return }
            
            // 更新完成小节数
            var updatedModel = self.model
            updatedModel.completedBars += 1
            self.model = updatedModel
            
            // 检查训练模式
            self.checkPracticeMode()
            
            // 通知视图模型
            self.onModelChanged?(self.model)
        }
    }
    
    // 节拍器控制方法
    func start() {
        // 配置计时服务
        timingService.configure(
            tempo: model.tempo,
            beatsPerBar: model.beatsPerBar,
            currentBeat: model.currentBeat
        )
        
        // 启动计时
        timingService.start()
        
        // 更新模型
        var updatedModel = model
        updatedModel.isPlaying = true
        model = updatedModel
        
        // 如果有练习模式，启动练习计时
        if model.practiceMode != nil {
            startPracticeTimer()
        }
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    func stop() {
        // 停止计时
        timingService.stop()
        
        // 停止练习计时
        stopPracticeTimer()
        
        // 更新模型
        var updatedModel = model
        updatedModel.isPlaying = false
        updatedModel.currentBeat = 0
        updatedModel.completedBars = 0
        model = updatedModel
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    func pause() {
        // 暂停计时
        timingService.pause()
        
        // 暂停练习计时
        practiceTimer?.invalidate()
        
        // 更新模型
        var updatedModel = model
        updatedModel.isPlaying = false
        model = updatedModel
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    func resume() {
        // 恢复计时
        timingService.resume()
        
        // 如果有练习模式，恢复练习计时
        if model.practiceMode != nil {
            startPracticeTimer()
        }
        
        // 更新模型
        var updatedModel = model
        updatedModel.isPlaying = true
        model = updatedModel
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    // 更新节拍器设置
    func updateTempo(to newTempo: Int) {
        // 更新模型
        var updatedModel = model
        updatedModel.tempo = newTempo
        model = updatedModel
        
        // 如果正在播放，更新计时器设置
        if model.isPlaying {
            timingService.configure(
                tempo: model.tempo,
                beatsPerBar: model.beatsPerBar,
                currentBeat: model.currentBeat
            )
        }
        
        // 保存设置
        saveSettings()
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    func updateBeatsPerBar(to newBeatsPerBar: Int) {
        // 更新模型
        var updatedModel = model
        updatedModel.beatsPerBar = newBeatsPerBar
        
        // 调整节拍模式数组长度
        if updatedModel.beatPatterns.count > newBeatsPerBar {
            // 如果减少拍数，截断数组
            updatedModel.beatPatterns = Array(updatedModel.beatPatterns.prefix(newBeatsPerBar))
        } else if updatedModel.beatPatterns.count < newBeatsPerBar {
            // 如果增加拍数，添加默认拍
            let additionalBeats = newBeatsPerBar - updatedModel.beatPatterns.count
            updatedModel.beatPatterns.append(contentsOf: Array(repeating: .normal, count: additionalBeats))
        }
        
        model = updatedModel
        
        // 如果正在播放，更新计时器设置
        if model.isPlaying {
            timingService.configure(
                tempo: model.tempo,
                beatsPerBar: model.beatsPerBar,
                currentBeat: min(model.currentBeat, model.beatsPerBar - 1)
            )
        }
        
        // 保存设置
        saveSettings()
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    func changeBeatPattern(at index: Int, to pattern: MetronomeModel.BeatPattern) {
        guard index < model.beatPatterns.count else { return }
        
        // 更新模型
        var updatedModel = model
        updatedModel.beatPatterns[index] = pattern
        model = updatedModel
        
        // 保存设置
        saveSettings()
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    func changeSoundSet(to soundSet: MetronomeModel.SoundSet) {
        // 更新模型
        var updatedModel = model
        updatedModel.soundSet = soundSet
        model = updatedModel
        
        // 加载音效
        audioService.loadSoundSet(soundSet)
        
        // 保存设置
        saveSettings()
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    func setSubdivision(to subdivision: MetronomeModel.Subdivision) {
        // 更新模型
        var updatedModel = model
        updatedModel.subdivision = subdivision
        model = updatedModel
        
        // 保存设置
        saveSettings()
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    // 训练模式方法
    func setPracticeMode(_ mode: MetronomeModel.PracticeMode?) {
        // 更新模型
        var updatedModel = model
        updatedModel.practiceMode = mode
        model = updatedModel
        
        // 如果正在播放并且设置了新的训练模式，启动练习计时
        if model.isPlaying && mode != nil {
            startPracticeTimer()
        } else {
            stopPracticeTimer()
        }
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    // 持久化方法
    func loadSavedSettings() {
        guard let settings = storageService.loadSettings() else { return }
        
        // 创建新模型
        var newModel = MetronomeModel()
        newModel.tempo = settings.tempo
        newModel.beatsPerBar = settings.beatsPerBar
        newModel.beatUnit = settings.beatUnit
        newModel.beatPatterns = settings.beatPatterns.compactMap {
            MetronomeModel.BeatPattern(rawValue: $0)
        }
        newModel.soundSet = MetronomeModel.SoundSet(rawValue: settings.soundSet) ?? .woodblock
        newModel.subdivision = MetronomeModel.Subdivision(rawValue: settings.subdivision) ?? .none
        
        // 更新模型
        model = newModel
        
        // 加载音效
        audioService.loadSoundSet(model.soundSet)
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    func saveSettings() {
        let settings = MetronomeSettings(from: model)
        storageService.saveSettings(settings)
    }
    
    func saveAsPreset(name: String) {
        let settings = MetronomeSettings(from: model)
        let newPreset = MetronomePreset(name: name, settings: settings)
        
        var presets = storageService.loadPresets() ?? []
        presets.append(newPreset)
        storageService.savePresets(presets)
    }
    
    func loadPreset(_ preset: MetronomePreset) {
        // 从预设创建新模型
        var newModel = MetronomeModel()
        newModel.tempo = preset.settings.tempo
        newModel.beatsPerBar = preset.settings.beatsPerBar
        newModel.beatUnit = preset.settings.beatUnit
        newModel.beatPatterns = preset.settings.beatPatterns.compactMap {
            MetronomeModel.BeatPattern(rawValue: $0)
        }
        newModel.soundSet = MetronomeModel.SoundSet(rawValue: preset.settings.soundSet) ?? .woodblock
        newModel.subdivision = MetronomeModel.Subdivision(rawValue: preset.settings.subdivision) ?? .none
        
        // 更新模型
        model = newModel
        
        // 加载音效
        audioService.loadSoundSet(model.soundSet)
        
        // 保存当前设置
        saveSettings()
        
        // 通知视图模型
        onModelChanged?(model)
    }
    
    func getAllPresets() -> [MetronomePreset] {
        return storageService.loadPresets() ?? []
    }
    
    // 内部辅助方法
    private func checkPracticeMode() {
        guard let practiceMode = model.practiceMode else { return }
        
        switch practiceMode {
        case .barCount(let count):
            if model.completedBars >= count {
                completePractice()
            }
        case .combined(_, let barCount):
            if model.completedBars >= barCount {
                completePractice()
            }
        default:
            break
        }
    }
    
    private func startPracticeTimer() {
        stopPracticeTimer()
        
        guard let practiceMode = model.practiceMode else { return }
        
        switch practiceMode {
        case .countdown(let minutes), .combined(let minutes, _):
            let totalSeconds = minutes * 60
            var elapsedSeconds = 0
            
            practiceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                elapsedSeconds += 1
                
                // 计算进度
                let progress = Double(elapsedSeconds) / Double(totalSeconds)
                let remainingSeconds = totalSeconds - elapsedSeconds
                let remainingMinutes = remainingSeconds / 60
                let remainingSecondsModulo = remainingSeconds % 60
                let timeString = String(format: "%d:%02d", remainingMinutes, remainingSecondsModulo)
                // 发送进度回调
                self.onPracticeModeProgress?(progress, timeString, 0)
                
                // 检查是否完成
                if elapsedSeconds >= totalSeconds {
                    self.completePractice()
                }
            }
        default:
            break
        }
    }

    private func stopPracticeTimer() {
        practiceTimer?.invalidate()
        practiceTimer = nil
    }

    private func completePractice() {
        // 停止计时
        stop()
        
        // 清除练习模式
        var updatedModel = model
        updatedModel.practiceMode = nil
        model = updatedModel
        
        // 通知完成
        onPracticeModeCompleted?()
        onModelChanged?(model)
    }
    
    
}
