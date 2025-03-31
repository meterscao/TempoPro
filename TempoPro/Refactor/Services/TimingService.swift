//
//  TimingService.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/31.
//

import SwiftUI

// 计时服务
class TimingService {
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.metronome.timer", qos: .userInteractive)
    private var nextBeatTime: TimeInterval = 0
    
    // 回调
    var onBeatTriggered: ((Int) -> Void)?
    var onBarCompleted: (() -> Void)?
    
    // 计时参数
    private var tempo: Int = 120
    private var beatsPerBar: Int = 4
    private var currentBeat: Int = 0
    
    // 配置函数
    func configure(tempo: Int, beatsPerBar: Int, currentBeat: Int) {
        self.tempo = tempo
        self.beatsPerBar = beatsPerBar
        self.currentBeat = currentBeat
    }
    
    // 启动计时
    func start() {
        stop() // 确保先停止可能存在的计时器
        
        // 计算第一拍的时间
        let now = Date().timeIntervalSince1970
        nextBeatTime = now
        
        // 创建高精度计时器
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.schedule(deadline: .now(), repeating: 0.01) // 10ms检查一次
        
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            let now = Date().timeIntervalSince1970
            if now >= self.nextBeatTime {
                // 触发当前拍的回调
                self.onBeatTriggered?(self.currentBeat)
                
                // 计算下一拍
                self.currentBeat = (self.currentBeat + 1) % self.beatsPerBar
                
                // 检查是否完成一个小节
                if self.currentBeat == 0 {
                    self.onBarCompleted?()
                }
                
                // 计算下一拍时间
                self.nextBeatTime += 60.0 / Double(self.tempo)
            }
        }
        
        timer?.resume()
    }
    
    func stop() {
        if let timer = timer {
            timer.cancel()
            self.timer = nil
        }
    }
    
    // 暂停但保留状态
    func pause() {
        if let timer = timer {
            timer.cancel()
            self.timer = nil
        }
    }
    
    // 从当前状态恢复
    func resume() {
        start()
    }
}



