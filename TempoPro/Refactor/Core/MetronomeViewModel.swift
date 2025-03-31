//
//  MetronomeViewModel.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/31.
//
import SwiftUI


class MetronomeViewModel: ObservableObject {
    // UI显示属性
    @Published var tempo: Int = 120
    @Published var beatsPerBar: Int = 4
    @Published var beatUnit: Int = 4
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    @Published var currentBeatDisplay: Int = 1 // 从1开始显示
    @Published var completedBars: Int = 0
    
    // 节拍模式
    @Published var beatPatterns: [BeatPatternViewModel] = []
    
    // 音效和切分音符
    @Published var availableSoundSets: [SoundSetViewModel] = []
    @Published var selectedSoundSet: String = "woodblock"
    @Published var availableSubdivisions: [SubdivisionViewModel] = []
    @Published var selectedSubdivision: String = "none"
    
    // 练习模式
    @Published var isPracticeModeActive: Bool = false
    @Published var practiceMode: String = "none" // none, countdown, barCount, combined
    @Published var practiceMinutes: Int = 5
    @Published var practiceBarCount: Int = 20
    @Published var practiceProgress: Double = 0.0
    @Published var practiceTimeRemaining: String = ""
    @Published var practiceBarsRemaining: Int = 0
    
    // 预设
    @Published var availablePresets: [PresetViewModel] = []
    
    // 依赖
    private let controller: MetronomeController
    private var model: MetronomeModel
    
    init(controller: MetronomeController, model: MetronomeModel) {
        self.controller = controller
        self.model = model
        
        // 初始化数据
        setupInitialData()
        
        // 设置控制器回调
        setupControllerCallbacks()
    }
    
    private func setupInitialData() {
        // 从模型设置初始值
        updateFromModel(model)
        
        // 初始化可用的音效集
        availableSoundSets = MetronomeModel.SoundSet.allCases.map { soundSet in
            SoundSetViewModel(id: soundSet.rawValue, name: soundSet.displayName)
        }
        
        // 初始化可用的切分音符模式
        availableSubdivisions = MetronomeModel.Subdivision.allCases.map { subdivision in
            SubdivisionViewModel(id: subdivision.rawValue, name: subdivision.displayName)
        }
        
        // 加载预设
        loadPresets()
    }
    
    private func setupControllerCallbacks() {
        // 监听模型变化
        controller.onModelChanged = { [weak self] updatedModel in
            guard let self = self else { return }
            
            // 在主线程更新UI状态
            DispatchQueue.main.async {
                self.updateFromModel(updatedModel)
            }
        }
        
        // 监听练习模式进度
        controller.onPracticeModeProgress = { [weak self] progress, timeRemaining, barsRemaining in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.practiceProgress = progress
                self.practiceTimeRemaining = timeRemaining
                self.practiceBarsRemaining = barsRemaining
            }
        }
        
        // 监听练习模式完成
        controller.onPracticeModeCompleted = { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isPracticeModeActive = false
                self.practiceProgress = 1.0
                self.practiceTimeRemaining = "完成"
                self.practiceBarsRemaining = 0
            }
        }
    }
    
    private func updateFromModel(_ model: MetronomeModel) {
        // 更新属性
        tempo = model.tempo
        beatsPerBar = model.beatsPerBar
        beatUnit = model.beatUnit
        isPlaying = model.isPlaying
        currentBeat = model.currentBeat
        currentBeatDisplay = model.currentBeat + 1
        completedBars = model.completedBars
        
        // 更新节拍模式
        beatPatterns = []
        for (index, pattern) in model.beatPatterns.enumerated() {
            beatPatterns.append(BeatPatternViewModel(
                index: index,
                patternId: pattern.rawValue,
                name: pattern.displayName
            ))
        }
        
        // 更新音效和切分音符选择
        selectedSoundSet = model.soundSet.rawValue
        selectedSubdivision = model.subdivision.rawValue
        
        // 更新练习模式状态
        if let practiceMode = model.practiceMode {
            isPracticeModeActive = true
            
            switch practiceMode {
            case .countdown(let minutes):
                self.practiceMode = "countdown"
                self.practiceMinutes = minutes
                self.practiceBarsRemaining = 0
            case .barCount(let count):
                self.practiceMode = "barCount"
                self.practiceBarCount = count
                self.practiceBarsRemaining = count - completedBars
            case .combined(let minutes, let barCount):
                self.practiceMode = "combined"
                self.practiceMinutes = minutes
                self.practiceBarCount = barCount
                self.practiceBarsRemaining = barCount - completedBars
            }
        } else {
            isPracticeModeActive = false
            practiceMode = "none"
        }
        
        // 保存当前模型引用
        self.model = model
    }
    
    // MARK: - 公共方法 (UI操作)
    
    func togglePlayPause() {
        if isPlaying {
            controller.pause()
        } else {
            if currentBeat == 0 && completedBars == 0 {
                controller.start()
            } else {
                controller.resume()
            }
        }
    }
    
    func stop() {
        controller.stop()
    }
    
    func changeTempo(to newTempo: Int) {
        controller.updateTempo(to: newTempo)
    }
    
    func changeBeatsPerBar(to newBeatsPerBar: Int) {
        controller.updateBeatsPerBar(to: newBeatsPerBar)
    }
    
    func changeBeatPattern(at index: Int, to patternId: String) {
        if let pattern = MetronomeModel.BeatPattern(rawValue: patternId) {
            controller.changeBeatPattern(at: index, to: pattern)
        }
    }
    
    func changeSoundSet(to soundSetId: String) {
        if let soundSet = MetronomeModel.SoundSet(rawValue: soundSetId) {
            controller.changeSoundSet(to: soundSet)
        }
    }
    
    func changeSubdivision(to subdivisionId: String) {
        if let subdivision = MetronomeModel.Subdivision(rawValue: subdivisionId) {
            controller.setSubdivision(to: subdivision)
        }
    }
    
    func startPracticeMode() {
        var mode: MetronomeModel.PracticeMode?
        
        switch practiceMode {
        case "countdown":
            mode = .countdown(minutes: practiceMinutes)
        case "barCount":
            mode = .barCount(count: practiceBarCount)
        case "combined":
            mode = .combined(minutes: practiceMinutes, barCount: practiceBarCount)
        default:
            mode = nil
        }
        
        controller.setPracticeMode(mode)
        
        if mode != nil {
            controller.start()
        }
    }
    
    func stopPracticeMode() {
        controller.setPracticeMode(nil)
        controller.stop()
    }
    
    func saveAsPreset(name: String) {
        controller.saveAsPreset(name: name)
        loadPresets()
    }
    
    func loadPreset(_ presetId: String) {
        if let preset = availablePresets.first(where: { $0.id == presetId })?.model {
            controller.loadPreset(preset)
        }
    }
    
    private func loadPresets() {
        let presets = controller.getAllPresets()
        
        availablePresets = presets.map { preset in
            PresetViewModel(
                id: preset.id,
                name: preset.name,
                description: "\(preset.settings.tempo)bpm, \(preset.settings.beatsPerBar)/\(preset.settings.beatUnit)",
                model: preset
            )
        }
    }
}

// 视图模型辅助类
struct BeatPatternViewModel: Identifiable {
    var id: String { "\(index)-\(patternId)" }
    let index: Int
    let patternId: String
    let name: String
}

struct SoundSetViewModel: Identifiable {
    var id: String
    let name: String
}

struct SubdivisionViewModel: Identifiable {
    var id: String
    let name: String
}

struct PresetViewModel: Identifiable {
    var id: String
    let name: String
    let description: String
    let model: MetronomePreset
}
