//
//  PrcticeViewModel.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/3.
//

import SwiftUI

class PracticeViewModel: ObservableObject {
    @Published var countdownType: CountdownType
    @Published var practiceStatus: PracticeStatus
    @Published var targetTime: Int
    @Published var targetBars: Int
    @Published var remainingTime: Int
    @Published var remainingBars: Int
    @Published var isLoopEnabled: Bool

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

    }
    

    // MARK: - 委托方法

    func didPracticeStatusChange(newStatus: PracticeStatus) {
        DispatchQueue.main.async {
            self.practiceStatus = newStatus
        }
    }

    func didCountdownTypeChange(newCountdownType: CountdownType) {
        DispatchQueue.main.async {
            self.countdownType = newCountdownType
        }
    }

    func didTargetTimeChange(newTargetTime: Int) {
        DispatchQueue.main.async {
            self.targetTime = newTargetTime
        }
    }

    func didTargetBarsChange(newTargetBars: Int) {
        DispatchQueue.main.async {
            self.targetBars = newTargetBars
        }
    }   

    func didRemainingTimeChange(newRemainingTime: Int) {
        DispatchQueue.main.async {
            self.remainingTime = newRemainingTime
        }
    }

    func didRemainingBarsChange(newRemainingBars: Int) {
        DispatchQueue.main.async {
            self.remainingBars = newRemainingBars
        }
    }

    func didIsLoopEnabledChange(newIsLoopEnabled: Bool) {
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
