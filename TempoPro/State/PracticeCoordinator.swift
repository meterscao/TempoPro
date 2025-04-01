//
//  PracticeMode.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/24.
//

// MARK: - 架构说明
// 该文件实现了节拍器的练习模式功能，采用委托模式与节拍器核心交互
// 架构改进 (2025/04):
// 1. 引入了高级委托协议(AdvancedMetronomePlaybackDelegate)，提供更精确的小节计时控制
// 2. 通过"即将完成小节"事件(metronomeWillCompleteBar)解决了倒计时不准确的问题
// 3. 将完成判断逻辑从小节完成后(didComplete)移动到小节完成前(willComplete)
// 4. 保留了向后兼容性，确保系统平滑过渡到新架构

import Foundation
import Combine
import SwiftUI

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

// 练习模式协调器 - 负责协调节拍器与练习模式之间的交互
class PracticeCoordinator: ObservableObject, AdvancedMetronomePlaybackDelegate {
    // MARK: - 公开状态属性
    @Published private(set) var activeMode: PracticeMode = .none      // 当前激活的练习模式
    @Published private(set) var practiceStatus: PracticeStatus = .standby  // 当前练习状态
    
    // MARK: - 倒计时模式设置
    @Published var countdownType: CountdownType = .time  // 倒计时类型（时间/小节）
    @Published var targetTime: Int = 300 // 目标时间 - 默认5分钟 (秒)
    @Published var targetBars: Int = 4   // 目标小节数 - 默认4小节
    @Published var isLoopEnabled: Bool = false       // 是否启用循环模式
    @Published var isSyncStartEnabled: Bool = true   // 是否同步启动节拍器
    @Published var isSyncStopEnabled: Bool = true    // 是否同步停止节拍器
    
    // MARK: - 渐进模式设置
    @Published var progressiveFromBPM: Int = 60      // 起始BPM
    @Published var progressiveToBPM: Int = 120       // 目标BPM
    @Published var progressiveIncrement: Int = 5     // 每次BPM增量
    @Published var progressiveInterval: Int = 10     // 更新间隔(秒或小节)
    @Published var progressiveType: CountdownType = .time  // 更新类型（按时间/按小节）
    
    // MARK: - 进度状态
    @Published private(set) var elapsedSeconds: Int = 0       // 已经过的秒数
    @Published private(set) var currentBPM: Int = 60          // 当前实际BPM值
    @Published private(set) var isCompletingCycle: Bool = false  // 标记是否正在完成一个循环
    
    // MARK: - 私有属性
    private weak var metronomeState: MetronomeState?  // 对节拍器状态的弱引用
    private var timer: Timer?                         // 计时器
    private var lastUpdateTime: Int = 0               // 上次更新BPM的时间点
    private var lastUpdateBar: Int = 0                // 上次更新BPM的小节数
    private var cancellables = Set<AnyCancellable>()  // 取消令牌集合
    private var resetProgressTask: DispatchWorkItem?  // 用于控制重置进度的任务
    private var stepUpdateTask: DispatchWorkItem?     // 用于 Step 模式 BPM 更新的任务
    private var cycleStartBarCount: Int = 0           // 当前循环开始时的小节计数
    
    // MARK: - 初始化
    init(metronomeState: MetronomeState) {
        self.metronomeState = metronomeState
        metronomeState.addDelegate(self)  // 注册为节拍器的委托
    }
    
    // MARK: - 公开方法
    
    // 设置练习模式 - 切换到指定的练习模式
    func setPracticeMode(_ mode: PracticeMode) {
        // 如果有正在运行的练习，先停止
        if practiceStatus == .running || practiceStatus == .paused {
            stopPractice()
        }
        
        activeMode = mode
        
        // 重置状态
        elapsedSeconds = 0
        practiceStatus = .standby
        cycleStartBarCount = 0
        
        if mode == .progressive {
            currentBPM = progressiveFromBPM
        }
        
        objectWillChange.send()
    }
    
