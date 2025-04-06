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
        countdownType = newType
        delegate?.didCountdownTypeChange(countdownType)
    }   

    func updatePracticeStatus(_ newStatus: PracticeStatus) {
        practiceStatus = newStatus
        delegate?.didPracticeStatusChange(practiceStatus)
    }

    func updateTargetTime(_ newTime: Int) {
        targetTime = newTime
        delegate?.didTargetTimeChange(targetTime)
    }

    func updateTargetBars(_ newBars: Int) {
        targetBars = newBars
        delegate?.didTargetBarsChange(targetBars)
    }
    
    func updateIsLoopEnabled(_ newIsLoopEnabled: Bool) {
        isLoopEnabled = newIsLoopEnabled
        delegate?.didIsLoopEnabledChange(isLoopEnabled)
    }
    

    
    
    
    
    // MARK: - Action
    
    func startPractice() {
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
        myController.stop()
        updatePracticeStatus(status)
        elapsedTime = 0
        elapsedBars = 0
        timer?.invalidate()
        timer = nil
    }

    private func beginToTick(){
        if countdownType == .time {
            setupTimer()
        }
        else {
            setupControllerCallbacks()
        }
    }

    private func setupControllerCallbacks() {
        if countdownType != .bar { return }
        myController.onBarCompleted = { [weak self] in
            guard let self = self else { return }
            self.elapsedBars += 1
            self.delegate?.didRemainingBarsChange(self.targetBars - self.elapsedBars)
            if self.elapsedBars >= self.targetBars {
                if self.isLoopEnabled {
                    self.resetStatusAndContinuePractice()
                }
                else {
                    self.stopPractice(.completed)
                }
            }
        }
    }

    private func setupTimer() {
        if countdownType != .time { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.elapsedTime += 1
            self.delegate?.didRemainingTimeChange(self.targetTime - self.elapsedTime)

            if self.elapsedTime >= self.targetTime {
                if self.isLoopEnabled {
                    self.resetStatusAndContinuePractice()
                }
                else {
                    self.stopPractice(.completed)
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

  
    
}
