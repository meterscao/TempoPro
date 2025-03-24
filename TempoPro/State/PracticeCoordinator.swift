//
//  PracticeMode.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/24.
//


import Foundation
import Combine
import SwiftUI

// 练习模式枚举
enum PracticeMode {
    case none        // 无练习模式
    case countdown   // 倒计时模式
    case progressive // 渐进式模式
}

// 倒计时模式类型
enum CountdownType {
    case time  // 按时间
    case bar   // 按小节
}

// 练习状态
enum PracticeStatus {
    case standby   // 准备状态
    case running   // 正在运行
    case paused    // 暂停状态
    case completed // 完成状态
}

class PracticeCoordinator: ObservableObject, MetronomePlaybackDelegate {
    // MARK: - 公开状态属性
    @Published private(set) var activeMode: PracticeMode = .none
    @Published private(set) var practiceStatus: PracticeStatus = .standby
    
    // 倒计时模式设置
    @Published var countdownType: CountdownType = .time
    @Published var targetTime: Int = 300 // 默认5分钟 (秒)
    @Published var targetBars: Int = 4   // 默认4小节
    @Published var isLoopEnabled: Bool = false
    @Published var isSyncStartEnabled: Bool = true
    @Published var isSyncStopEnabled: Bool = true
    
    // 渐进模式设置
    @Published var progressiveFromBPM: Int = 60
    @Published var progressiveToBPM: Int = 120
    @Published var progressiveIncrement: Int = 5
    @Published var progressiveInterval: Int = 10  // 更新间隔(秒或小节)
    @Published var progressiveType: CountdownType = .time
    
    // 进度状态
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var currentBPM: Int = 60
    @Published private(set) var isCompletingCycle: Bool = false
    
    // MARK: - 私有属性
    private weak var metronomeState: MetronomeState?
    private var timer: Timer?
    private var lastUpdateTime: Int = 0
    private var lastUpdateBar: Int = 0
    private var cancellables = Set<AnyCancellable>()
    private var resetProgressTask: DispatchWorkItem?
    private var stepUpdateTask: DispatchWorkItem?
    
    // MARK: - 初始化
    init(metronomeState: MetronomeState) {
        self.metronomeState = metronomeState
        metronomeState.addDelegate(self)
    }
    
    // MARK: - 公开方法
    
    // 设置练习模式
    func setPracticeMode(_ mode: PracticeMode) {
        // 如果有正在运行的练习，先停止
        if practiceStatus == .running || practiceStatus == .paused {
            stopPractice()
        }
        
        activeMode = mode
        
        // 重置状态
        elapsedSeconds = 0
        practiceStatus = .standby
        
        if mode == .progressive {
            currentBPM = progressiveFromBPM
        }
        
        objectWillChange.send()
    }
    
    // 开始练习
    func startPractice() {
        guard let metronomeState = metronomeState else { return }
        
        // 重置计时状态
        elapsedSeconds = 0
        practiceStatus = .running
        
        // 根据练习模式设置初始状态
        if activeMode == .countdown {
            // 倒计时模式 - 根据同步设置启动节拍器
            if isSyncStartEnabled && !metronomeState.isPlaying {
                metronomeState.play()
            }
        } else if activeMode == .progressive {
            // 渐进模式 - 设置初始BPM并启动节拍器
            currentBPM = progressiveFromBPM
            metronomeState.updateTempo(progressiveFromBPM)
            
            if !metronomeState.isPlaying {
                metronomeState.play()
            }
            
            // 重置更新计数
            lastUpdateTime = 0
            lastUpdateBar = 0
        }
        
        // 启动定时器
        startTimer()
    }
    
    // 暂停练习
    func pausePractice() {
        if practiceStatus != .running { return }
        
        practiceStatus = .paused
        timer?.invalidate()
        timer = nil
        
        // 暂停节拍器
        metronomeState?.pause()
        
        objectWillChange.send()
    }
    
    // 恢复练习
    func resumePractice() {
        if practiceStatus != .paused { return }
        
        practiceStatus = .running
        
        // 恢复节拍器
        metronomeState?.resume()
        
        // 重启定时器
        startTimer()
    }
    
    // 停止练习
    func stopPractice() {
        timer?.invalidate()
        timer = nil
        resetProgressTask?.cancel()
        resetProgressTask = nil
        stepUpdateTask?.cancel()
        stepUpdateTask = nil
        
        // 确保无动画重置进度
        withAnimation(nil) {
            isCompletingCycle = false
        }
        
        practiceStatus = .standby
        elapsedSeconds = 0
        
        // 停止节拍器
        metronomeState?.stop()
        
        objectWillChange.send()
    }
    
    // 获取倒计时显示文本
    func getCountdownDisplayText() -> String {
        if countdownType == .time {
            return formatTime(remainingSeconds)
        } else {
            return "\(remainingBars)"
        }
    }
    
    // 获取渐进式显示文本
    func getProgressiveDisplayText() -> String {
        return "\(currentBPM) BPM"
    }
    
    // MARK: - MetronomePlaybackDelegate 实现
    
    func metronomeDidChangePlaybackState(_ state: PlaybackState) {
        // 如果节拍器停止，且处于练习模式，也停止练习
        if state == .standby && (practiceStatus == .running || practiceStatus == .paused) {
            stopPractice()
        }
    }
    
    func metronomeDidCompleteBeat(beatIndex: Int, isLastBeat: Bool) {
        // 这里可以处理节拍事件
    }
    
