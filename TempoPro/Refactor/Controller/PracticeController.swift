//
//  PracticeController.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/3.
//

import Foundation

// 练习模式枚举 - 定义不同的练习类型
enum PracticeMode {
    case none        // 无练习模式 - 普通节拍器模式
    case countdown   // 倒计时模式 - 按时间或小节进行倒计时
    case progressive // 渐进式模式 - 逐步增加/减少BPM
}

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
    func didPracticeModeChange(_ newPracticeMode: PracticeMode)
    func didCurrentCycleInfoChange(_ currentCycle: Int, _ totalCycles: Int)
    func didStageInfoChange(_ currentBPM: Int, _ nextBPM: Int)
    func didBPMChange(_ newBPM: Int)
}

class PracticeController {

    // MARK: - Property
    weak var delegate: PracticeControllerDelegate?
    private var myController: MyController
    

    // MARK: - Property
    // 练习模式
    private var practiceMode: PracticeMode = .none
    // 循环处理器
    private var cycleHandler: PracticeCycleHandler?
    
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
    
    // 渐进模式专用属性
    private var startBPM: Int = 60
    private var targetBPM: Int = 120
    private var stepBPM: Int = 5

    init(myController: MyController) {
        self.myController = myController
    }

    // MARK: - Getter
    func getPracticeMode() -> PracticeMode {
        return practiceMode
    }
    
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
    
    func getStartBPM() -> Int {
        return startBPM
    }
    
    func getTargetBPM() -> Int {
        return targetBPM
    }
    
    func getStepBPM() -> Int {
        return stepBPM
    }
    
    func getCurrentCycleInfo() -> (currentCycle: Int, totalCycles: Int)? {
        return cycleHandler?.getCurrentCycleInfo()
    }
    
    func getStageInfo() -> (currentBPM: Int, nextBPM: Int)? {
        return cycleHandler?.getCurrentStageInfo()
    }


    // MARK: - Setter
    func updatePracticeMode(_ newMode: PracticeMode) {
        print("🔧 控制器 - 更新练习模式: \(practiceMode) -> \(newMode)")
        
        // 如果正在练习中，先停止
        if practiceStatus == .running || practiceStatus == .paused {
            stopPractice()
        }
        
        practiceMode = newMode
        
        // 根据模式创建对应处理器
        switch newMode {
        case .none:
            cycleHandler = nil
            
        case .countdown:
            cycleHandler = CountdownCycleHandler(isLoopEnabled: isLoopEnabled)
            
        case .progressive:
            cycleHandler = ProgressiveCycleHandler(
                startBPM: startBPM,
                targetBPM: targetBPM,
                stepBPM: stepBPM,
                metronomeBPMUpdater: { [weak self] newBPM in
                    self?.updateBPM(newBPM)
                }
            )
        }
        
        delegate?.didPracticeModeChange(practiceMode)
        updateCycleInfo()
        updateStageInfo()
    }
    
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
        
        // 如果当前是倒计时模式，更新对应的处理器
        if practiceMode == .countdown {
            cycleHandler = CountdownCycleHandler(isLoopEnabled: isLoopEnabled)
        }
        
        delegate?.didIsLoopEnabledChange(isLoopEnabled)
    }
    
    func updateStartBPM(_ newBPM: Int) {
        print("🔧 控制器 - 更新起始BPM: \(startBPM) -> \(newBPM)")
        startBPM = newBPM
    }
    
    func updateTargetBPM(_ newBPM: Int) {
        print("🔧 控制器 - 更新目标BPM: \(targetBPM) -> \(newBPM)")
        targetBPM = newBPM
    }
    
    func updateStepBPM(_ newStep: Int) {
        print("🔧 控制器 - 更新BPM步长: \(stepBPM) -> \(newStep)")
        stepBPM = newStep
    }
    
    func updateBPM(_ newBPM: Int) {
        print("🔧 控制器 - 更新当前BPM: \(newBPM)")
        myController.updateTempo(newBPM)
        delegate?.didBPMChange(newBPM)
    }
    
    // 更新循环信息
    private func updateCycleInfo() {
        if let info = cycleHandler?.getCurrentCycleInfo() {
            delegate?.didCurrentCycleInfoChange(info.currentCycle, info.totalCycles)
        }
    }
    
    // 更新阶段信息(针对渐进模式)
    private func updateStageInfo() {
        if let info = cycleHandler?.getCurrentStageInfo() {
            delegate?.didStageInfoChange(info.currentBPM, info.nextBPM)
        }
    }

}



extension PracticeController {
    // MARK: - Action
    
    func startPractice() {
        print("🔧 控制器 - 开始练习, 当前模式: \(practiceMode), 类型: \(countdownType), 目标时间: \(targetTime), 目标小节: \(targetBars)")
        // 重置计时状态
        elapsedTime = 0
        elapsedBars = 0

        updatePracticeStatus(.running)
        
        delegate?.didRemainingBarsChange(targetBars - elapsedBars)
        delegate?.didRemainingTimeChange(targetTime - elapsedTime)

        // 通知处理器循环开始
        cycleHandler?.onCycleStart()
        
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

        if status == .completed {
            cycleHandler?.onPracticeComplete()
        }
        
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
        
        // 更新剩余时间/小节
        delegate?.didRemainingTimeChange(targetTime - elapsedTime)
        delegate?.didRemainingBarsChange(targetBars - elapsedBars)
        
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
                
                // 通知处理器进度更新
                self.cycleHandler?.onCycleProgress(elapsedTime: self.elapsedTime, elapsedBars: self.elapsedBars)
                
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
                
                // 通知处理器进度更新
                self.cycleHandler?.onCycleProgress(elapsedTime: self.elapsedTime, elapsedBars: self.elapsedBars)

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
        
        // 更新循环信息
        updateCycleInfo()
        updateStageInfo()
    }

    // 每个周期结束时触发的回调
    private func onLoopEnd(){
        // 使用处理器处理循环完成逻辑
        if let handler = cycleHandler, handler.onCycleComplete() {
            // 处理器返回true表示继续下一个循环
            resetStatusAndContinuePractice()
        } else {
            // 处理器返回false或无处理器，表示完成练习
            stopPractice(.completed)
        }
    }   
}
// MARK: - 快捷设置方法

extension PracticeController {
    // 设置倒计时练习模式
    func setupCountdownPractice(countdownType: CountdownType, isLoopEnabled: Bool) {
        self.updateCountdownType(countdownType)
        self.updateIsLoopEnabled(isLoopEnabled)
        self.updatePracticeMode(.countdown)
    }
    
    // 设置渐进式练习模式
    func setupProgressivePractice(startBPM: Int, targetBPM: Int, stepBPM: Int, countdownType: CountdownType) {
        self.updateStartBPM(startBPM)
        self.updateTargetBPM(targetBPM)
        self.updateStepBPM(stepBPM)
        self.updateCountdownType(countdownType)
        self.updatePracticeMode(.progressive)
    }
}