    // 开始练习 - 根据当前模式启动练习
    func startPractice() {
        guard let metronomeState = metronomeState else { return }
        
        // 重置计时状态
        elapsedSeconds = 0
        practiceStatus = .running
        
        // 设置正确的循环起始小节数
        // 如果节拍器不在播放状态，设置为0，因为play()会重置completedBars
        // 否则使用当前值
        if !metronomeState.isPlaying {
            cycleStartBarCount = 0
            print("初始化cycleStartBarCount为0(未播放状态)")
        } else {
            cycleStartBarCount = metronomeState.completedBars
            print("初始化cycleStartBarCount为\(cycleStartBarCount)(已播放状态)")
        }
        
        // 根据练习模式设置初始状态
        if activeMode == .countdown {
            // 倒计时模式 - 根据同步设置启动节拍器
            if isSyncStartEnabled && !metronomeState.isPlaying {
                metronomeState.play()
                // play()会重置completedBars为0，需要确保循环起始值一致
                cycleStartBarCount = 0
            }
        } else if activeMode == .progressive {
            // 渐进模式 - 设置初始BPM并启动节拍器
            currentBPM = progressiveFromBPM
            metronomeState.updateTempo(progressiveFromBPM)
            
            if !metronomeState.isPlaying {
                metronomeState.play()
                // play()会重置completedBars为0，需要确保循环起始值一致
                cycleStartBarCount = 0
            }
            
            // 重置更新计数
            lastUpdateTime = 0
            lastUpdateBar = 0
        }
        
        // 启动定时器
        startTimer()
    }
    
    // 暂停练习 - 暂停进行中的练习
    func pausePractice() {
        if practiceStatus != .running { return }
        
        practiceStatus = .paused
        timer?.invalidate()
        timer = nil
        
        // 暂停节拍器
        metronomeState?.pause()
        
        objectWillChange.send()
    }
    
    // 恢复练习 - 从暂停状态恢复练习
    func resumePractice() {
        if practiceStatus != .paused { return }
        
        practiceStatus = .running
        
        // 恢复节拍器
        metronomeState?.resume()
        
        // 重启定时器
        startTimer()
    }
    
    // 停止练习 - 完全停止当前练习
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
        cycleStartBarCount = 0
        
        // 停止节拍器
        metronomeState?.stop()
        
