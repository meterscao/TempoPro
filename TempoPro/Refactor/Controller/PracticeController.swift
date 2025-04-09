//
//  PracticeController.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/3.
//

import Foundation

// 倒计时模式类型 - 定义倒计时的计量方式
enum CountdownType {
    case time  // 按时间倒计时 - 以秒为单位
    case bar   // 按小节倒计时 - 以完成的小节数为单位
}

// 练习状态枚举 - 定义练习的运行状态
enum PracticeStatus {
    case standby   // 准备状态 - 未开始
    case running   // 正在运行 - 练习中
    case paused    // 暂停状态 - 暂时中断
    case completed // 完成状态 - 已达成目标
}

protocol PracticeControllerDelegate: AnyObject {
    func didPracticeStatusChange(_ newStatus: PracticeStatus)
    func didCountdownTypeChange(_ newCountdownType: CountdownType)
    func didTargetTimeChange(_ newTargetTime: Int)
    func didTargetBarsChange(_ newTargetBars: Int)
    func didRemainingTimeChange(_ newRemainingTime: Int)
    func didRemainingBarsChange(_ newRemainingBars: Int)
    func didIsLoopEnabledChange(_ newIsLoopEnabled: Bool)
}

class PracticeController {

    // MARK: - Property
    weak var delegate: PracticeControllerDelegate?
    private var myController: MyController
    

    // MARK: - Property
    // 倒计时类型
    private var countdownType: CountdownType = .time
    // 练习状态
    private var practiceStatus: PracticeStatus = .standby
    // 目标时间
    private var targetTime: Int = 300
    // 已用时间
    private var elapsedTime: Int = 0
    

    // 目标小节数
    private var targetBars: Int = 20
    // 已用小节数
    private var elapsedBars: Int = 0
    

    // 是否启用循环
    private var isLoopEnabled: Bool = false
    // 计时器
    private var timer: Timer?

    init(myController: MyController) {
        self.myController = myController
    }

    // MARK: - Getter
    func getCountdownType() -> CountdownType {
        return countdownType
    }

    func getPracticeStatus() -> PracticeStatus {
        return practiceStatus
    }

    func getTargetTime() -> Int {
        return targetTime
    }

    func getTargetBars() -> Int {
        return targetBars
    }

    func getRemainingTime() -> Int {
        return targetTime - elapsedTime
    }

    func getRemainingBars() -> Int {
        return targetBars - elapsedBars
    }   

    func getIsLoopEnabled() -> Bool {
        return isLoopEnabled
    }


    // MARK: - Setter
    func updateCountdownType(_ newType: CountdownType) {
        print("🔧 控制器 - 更新倒计时类型: \(countdownType) -> \(newType)")
        countdownType = newType
        delegate?.didCountdownTypeChange(countdownType)
    }   

    func updatePracticeStatus(_ newStatus: PracticeStatus) {
        print("🔧 控制器 - 更新练习状态: \(practiceStatus) -> \(newStatus)")
        practiceStatus = newStatus
        delegate?.didPracticeStatusChange(practiceStatus)
    }

    func updateTargetTime(_ newTime: Int) {
        print("🔧 控制器 - 更新目标时间: \(targetTime) -> \(newTime)")
        targetTime = newTime
        delegate?.didTargetTimeChange(targetTime)
    }

    func updateTargetBars(_ newBars: Int) {
        print("🔧 控制器 - 更新目标小节: \(targetBars) -> \(newBars)")
        targetBars = newBars
        delegate?.didTargetBarsChange(targetBars)
    }
    
    func updateIsLoopEnabled(_ newIsLoopEnabled: Bool) {
        print("🔧 控制器 - 更新循环模式: \(isLoopEnabled) -> \(newIsLoopEnabled)")
        isLoopEnabled = newIsLoopEnabled
        delegate?.didIsLoopEnabledChange(isLoopEnabled)
    }

}



extension PracticeController {
    // MARK: - Action
    
    func startPractice() {
        print("🔧 控制器 - 开始练习, 当前类型: \(countdownType), 目标时间: \(targetTime), 目标小节: \(targetBars)")
        // 重置计时状态
        elapsedTime = 0
        elapsedBars = 0

        updatePracticeStatus(.running)
        
        delegate?.didRemainingBarsChange(targetBars - elapsedBars)
        delegate?.didRemainingTimeChange(targetTime - elapsedTime)

        myController.play()
        // 根据倒计时类型设置目标
        beginToTick()
    }

    func pausePractice() {
        if practiceStatus != .running { return }
        myController.pause()
        updatePracticeStatus(.paused)
        timer?.invalidate()
        timer = nil
        
    }

    func resumePractice() {
        if practiceStatus != .paused { return }
        myController.resume()
        updatePracticeStatus(.running)
        beginToTick()
    }

    func stopPractice(_ status: PracticeStatus = .standby) {
        print("🔧 控制器 - 停止练习, 设置状态: \(status)")
        myController.stop()
        updatePracticeStatus(status)

        if countdownType == .time {
            if status == .completed {
                elapsedTime = targetTime
            }
            else {
                elapsedTime = 0
            }
            timer?.invalidate()
            timer = nil
        }
        else {
            if status == .completed {
                elapsedBars = targetBars
            }
            else {
                elapsedBars = 0
            }
        }
        print("🔧 控制器 - 停止后状态: 剩余时间应为\(targetTime), 剩余小节应为\(targetBars)")
    }

    // 开始倒计时
    private func beginToTick(){
        if countdownType == .time {
            setupTimer()
        }
        else {
            setupControllerCallbacks()
        }
    }
}


extension PracticeController {
    


    // 设置控制器回调
    private func setupControllerCallbacks() {
        if countdownType != .bar { return }
        myController.onBarCompleted = { [weak self] in
            guard let self = self else { return }
            if self.practiceStatus == .running {        
                self.elapsedBars += 1
                self.delegate?.didRemainingBarsChange(self.targetBars - self.elapsedBars)
                if self.elapsedBars >= self.targetBars {
                    self.onLoopEnd()
                }
            }
        }
    }

    // 设置时间倒计时
    private func setupTimer() {
        if countdownType != .time { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.practiceStatus == .running {
                self.elapsedTime += 1
                self.delegate?.didRemainingTimeChange(self.targetTime - self.elapsedTime)

                if self.elapsedTime >= self.targetTime {
                    self.onLoopEnd()
                }
            }
        }
    }

    private func resetStatusAndContinuePractice(){
        updatePracticeStatus(.running)
        elapsedTime = 0
        elapsedBars = 0
        delegate?.didRemainingTimeChange(targetTime - elapsedTime)
        delegate?.didRemainingBarsChange(targetBars - elapsedBars)
    }


    // 每个周期结束时触发的回调
    private func onLoopEnd(){
        if isLoopEnabled {
            resetStatusAndContinuePractice()
        }
        else {
            stopPractice(.completed)
        }
    }   
}