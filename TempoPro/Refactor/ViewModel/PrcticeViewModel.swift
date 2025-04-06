//
//  PrcticeViewModel.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/3.
//

import SwiftUI

class PracticeViewModel: ObservableObject, PracticeControllerDelegate {
    @Published var countdownType: CountdownType
    @Published var practiceStatus: PracticeStatus
    @Published var targetTime: Int
    @Published var targetBars: Int
    @Published var remainingTime: Int
    @Published var remainingBars: Int
    @Published var isLoopEnabled: Bool

    @Published var timeProgress: Double = 0.0
    @Published var barProgress: Double = 0.0

    private let practiceController: PracticeController

    init(practiceController: PracticeController) {
        self.practiceController = practiceController

        self.countdownType = practiceController.getCountdownType()
        self.practiceStatus = practiceController.getPracticeStatus()
        self.targetTime = practiceController.getTargetTime()
        self.targetBars = practiceController.getTargetBars()
        self.remainingTime = practiceController.getRemainingTime()
        self.remainingBars = practiceController.getRemainingBars()
        self.isLoopEnabled = practiceController.getIsLoopEnabled()

        practiceController.delegate = self

    }
    

    // MARK: - 委托方法

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
}   