    func metronomeDidCompleteBar(barCount: Int) {
        // 检查是否需要更新渐进式BPM
        if activeMode == .progressive && practiceStatus == .running && progressiveType == .bar {
            let barsSinceLastUpdate = barCount - lastUpdateBar
            
            if barsSinceLastUpdate >= progressiveInterval {
                lastUpdateBar = barCount
                updateProgressiveBPM()
            }
        }
        
        // 检查是否完成倒计时小节
        if activeMode == .countdown && practiceStatus == .running && countdownType == .bar {
            if barCount >= targetBars {
                completePractice()
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.elapsedSeconds += 1
            
            // 处理倒计时模式
            if self.activeMode == .countdown && self.countdownType == .time {
                if self.elapsedSeconds >= self.targetTime {
                    self.completePractice()
                }
            }
            
            // 处理渐进模式
            if self.activeMode == .progressive && self.progressiveType == .time {
                let timeSinceLastUpdate = self.elapsedSeconds - self.lastUpdateTime
                
                if timeSinceLastUpdate >= self.progressiveInterval {
                    self.lastUpdateTime = self.elapsedSeconds
                    self.updateProgressiveBPM()
                }
            }
            
            self.objectWillChange.send()
        }
    }
    
    private func updateProgressiveBPM() {
        guard let metronomeState = metronomeState,
              progressiveFromBPM != progressiveToBPM else { return }
        
        // 计算下一个BPM值
        let isIncreasing = progressiveToBPM > progressiveFromBPM
        let nextBPM = isIncreasing ? 
            min(currentBPM + progressiveIncrement, progressiveToBPM) : 
            max(currentBPM - progressiveIncrement, progressiveToBPM)
        
        // 检查是否已达到目标BPM
        if (isIncreasing && nextBPM >= progressiveToBPM) || 
           (!isIncreasing && nextBPM <= progressiveToBPM) {
            // 已达到最终BPM
            currentBPM = progressiveToBPM
            metronomeState.updateTempo(progressiveToBPM)
            
            // 标记练习完成，但不停止节拍器
            practiceStatus = .completed
            timer?.invalidate()
            timer = nil
        } else {
            // 先使进度条动画到100%
            withAnimation(.linear(duration: 0.5)) {
                isCompletingCycle = true
            }
            
            // 创建延迟任务更新BPM
            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                // 无动画地重置进度
                DispatchQueue.main.async {
                    withAnimation(nil) {
                        self.isCompletingCycle = false
                    }
                    
                    // 更新BPM
                    self.currentBPM = nextBPM
                    metronomeState.updateTempo(nextBPM)
                    
                    // 更新时间点
                    if self.progressiveType == .time {
                        self.lastUpdateTime = self.elapsedSeconds
                    } else {
                        if let metronomeState = self.metronomeState {
                            self.lastUpdateBar = metronomeState.completedBars
                        }
                    }
                }
            }
            
            stepUpdateTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
        }
    }
    
    private func completePractice() {
        timer?.invalidate()
        timer = nil
        
        if activeMode == .countdown && isLoopEnabled {
            // 循环模式 - 显示完成状态，再重置
            practiceStatus = .completed
            
            // 取消之前的重置任务
            resetProgressTask?.cancel()
            
            // 设置完成循环标志
            withAnimation(.linear(duration: 0.5)) {
                isCompletingCycle = true
            }
            
            // 创建延迟任务
            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    withAnimation(nil) {
                        self.isCompletingCycle = false
                        self.elapsedSeconds = 0
                    }
                    
                    self.practiceStatus = .running
                    self.startTimer()
                }
            }
            
            resetProgressTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: task)
        } else {
            // 非循环模式，直接完成
            practiceStatus = .completed
            
            if activeMode == .countdown && isSyncStopEnabled {
                metronomeState?.stop()
            }
        }
        
        objectWillChange.send()
    }
    
    // 格式化时间
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - 便捷计算属性
    
    var remainingSeconds: Int {
        return max(0, targetTime - elapsedSeconds)
    }
    
    var remainingBars: Int {
        guard let metronomeState = metronomeState else { return targetBars }
        
        if practiceStatus == .completed {
            return 0
        }
        
        let currentBar = metronomeState.currentBarNumber
        return currentBar <= targetBars ? (targetBars - currentBar + 1) : 0
    }
    
    var progress: CGFloat {
        if isCompletingCycle || practiceStatus == .completed {
            return 1.0
        }
        
        if activeMode == .countdown {
            if countdownType == .time {
                return targetTime > 0 ? CGFloat(elapsedSeconds) / CGFloat(targetTime) : 0.01
            } else {
                guard let metronomeState = metronomeState else { return 0.01 }
                let completedBars = metronomeState.completedBars
                return min(CGFloat(completedBars) / CGFloat(targetBars), 1.0)
            }
        } else if activeMode == .progressive {
            if progressiveFromBPM == progressiveToBPM { return 1.0 }
            
            let totalChange = abs(progressiveToBPM - progressiveFromBPM)
            let currentChange = abs(currentBPM - progressiveFromBPM)
            return min(CGFloat(currentChange) / CGFloat(totalChange), 1.0)
        }
        
        return 0.0
    }
    
    // MARK: - 清理资源
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
        resetProgressTask?.cancel()
        resetProgressTask = nil
        stepUpdateTask?.cancel()
        stepUpdateTask = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        if let metronomeState = metronomeState {
            metronomeState.removeDelegate(self)
        }
    }
}