        objectWillChange.send()
    }
    
    // 获取倒计时显示文本 - 用于UI显示
    func getCountdownDisplayText() -> String {
        if countdownType == .time {
            return formatTime(remainingSeconds)
        } else {
            return "\(remainingBars) bars"
        }
    }
    
    // 获取渐进式显示文本 - 用于UI显示
    func getProgressiveDisplayText() -> String {
        return "\(currentBPM) BPM"
    }
    
    // MARK: - MetronomePlaybackDelegate 实现
    
    // 节拍器播放状态变化回调
    func metronomeDidChangePlaybackState(_ state: PlaybackState) {
        print("metronomeDidChangePlaybackState: \(state), 练习状态: \(practiceStatus)")
        // 如果节拍器停止，且处于练习模式，也停止练习
        if state == .standby && (practiceStatus == .running || practiceStatus == .paused) {
            stopPractice()
        }
        
        // 监听播放状态变化，同步cycleStartBarCount
        if state == .playing && (practiceStatus == .running || practiceStatus == .paused) {
            // 节拍器刚开始播放时，completedBars会被重置为0
            // 我们需要确保cycleStartBarCount也同步重置
            if let metronomeState = metronomeState, metronomeState.completedBars == 0 {
                print("检测到节拍器重置，同步cycleStartBarCount为0")
                cycleStartBarCount = 0
            }
        }
    }
    
    // 简化版播放状态变化回调（兼容重构后的接口）
    func metronomePlaybackDidChangeState(isPlaying: Bool) {
        // 此方法实现是为了兼容性，实际逻辑已在 metronomeDidChangePlaybackState 中处理
        print("metronomePlaybackDidChangeState: isPlaying=\(isPlaying), 练习状态: \(practiceStatus)")
    }
    
    // 节拍完成回调
    func metronomeDidCompleteBeat(beatIndex: Int, isLastBeat: Bool) {
        // 在最后一拍也可以处理拍子完成事件，但现在我们改用高级委托方法
    }
    
    // 小节即将完成回调（AdvancedMetronomePlaybackDelegate）
    func metronomeWillCompleteBar(barCount: Int) {
        // 添加日志
        print("【高级委托】小节即将完成: \(barCount), 目标小节: \(targetBars), 练习状态: \(practiceStatus), 练习模式: \(activeMode), 倒计时类型: \(countdownType)")
        
        // 检查倒计时模式是否需要提前结束
        if activeMode == .countdown && practiceStatus == .running && countdownType == .bar {
            // 计算当前循环中即将完成的小节数（包括当前即将完成的小节）
            let willCompleteBarCount = barCount - cycleStartBarCount
            
            print("【高级委托】检查小节完成条件: 循环起始(\(cycleStartBarCount)), 即将完成总计(\(barCount)), 本循环即将完成(\(willCompleteBarCount)), 目标(\(targetBars)): \(willCompleteBarCount == targetBars)")
            
            // 检查即将完成的小节是否正好达到目标数量
            if willCompleteBarCount == targetBars {
                // 在小节的最后一拍完成时就停止，而不是等到下一小节开始
                print("【高级委托】小节即将达到目标，提前调用完成练习")
                
                // 注意：已不再需要异步调用completePractice
                // 因为在MetronomeTimer中会直接调用
                // 这里保留代码是为了在其他情况下仍能正常工作
                // DispatchQueue.main.async { [weak self] in
                //     guard let self = self else { return }
                //     self.completePractice()
                // }
            }
        }
    }
    
    // 小节完成回调
    func metronomeDidCompleteBar(barCount: Int) {
        // 添加日志
        print("【委托】完成小节: \(barCount), 目标小节: \(targetBars), 练习状态: \(practiceStatus), 练习模式: \(activeMode), 倒计时类型: \(countdownType)")
        
        // 检查是否需要更新渐进式BPM
        if activeMode == .progressive && practiceStatus == .running && progressiveType == .bar {
            let barsSinceLastUpdate = barCount - lastUpdateBar
            
            if barsSinceLastUpdate >= progressiveInterval {
                lastUpdateBar = barCount
                updateProgressiveBPM()
            }
        }
        
        // 注意：倒计时模式下的小节检查已移至 metronomeWillCompleteBar 方法
        // 这里保留代码是为了向后兼容，但不应再触发完成事件
        if activeMode == .countdown && practiceStatus == .running && countdownType == .bar {
            // 计算当前循环中已完成的小节数
            let completedBarsInCurrentCycle = barCount - cycleStartBarCount
            print("【委托】检查小节完成条件（已由高级委托预先处理）: 循环起始(\(cycleStartBarCount)), 当前总计(\(barCount)), 本循环已完成(\(completedBarsInCurrentCycle)), 目标(\(targetBars))")
        }
    }
    
    // MARK: - 私有方法
    
    // 启动计时器 - 每秒触发一次
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
    
    // 更新渐进式BPM - 根据设置增加或减少BPM
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
            // 使用动画更新进度和BPM
            animateProgressUpdate(newBPM: nextBPM)
        }
    }
    
    // 带动画更新进度和BPM
    private func animateProgressUpdate(newBPM: Int) {
        // 进度条动画到100%
        withAnimation(.linear(duration: 0.5)) {
            isCompletingCycle = true
        }
        
        // 创建延迟任务
        let task = DispatchWorkItem { [weak self] in
            guard let self = self, let metronomeState = self.metronomeState else { return }
            
            // 无动画地重置进度并更新BPM
            DispatchQueue.main.async {
                withAnimation(nil) {
                    self.isCompletingCycle = false
                }
                
                // 更新BPM
                self.currentBPM = newBPM
                metronomeState.updateTempo(newBPM)
                
                // 更新时间点
                if self.progressiveType == .time {
                    self.lastUpdateTime = self.elapsedSeconds
                } else {
                    self.lastUpdateBar = metronomeState.completedBars
                }
            }
        }
        
        stepUpdateTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }
    
    // 完成练习 - 处理练习达到目标的情况
    func completePractice() {
        print("进入completePractice，循环模式: \(isLoopEnabled), 同步停止: \(isSyncStopEnabled), 当前状态: \(practiceStatus)")
        
        // 检查状态，避免重复调用
        if practiceStatus == .completed {
            print("练习已经处于完成状态，忽略此次调用")
            return
        }
        
        timer?.invalidate()
        timer = nil
        
        if activeMode == .countdown && isLoopEnabled {
            // 循环模式处理
            print("触发循环模式处理")
            handleLoopCompletion()
        } else {
            // 非循环模式，直接完成
            practiceStatus = .completed
            
            if isSyncStopEnabled {
                print("准备停止节拍器")
                metronomeState?.stop()  // 直接调用停止方法
                print("节拍器已停止")
            }
        }
        
        objectWillChange.send()
    }
    
    // 处理循环完成 - 循环模式下的重新开始逻辑
    private func handleLoopCompletion() {
        // 循环模式 - 显示完成状态，再重置
        practiceStatus = .completed
        resetProgressTask?.cancel()
        
        print("循环模式：准备重置计时")
        
        // 设置完成循环标志
        withAnimation(.linear(duration: 0.5)) {
            isCompletingCycle = true
        }
        
        // 创建延迟任务
        let task = DispatchWorkItem { [weak self] in
            guard let self = self, let metronomeState = self.metronomeState else { return }
            
            DispatchQueue.main.async {
                print("循环模式：重置计时器")
                withAnimation(nil) {
                    self.isCompletingCycle = false
                    self.elapsedSeconds = 0
                }
                
                // 更新循环起始小节数为当前小节数
                self.cycleStartBarCount = metronomeState.completedBars
                print("循环模式：更新循环起始小节数为 \(self.cycleStartBarCount)")
                
                // 验证计算是否正确
                let completedBarsInCurrentCycle = metronomeState.completedBars - self.cycleStartBarCount
                print("循环模式：验证 - 当前总计(\(metronomeState.completedBars)), 循环起始(\(self.cycleStartBarCount)), 本循环已完成(\(completedBarsInCurrentCycle)), 目标(\(self.targetBars))")
                
                self.practiceStatus = .running
                self.startTimer()
            }
        }
        
        resetProgressTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: task)
    }
    
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
    
    // MARK: - 便捷计算属性
    
    // 剩余秒数 - 倒计时模式下的剩余时间
    var remainingSeconds: Int {
        return max(0, targetTime - elapsedSeconds)
    }
    
    // 剩余小节数 - 倒计时模式下的剩余小节
    var remainingBars: Int {
        guard let metronomeState = metronomeState else { return targetBars }
        
        if practiceStatus == .completed {
            return 0
        }
        
        // 计算相对于当前循环的已完成小节数
        let completedBarsInCurrentCycle = metronomeState.completedBars - cycleStartBarCount
        print("计算剩余小节: 循环起始(\(cycleStartBarCount)), 当前总计(\(metronomeState.completedBars)), 本循环已完成(\(completedBarsInCurrentCycle)), 目标(\(targetBars)), 剩余(\(max(targetBars - completedBarsInCurrentCycle, 0)))")
        return max(targetBars - completedBarsInCurrentCycle, 0)
    }
    
    // 进度 - 当前练习的完成进度（0.0-1.0）
    var progress: CGFloat {
        // 特殊情况处理
        if isCompletingCycle || practiceStatus == .completed {
            return 1.0
        }
        
        // 根据模式计算进度
        if activeMode == .countdown {
            if countdownType == .time {
                return targetTime > 0 ? CGFloat(elapsedSeconds) / CGFloat(targetTime) : 0.01
            } else {
                guard let metronomeState = metronomeState else { return 0.01 }
                // 使用相对于当前循环开始的小节数计算进度
                let completedBarsInCurrentCycle = metronomeState.completedBars - cycleStartBarCount
                return min(CGFloat(completedBarsInCurrentCycle) / CGFloat(targetBars), 1.0)
            }
        } else if activeMode == .progressive {
            // 渐进模式 - 计算BPM变化进度
            if progressiveFromBPM == progressiveToBPM { return 1.0 }
            
            let totalChange = abs(progressiveToBPM - progressiveFromBPM)
            let currentChange = abs(currentBPM - progressiveFromBPM)
            return min(CGFloat(currentChange) / CGFloat(totalChange), 1.0)
        }
        
        return 0.0
    }
    
    // MARK: - 清理资源
    
    // 清理资源 - 取消所有计时器和任务
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
    
    /// 检查给定的小节计数是否达到了目标小节数
    /// - Parameter barCount: 当前完成的小节数
    /// - Returns: 如果达到目标小节数则返回true，否则返回false
    public func isTargetBarReached(barCount: Int) -> Bool {
        print("PracticeCoordinator - 检查是否达到目标小节: barCount=\(barCount), activeMode=\(activeMode), countdownType=\(countdownType), practiceStatus=\(practiceStatus)")
        
        // 只有在倒计时模式、小节计数类型和正在运行状态下才进行检查
        guard activeMode == .countdown && 
              countdownType == .bar && 
              practiceStatus == .running else {
            return false
        }
        
        // 计算相对于循环开始的小节数
        let completedBarCount = barCount - cycleStartBarCount
        print("PracticeCoordinator - 计算完成小节: completedBarCount=\(completedBarCount), targetBars=\(targetBars)")
        
        // 检查是否达到目标小节数
        return completedBarCount == targetBars
    }
}
