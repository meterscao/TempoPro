//
//  PrcticeViewModel.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/3.
//

import SwiftUI

class PracticeViewModel: ObservableObject, PracticeControllerDelegate {
    @Published var practiceMode: PracticeMode = .none
    @Published var countdownType: CountdownType
    @Published var practiceStatus: PracticeStatus
    @Published var targetTime: Int
    @Published var targetBars: Int
    @Published var remainingTime: Int
    @Published var remainingBars: Int
    @Published var isLoopEnabled: Bool

    @Published var timeProgress: Double = 0.0
    @Published var barProgress: Double = 0.0
    
    // 循环相关属性
    @Published var currentCycle: Int = 1
    @Published var totalCycles: Int = 1
    
    // 渐进模式属性
    @Published var startBPM: Int = 60
    @Published var currentBPM: Int = 60
    @Published var targetBPM: Int = 120
    @Published var stepBPM: Int = 5
    @Published var nextStageBPM: Int = 65

    private let practiceController: PracticeController

    init(practiceController: PracticeController) {
        self.practiceController = practiceController

        self.practiceMode = practiceController.getPracticeMode()
        self.countdownType = practiceController.getCountdownType()
        self.practiceStatus = practiceController.getPracticeStatus()
        self.targetTime = practiceController.getTargetTime()
        self.targetBars = practiceController.getTargetBars()
        self.remainingTime = practiceController.getRemainingTime()
        self.remainingBars = practiceController.getRemainingBars()
        self.isLoopEnabled = practiceController.getIsLoopEnabled()
        self.startBPM = practiceController.getStartBPM()
        self.targetBPM = practiceController.getTargetBPM()
        self.stepBPM = practiceController.getStepBPM()
        
        // 初始化循环信息
        if let cycleInfo = practiceController.getCurrentCycleInfo() {
            self.currentCycle = cycleInfo.currentCycle
            self.totalCycles = cycleInfo.totalCycles
        }
        
        // 初始化阶段信息
        if let stageInfo = practiceController.getStageInfo() {
            self.currentBPM = stageInfo.currentBPM
            self.nextStageBPM = stageInfo.nextBPM
        }

        practiceController.delegate = self
    }
    

    // MARK: - 委托方法
    
    func didPracticeModeChange(_ newPracticeMode: PracticeMode) {
        DispatchQueue.main.async {
            print("🔄 练习模式切换: \(self.practiceMode) -> \(newPracticeMode)")
            self.practiceMode = newPracticeMode
        }
    }

    func didPracticeStatusChange(_ newStatus: PracticeStatus) {
        DispatchQueue.main.async {
            self.practiceStatus = newStatus
        }
    }

    func didCountdownTypeChange(_ newCountdownType: CountdownType) {
        DispatchQueue.main.async {
            print("🔄 类型切换: \(self.countdownType) -> \(newCountdownType), 目标时间: \(self.targetTime), 剩余时间: \(self.remainingTime), 目标小节: \(self.targetBars), 剩余小节: \(self.remainingBars)")
            self.countdownType = newCountdownType
        }
    }

    func didTargetTimeChange(_ newTargetTime: Int) {
        DispatchQueue.main.async {
            print("⏱️ 目标时间更新: \(self.targetTime) -> \(newTargetTime)")
            self.targetTime = newTargetTime
        }
    }

    func didTargetBarsChange(_ newTargetBars: Int) {
        DispatchQueue.main.async {
            print("🎵 目标小节更新: \(self.targetBars) -> \(newTargetBars)")
            self.targetBars = newTargetBars
        }
    }   

    func didRemainingTimeChange(_ newRemainingTime: Int) {
        DispatchQueue.main.async {
            print("⏱️ 剩余时间更新: \(self.remainingTime) -> \(newRemainingTime)")
            self.remainingTime = newRemainingTime
            self.timeProgress = 1 - Double(newRemainingTime) / Double(self.targetTime)
        }
    }

    func didRemainingBarsChange(_ newRemainingBars: Int) {
        DispatchQueue.main.async {
            print("🎵 剩余小节更新: \(self.remainingBars) -> \(newRemainingBars)")
            self.remainingBars = newRemainingBars
            self.barProgress = 1 - Double(newRemainingBars) / Double(self.targetBars)
        }
    }

    func didIsLoopEnabledChange(_ newIsLoopEnabled: Bool) {
        DispatchQueue.main.async {
            self.isLoopEnabled = newIsLoopEnabled
        }
    }
    
