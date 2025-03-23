//
//  TimerState.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/21.
//

import Foundation
import Combine
import SwiftUI

// 定义练习模式枚举
enum PracticeMode {
    case countdown
    case step
}

// 定义计时器类型枚举
enum TimerType: String {
    case time = "time"
    case bar = "bar"
}

// 定义计时器状态枚举
enum TimerStatus {
    case standby   // 默认状态
    case running   // 正在运行
    case paused    // 暂停状态
    case completed // 完成状态
}

class PracticeTimerState: ObservableObject {
    // 模式相关
    @Published var practiceMode: PracticeMode = .countdown
    @Published var timerStatus: TimerStatus = .standby
    
    // 模式类型配置 (按时间/按小节)
    @Published var countdownTimerType: TimerType = .time
    @Published var stepTimerType: TimerType = .time
    
    // 当前活动的计时器类型（只读计算属性）
    var activeTimerType: TimerType {
        return practiceMode == .countdown ? countdownTimerType : stepTimerType
    }
    
    // --------- Countdown模式配置 ---------
    // 时间设置
    @Published var selectedHours = 0
    @Published var selectedMinutes = 5
    @Published var selectedSeconds = 0
    
    // 小节设置
    @Published var targetBars = 4 // 默认4小节
    
    // 选项配置
    @Published var isLoopEnabled = false
    @Published var isSyncStartEnabled = true  // 默认开启同步启动
    @Published var isSyncStopEnabled = true   // 默认开启同步停止
    
    // --------- Step模式配置 ---------
    // 渐进式节拍器设置
    @Published var stepFromBPM: Int = 60
    @Published var stepToBPM: Int = 120
    @Published var stepIncrement: Int = 5
    @Published var stepEverySeconds: Int = 10
    @Published var stepEveryBars: Int = 4
    
    // 当前进度状态
    @Published var elapsedSeconds = 0
    @Published var previousCompletedBars = 0 // 记录开始时的小节数
    @Published var currentBPM: Int = 60      // 当前实际BPM值
    
    // 跟踪状态
    private var pausedCompletedBars: Int = 0
    private var lastBPMUpdateTime: Int = 0  // 上次更新BPM的时间点
    private var lastBPMUpdateBar: Int = 0   // 上次更新BPM的小节数
    private var isUpdatingBPM: Bool = false // 防止递归更新的标志
    private var cancellables = Set<AnyCancellable>()
    
    // 引用MetronomeState
    private weak var metronomeState: MetronomeState?
    
    var timer: Timer? = nil
    
    // 添加新属性用于处理进度条动画
    @Published var isCompletingCycle: Bool = false // 标记是否正在完成一个循环
    private var resetProgressTask: DispatchWorkItem? // 用于控制重置进度的任务
    private var stepUpdateTask: DispatchWorkItem? // 用于 Step 模式 BPM 更新的任务
    
    // ------- 通用计算属性 -------
    
    var isTimerRunning: Bool {
        return timerStatus == .running || timerStatus == .paused
    }
    
    var isTimerCompleted: Bool {
        return timerStatus == .completed
    }
    
