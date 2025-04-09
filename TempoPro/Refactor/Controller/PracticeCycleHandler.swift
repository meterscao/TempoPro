//
//  PracticeCycleHandler.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/5.
//

import Foundation

/// 练习循环处理器协议 - 定义不同练习模式下循环处理的行为
protocol PracticeCycleHandler {
    /// 循环开始时调用
    func onCycleStart()
    
    /// 循环进行中调用，用于更新进度
    /// - Parameters:
    ///   - elapsedTime: 已用时间(秒)
    ///   - elapsedBars: 已完成小节数
    func onCycleProgress(elapsedTime: Int, elapsedBars: Int)
    
    /// 循环完成时调用
    /// - Returns: 是否应继续下一个循环
    func onCycleComplete() -> Bool
    
    /// 练习完成时调用
    func onPracticeComplete()
    
    /// 获取当前循环信息
    /// - Returns: (当前循环索引, 总循环数)
    func getCurrentCycleInfo() -> (currentCycle: Int, totalCycles: Int)
    
    /// 计算总循环数
    /// - Returns: 总循环数
    func calculateTotalCycles() -> Int
    
    /// 获取当前阶段信息(主要用于渐进模式)
    /// - Returns: 当前阶段信息，如果不适用则返回nil
    func getCurrentStageInfo() -> (currentBPM: Int, nextBPM: Int)?
} 