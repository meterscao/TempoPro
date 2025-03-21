//
//  TimerState.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/21.
//


import Foundation

class PracticeTimerState: ObservableObject {
    @Published var isTimerRunning = false
    @Published var selectedHours = 0
    @Published var selectedMinutes = 5
    @Published var selectedSeconds = 0
    @Published var isLoopEnabled = false
    @Published var elapsedSeconds = 0
    @Published var isTimerCompleted = false
    
    var timer: Timer? = nil
    
    var totalSeconds: Int {
        return (selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds
    }
    
    var remainingSeconds: Int {
        return max(0, totalSeconds - elapsedSeconds)
    }
    
    var progress: CGFloat {
        return totalSeconds > 0 ? CGFloat(elapsedSeconds) / CGFloat(totalSeconds) : 0.01
    }
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    func startTimer() {
        isTimerRunning = true
        elapsedSeconds = 0
        startTimerTick()
    }
    
    func startTimerTick() {
        isTimerCompleted = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.elapsedSeconds < self.totalSeconds {
                self.elapsedSeconds += 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.isTimerCompleted = true
                
                if self.isLoopEnabled {
                    self.elapsedSeconds = 0
                    self.isTimerCompleted = false
                    self.startTimerTick()
                }
            }
        }
    }
    
    func togglePause() {
        if timer == nil {
            startTimerTick()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        elapsedSeconds = 0
        isTimerCompleted = false
    }
}