    var totalSeconds: Int {
        return (selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds
    }
    
    var remainingSeconds: Int {
        return max(0, totalSeconds - elapsedSeconds)
    }
    
    // 在Step模式下，计算还需要多少时间或小节达到目标BPM
    var stepProgress: CGFloat {
        if stepFromBPM == stepToBPM { return 1.0 }
        
        let totalChange = abs(stepToBPM - stepFromBPM)
        let currentChange = abs(currentBPM - stepFromBPM)
        return min(CGFloat(currentChange) / CGFloat(totalChange), 1.0)
    }
    
    // 在Step模式下，计算当前循环的进度（即距离下一次BPM变化的进度）
    var stepCycleProgress: CGFloat {
        // 如果正在完成循环，返回100%
        if isCompletingCycle {
            return 1.0
        }
        
        if practiceMode != .step || timerStatus != .running {
            return 0.0
        }
        
        if activeTimerType == .time {
            // 时间模式 - 计算当前时间周期的进度
            let timeSinceLastUpdate = elapsedSeconds - lastBPMUpdateTime
            return min(CGFloat(timeSinceLastUpdate) / CGFloat(stepEverySeconds), 1.0)
        } else {
            // 小节模式 - 计算当前小节周期的进度
            guard let metronomeState = metronomeState else { return 0.0 }
            
            let barsSinceLastUpdate = metronomeState.completedBars - lastBPMUpdateBar
            return min(CGFloat(barsSinceLastUpdate) / CGFloat(stepEveryBars), 1.0)
        }
    }
    
    // 倒计时或小节计数的进度
    var progress: CGFloat {
        // 如果正在完成循环，返回100%
        if isCompletingCycle {
            return 1.0
        }
        
        if practiceMode == .countdown {
            // 倒计时模式进度
            if activeTimerType == .time {
                return totalSeconds > 0 ? CGFloat(elapsedSeconds) / CGFloat(totalSeconds) : 0.01
            } else {
                // 小节进度 - 需要考虑暂停状态
                let currentCompletedBars = timerStatus == .paused ? 
                    pausedCompletedBars : (metronomeState?.completedBars ?? 0)
                
                let completedSinceStart = max(0, currentCompletedBars - previousCompletedBars)
                let barProgress = targetBars > 0 ? 
                    CGFloat(completedSinceStart) / CGFloat(targetBars) : 0.01
                
                return min(barProgress, 1.0)
            }
        } else {
            // Step模式下显示BPM变化进度
            return stepProgress
        }
    }
    
    // 根据当前的计时模式显示剩余小节数
    var remainingBars: Int {
        // 只有小节模式才计算剩余小节
        guard activeTimerType == .bar else { return 0 }
        
        guard let metronomeState = metronomeState else { return targetBars }
        
        // 如果是暂停状态，使用暂停时记录的小节数
        let currentCompletedBars = timerStatus == .paused ? 
            pausedCompletedBars : metronomeState.completedBars
        
        // 计算自计时开始后完成的小节数
        let completedSinceStart = max(0, currentCompletedBars - previousCompletedBars)
        
        // 计算剩余小节数
        return max(0, targetBars - completedSinceStart)
    }
    
    // ------- 初始化与设置 -------
    
    // 设置MetronomeState引用方法
    func setMetronomeState(_ metronomeState: MetronomeState) {
        self.metronomeState = metronomeState
        
        // 订阅 MetronomeState 的变化
        metronomeState.objectWillChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.timerStatus == .running {
                    if self.practiceMode == .countdown && self.activeTimerType == .bar {
                        // CountDown模式 - 小节计时
                        let currentCompletedBars = metronomeState.completedBars
                        
                        // 计算从开始以来完成的小节数
                        let completedSinceStart = max(0, currentCompletedBars - self.previousCompletedBars)
                        
                        // 如果达到目标小节数，完成计时
                        if completedSinceStart >= self.targetBars {
                            self.completeTimer()
                        }
                    } else if self.practiceMode == .step && self.activeTimerType == .bar {
                        // Step模式 - 小节计时
                        let currentCompletedBars = metronomeState.completedBars
                        
                        // 计算从上次BPM更新以来完成的小节数
                        let completedSinceLastUpdate = currentCompletedBars - self.lastBPMUpdateBar
                        
                        // 如果完成了设定的小节数，更新BPM
                        if completedSinceLastUpdate >= self.stepEveryBars && !self.isUpdatingBPM {
                            // 设置更新标志，并使用主线程异步执行避免递归
                            DispatchQueue.main.async {
                                self.lastBPMUpdateBar = currentCompletedBars
                                self.updateStepBPM()
                            }
                        }
                    }
                    
                    // 通知UI更新
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    // 设置计时器类型
    func setTimerType(_ type: TimerType) {
        if practiceMode == .countdown {
            countdownTimerType = type
        } else {
            stepTimerType = type
        }
        
        print("DEBUG: 计时类型变更 - \(practiceMode) 模式切换到 \(type)")
        
        // 当切换到小节模式时，重置previousCompletedBars
        if type == .bar {
            previousCompletedBars = metronomeState?.completedBars ?? 0
            print("DEBUG: 切换到小节模式，重置previousCompletedBars为当前值: \(previousCompletedBars)")
        }
    }
    
    // ------- 倒计时功能 -------
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // 获取已完成小节数
    var completedBars: Int {
        return metronomeState?.completedBars ?? 0
    }
    
    // 开始计时器
    func startTimer() {
        // 检查是否有其他类型的练习正在进行
        if isAnyTimerRunning() && practiceMode == .countdown {
            // 如果是倒计时模式，且已有计时器运行，则不允许启动
            print("DEBUG: 无法启动倒计时，已有其他练习正在进行")
            return
        } else if isAnyTimerRunning() && practiceMode == .step {
            // 如果是步进模式，且已有计时器运行，则不允许启动
            print("DEBUG: 无法启动渐进练习，已有其他练习正在进行")
            return
        }
        
        if timerStatus != .standby {
            stopTimer()
        }
        
        guard let metronomeState = metronomeState else { return }
        
        // 记录当前已完成的小节数和时间
        previousCompletedBars = metronomeState.completedBars
        elapsedSeconds = 0
        timerStatus = .running
        
        if practiceMode == .countdown {
            // Countdown模式 - 根据同步启动设置决定是否启动节拍器
            if isSyncStartEnabled && !metronomeState.isPlaying {
                metronomeState.play()
                // 由于play()会重置completedBars，我们也需要更新previousCompletedBars
                previousCompletedBars = 0
            }
        } else {
            // Step模式 - 总是启动节拍器
            if !metronomeState.isPlaying {
                // 设置初始BPM并启动
                currentBPM = stepFromBPM
                metronomeState.updateTempo(stepFromBPM)
                metronomeState.play()
                previousCompletedBars = 0
            } else {
                // 如果节拍器已在运行，只更新BPM
                currentBPM = stepFromBPM
                metronomeState.updateTempo(stepFromBPM)
            }
            
            // 设置初始状态
            lastBPMUpdateTime = 0
            lastBPMUpdateBar = metronomeState.completedBars
        }
        
        startTimerTick()
    }
    
    func startTimerTick() {
        timerStatus = .running
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 增加已经过时间
            self.elapsedSeconds += 1
            
            if self.practiceMode == .countdown {
                // CountDown模式计时
                if self.activeTimerType == .time {
                    if self.elapsedSeconds >= self.totalSeconds {
                        self.completeTimer()
                    }
                }
            } else {
                // Step模式计时
                if self.activeTimerType == .time {
                    // 按时间增加BPM
                    let timeSinceLastUpdate = self.elapsedSeconds - self.lastBPMUpdateTime
                    
                    if timeSinceLastUpdate >= self.stepEverySeconds {
                        self.updateStepBPM()
                        self.lastBPMUpdateTime = self.elapsedSeconds
                    }
                }
            }
            
            // 更新UI
            self.objectWillChange.send()
        }
    }
    
    // 更新Step模式的BPM值
    func updateStepBPM() {
        // 防止递归调用和已经在更新的情况
        if isUpdatingBPM {
            return
        }
        
        isUpdatingBPM = true
        
        // 取消之前的更新任务（如果有）
        stepUpdateTask?.cancel()
        
        guard let metronomeState = metronomeState,
              stepFromBPM != stepToBPM else {
            isUpdatingBPM = false
            return
        }
        
        // 计算下一个BPM值
        let isIncreasing = stepToBPM > stepFromBPM
        let nextBPM = isIncreasing ? 
            min(currentBPM + stepIncrement, stepToBPM) : 
            max(currentBPM + stepIncrement, stepToBPM) // stepIncrement可能为负数
        
        // 检查是否已达到目标BPM
        if (isIncreasing && nextBPM >= stepToBPM) || 
           (!isIncreasing && nextBPM <= stepToBPM) {
            // 已达到最终BPM
            currentBPM = stepToBPM
            
            // 安全地更新节拍器
            DispatchQueue.main.async {
                metronomeState.updateTempo(self.stepToBPM)
                
                // 标记练习完成，但不停止节拍器
                self.timerStatus = .completed
                self.timer?.invalidate()
                self.timer = nil
                
                // 完成后重置标志
                self.isUpdatingBPM = false
            }
        } else {
            // 先使进度条动画到100%
            withAnimation(.linear(duration: 0.5)) {
                self.isCompletingCycle = true
            }
            
            // 创建延迟任务
            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                // 无动画地重置进度并更新BPM
                DispatchQueue.main.async {
                    // 关闭动画重置进度
                    withAnimation(nil) {
                        self.isCompletingCycle = false
                    }
                    
                    // 更新到下一个BPM值
                    self.currentBPM = nextBPM
                    
                    // 记录当前更新时间点
                    if self.activeTimerType == .time {
                        self.lastBPMUpdateTime = self.elapsedSeconds
                    } else {
                        self.lastBPMUpdateBar = metronomeState.completedBars
                    }
                    
                    // 更新节拍器
                    metronomeState.updateTempo(self.currentBPM)
                    
                    // 完成后重置标志
                    self.isUpdatingBPM = false
                }
            }
            
            // 存储任务引用
            stepUpdateTask = task
            
            // 延迟0.5秒执行，与进度条动画时间一致
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
        }
        
        print("DEBUG: 更新BPM到 \(currentBPM)")
    }
    
    // 提取出计时完成的逻辑
    private func completeTimer() {
        self.timer?.invalidate()
        self.timer = nil
        
        if self.practiceMode == .countdown && self.isLoopEnabled {
            // 循环模式 - 先显示完成状态，再重置计时器
            self.timerStatus = .completed
            
            // 取消之前的重置任务（如果有）
            resetProgressTask?.cancel()
            
            // 设置完成循环标志，使进度显示100%
            withAnimation(.linear(duration: 0.5)) {
                self.isCompletingCycle = true
            }
            
            // 创建新的延迟任务
            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                // 在主线程上无动画地重置进度
                DispatchQueue.main.async {
                    // 关闭动画
                    withAnimation(nil) {
                        self.isCompletingCycle = false
                        self.elapsedSeconds = 0
                        self.previousCompletedBars = self.metronomeState?.completedBars ?? 0
                    }
                    
                    // 设置状态并重启计时器
                    self.timerStatus = .running
                    self.startTimerTick()
                }
            }
            
            // 存储任务引用
            resetProgressTask = task
            
            // 延迟执行重置，给足够时间显示完成状态（1秒）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: task)
        } else {
            // 非循环模式，直接完成
            self.timerStatus = .completed
            
            if self.practiceMode == .countdown && self.isSyncStopEnabled {
                // 计时结束时根据同步停止设置决定是否停止节拍器
                self.metronomeState?.stop()
            }
        }
        // Step模式下完成后不停止节拍器，保持最终BPM继续运行
    }
    