    func didCurrentCycleInfoChange(_ currentCycle: Int, _ totalCycles: Int) {
        DispatchQueue.main.async {
            print("🔄 循环信息更新: \(self.currentCycle)/\(self.totalCycles) -> \(currentCycle)/\(totalCycles)")
            self.currentCycle = currentCycle
            self.totalCycles = totalCycles
        }
    }
    
    func didStageInfoChange(_ currentBPM: Int, _ nextBPM: Int) {
        DispatchQueue.main.async {
            print("🎵 阶段信息更新: 当前BPM = \(currentBPM), 下一BPM = \(nextBPM)")
            self.currentBPM = currentBPM
            self.nextStageBPM = nextBPM
        }
    }
    
    func didBPMChange(_ newBPM: Int) {
        DispatchQueue.main.async {
            print("🎵 BPM更新: \(self.currentBPM) -> \(newBPM)")
            self.currentBPM = newBPM
        }
    }

    // MARK: - Action Methods

    func startPractice() {
        practiceController.startPractice()
    }

    func pausePractice() {
        practiceController.pausePractice()
    }

    func resumePractice() {
        practiceController.resumePractice()
    }

    func stopPractice() {
        practiceController.stopPractice()
    }


    // MARK: - 更新方法 
    func updateCountdownType(_ newCountdownType: CountdownType) {
        practiceController.updateCountdownType(newCountdownType)
    }

    func updateTargetTime(_ newTargetTime: Int) {
        practiceController.updateTargetTime(newTargetTime)
    }

    func updateTargetBars(_ newTargetBars: Int) {
        practiceController.updateTargetBars(newTargetBars)
    }

    func updateIsLoopEnabled(_ newIsLoopEnabled: Bool) {
        practiceController.updateIsLoopEnabled(newIsLoopEnabled)
    }   
    
    func updateStartBPM(_ newBPM: Int) {
        practiceController.updateStartBPM(newBPM)
    }
    
    func updateTargetBPM(_ newBPM: Int) {
        practiceController.updateTargetBPM(newBPM)
    }
    
    func updateStepBPM(_ newStep: Int) {
        practiceController.updateStepBPM(newStep)
    }
    
    // MARK: - 模式切换方法
    
    /// 切换到倒计时练习模式
    /// - Parameters:
    ///   - countdownType: 倒计时类型（时间/小节）
    ///   - isLoopEnabled: 是否启用循环
    func setupCountdownMode(countdownType: CountdownType = .time, isLoopEnabled: Bool = false) {
        practiceController.setupCountdownPractice(countdownType: countdownType, isLoopEnabled: isLoopEnabled)
    }
    
    /// 切换到渐进式练习模式
    /// - Parameters:
    ///   - startBPM: 起始BPM
    ///   - targetBPM: 目标BPM
    ///   - stepBPM: BPM步长
    ///   - countdownType: 倒计时类型（时间/小节）
    func setupProgressiveMode(startBPM: Int, targetBPM: Int, stepBPM: Int, countdownType: CountdownType = .time) {
        practiceController.setupProgressivePractice(
            startBPM: startBPM,
            targetBPM: targetBPM,
            stepBPM: stepBPM,
            countdownType: countdownType
        )
    }
}


// MARK: - 便捷计算属性
extension PracticeViewModel {
    // 格式化时间 - 将秒数转换为分:秒格式
    func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600  // 计算小时数
        let minutes = (seconds % 3600) / 60  // 计算分钟数
        let remainingSeconds = seconds % 60  // 计算剩余秒数
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }

     // 获取倒计时显示文本 - 用于UI显示
    func getCountdownDisplayText() -> String {
        if countdownType == .time {
            return formatTime(remainingTime)
        } else {
            return "\(remainingBars) bars"
        }
    }
    
    // 获取BPM阶段文本 - 仅用于渐进模式
    func getBPMStageText() -> String {
        if practiceMode == .progressive {
            return "当前: \(currentBPM) BPM → 下一: \(nextStageBPM) BPM"
        }
        return ""
    }
    
    // 获取循环信息文本 - 用于UI显示
    func getCycleInfoText() -> String {
        if totalCycles > 1 {
            return "第 \(currentCycle) / \(totalCycles) 个循环"
        }
        return ""
    }
    
    // 检查是否为渐进式模式
    var isProgressiveMode: Bool {
        return practiceMode == .progressive
    }
    
    // 检查是否为倒计时模式
    var isCountdownMode: Bool {
        return practiceMode == .countdown
    }
}   
