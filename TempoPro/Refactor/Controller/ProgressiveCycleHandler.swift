//
//  ProgressiveCycleHandler.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/5.
//

import Foundation

/// 渐进式模式循环处理器 - 处理BPM逐步变化的练习模式
class ProgressiveCycleHandler: PracticeCycleHandler {
    // MARK: - 属性
    
    /// 起始BPM
    private let startBPM: Int
    
    /// 当前BPM
    private var currentBPM: Int
    
    /// 目标BPM
    private let targetBPM: Int
    
    /// 每次调整的BPM步长
    private let stepBPM: Int
    
    /// 已完成的循环数
    private var cyclesCompleted: Int = 0
    
    /// BPM更新回调函数
    private let metronomeBPMUpdater: (Int) -> Void
    
    // MARK: - 初始化方法
    
    /// 创建渐进式循环处理器
    /// - Parameters:
    ///   - startBPM: 起始BPM
    ///   - targetBPM: 目标BPM
    ///   - stepBPM: 每次调整的BPM步长
    ///   - metronomeBPMUpdater: BPM更新回调
    init(startBPM: Int, targetBPM: Int, stepBPM: Int, metronomeBPMUpdater: @escaping (Int) -> Void) {
        self.startBPM = startBPM
        self.currentBPM = startBPM
        self.targetBPM = targetBPM
        self.stepBPM = stepBPM
        self.metronomeBPMUpdater = metronomeBPMUpdater
        
        // 初始化时设置起始BPM
        metronomeBPMUpdater(startBPM)
    }
    
    // MARK: - PracticeCycleHandler 协议实现
    
    func onCycleStart() {
        print("🔄 渐进循环开始: 当前BPM = \(currentBPM)")
    }
    
    func onCycleProgress(elapsedTime: Int, elapsedBars: Int) {
        // 渐进模式进度更新不需要特殊处理
    }
    
    func onCycleComplete() -> Bool {
        cyclesCompleted += 1
        
        // 计算下一个BPM
        let nextBPM = calculateNextBPM()
        let isComplete = isTargetReached(nextBPM)
        
        print("🔄 渐进循环完成: \(cyclesCompleted)/\(calculateTotalCycles()), 当前BPM = \(currentBPM), 下一个BPM = \(nextBPM), 完成 = \(isComplete)")
        
        // 如果未达到目标BPM，则更新BPM并继续
        if !isComplete {
            currentBPM = nextBPM
            metronomeBPMUpdater(currentBPM)
            return true
        }
        
        return false
    }
    
    func onPracticeComplete() {
        print("✅ 渐进练习完成：从 \(startBPM) 到 \(currentBPM)")
    }
    
    func getCurrentCycleInfo() -> (currentCycle: Int, totalCycles: Int) {
        return (cyclesCompleted + 1, calculateTotalCycles())
    }
    
    func calculateTotalCycles() -> Int {
        // 计算从起始到目标所需的循环数
        // 如果BPM是减少的情况，使用负步长
        let effectiveStep = targetBPM > startBPM ? stepBPM : -stepBPM
        let difference = abs(targetBPM - startBPM)
        let cycles = Int(ceil(Double(difference) / Double(abs(effectiveStep))))
        return max(1, cycles)
    }
    
    func getCurrentStageInfo() -> (currentBPM: Int, nextBPM: Int)? {
        if isTargetReached(calculateNextBPM()) {
            return (currentBPM, targetBPM)
        }
        return (currentBPM, calculateNextBPM())
    }
    
    // MARK: - 辅助方法
    
    /// 计算下一个BPM值
    /// - Returns: 下一个BPM值
    private func calculateNextBPM() -> Int {
        // 根据目标方向计算下一个BPM
        if targetBPM > startBPM {
            // 渐进增加
            return min(currentBPM + stepBPM, targetBPM)
        } else {
            // 渐进减少
            return max(currentBPM - stepBPM, targetBPM)
        }
    }
    
    /// 检查是否已达到目标BPM
    /// - Parameter nextBPM: 下一个BPM值
    /// - Returns: 是否已达到目标
    private func isTargetReached(_ nextBPM: Int) -> Bool {
        if targetBPM > startBPM {
            // 增加模式，检查是否已达到或超过目标
            return nextBPM >= targetBPM
        } else {
            // 减少模式，检查是否已达到或低于目标
            return nextBPM <= targetBPM
        }
    }
} 