    // 计算下一个BPM值
    func getNextBPM() -> Int {
        let isIncreasing = stepToBPM > stepFromBPM
        let nextBPM = isIncreasing ? 
            min(currentBPM + stepIncrement, stepToBPM) : 
            max(currentBPM + stepIncrement, stepToBPM) // stepIncrement可能为负数
        
        // 检查是否已达到目标BPM
        if (isIncreasing && nextBPM >= stepToBPM) || 
           (!isIncreasing && nextBPM <= stepToBPM) {
            return stepToBPM
        } else {
            return nextBPM
        }
    }
    
    func togglePause() {
        if timerStatus == .paused {
            // 从暂停恢复
            timerStatus = .running
            
            // 启动计时器
            startTimerTick()
            
            // 恢复节拍器播放 - 使用新的resume方法
            metronomeState?.resume()
        } else if timerStatus == .running {
            // 暂停
            timer?.invalidate()
            timer = nil
            timerStatus = .paused

            // 记录当前状态
            if activeTimerType == .bar {
                pausedCompletedBars = metronomeState?.completedBars ?? 0
                print("DEBUG: 暂停时记录completedBars: \(pausedCompletedBars)")
            }
            
            // 暂停节拍器 - 使用新的pause方法
            metronomeState?.pause()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        resetProgressTask?.cancel()
        resetProgressTask = nil
        stepUpdateTask?.cancel()
        stepUpdateTask = nil
        
        // 确保无动画重置所有状态
        withAnimation(nil) {
            isCompletingCycle = false
        }
        
        timerStatus = .standby
        elapsedSeconds = 0
        
        
        metronomeState?.stop()
        
    }
    
    // 清理资源
    func cleanup() {
        timer?.invalidate()
        timer = nil
        resetProgressTask?.cancel()
        resetProgressTask = nil
        stepUpdateTask?.cancel()
        stepUpdateTask = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    // 检查是否有任何类型的计时器正在运行
    func isAnyTimerRunning() -> Bool {
        return timerStatus == .running || timerStatus == .paused
    }
    
    // 获取当前正在运行的练习模式（如果有）
    func getRunningPracticeMode() -> PracticeMode? {
        if isAnyTimerRunning() {
            return practiceMode
        }
        return nil
    }
    
    // 检查是否可以启动新的练习
    func canStartNewPractice(mode: PracticeMode) -> Bool {
        // 如果没有计时器运行，或者要启动的正是当前模式，则可以启动
        if !isAnyTimerRunning() || mode == practiceMode {
            return true
        }
        return false
    }
    
    // 获取无法启动新练习的提示信息
    func getCannotStartMessage() -> String {
        if practiceMode == .countdown {
            return "渐进练习正在进行中，请先停止再开始新的倒计时"
        } else {
            return "倒计时正在进行中，请先停止再开始新的渐进练习"
        }
    }
    
    // 计算Step模式下距离下一次BPM更新的剩余秒数
    func getRemainingSecondsToNextUpdate() -> Int {
        if activeTimerType != .time || practiceMode != .step {
            return 0
        }
        
        let timeSinceLastUpdate = elapsedSeconds - lastBPMUpdateTime
        return max(0, stepEverySeconds - timeSinceLastUpdate)
    }
    
    // 计算Step模式下距离下一次BPM更新的剩余小节数
    func getRemainingBarsToNextUpdate() -> Int {
        if activeTimerType != .bar || practiceMode != .step {
            return 0
        }
        
        guard let metronomeState = metronomeState else { return 0 }
        
        let barsSinceLastUpdate = metronomeState.completedBars - lastBPMUpdateBar
        return max(0, stepEveryBars - barsSinceLastUpdate)
    }
}
