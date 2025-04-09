//
//  CountdownCycleHandler.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/5.
//

import Foundation

/// 倒计时模式循环处理器 - 处理按时间或小节倒计时的循环
class CountdownCycleHandler: PracticeCycleHandler {
    // MARK: - 属性
    
    /// 是否启用循环模式
    private let isLoopEnabled: Bool
    
    /// 计算的总循环数 (循环模式下为无限)
    private let totalCycles: Int
    
    /// 已完成的循环数
    private var cyclesCompleted: Int = 0
    
    // MARK: - 初始化方法
    
    /// 创建倒计时循环处理器
    /// - Parameter isLoopEnabled: 是否启用循环模式
    init(isLoopEnabled: Bool) {
        self.isLoopEnabled = isLoopEnabled
        self.totalCycles = isLoopEnabled ? Int.max : 1
    }
    
    // MARK: - PracticeCycleHandler 协议实现
    
    func onCycleStart() {
        // 倒计时模式不需要特殊处理
        print("🔄 倒计时循环开始")
    }
    
    func onCycleProgress(elapsedTime: Int, elapsedBars: Int) {
        // 倒计时模式进度更新不需要特殊处理
    }
    
    func onCycleComplete() -> Bool {
        cyclesCompleted += 1
        print("🔄 倒计时循环完成: \(cyclesCompleted)/\(totalCycles)")
        
        // 如果启用了循环模式，则继续下一个循环
        return isLoopEnabled
    }
    
    func onPracticeComplete() {
        print("✅ 倒计时练习完成")
    }
    
    func getCurrentCycleInfo() -> (currentCycle: Int, totalCycles: Int) {
        return (cyclesCompleted + 1, totalCycles)
    }
    
    func calculateTotalCycles() -> Int {
        return totalCycles
    }
    
    func getCurrentStageInfo() -> (currentBPM: Int, nextBPM: Int)? {
        // 倒计时模式不支持阶段信息
        return nil
    }
} 