//
//  MyConnector.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/4/2.
//

class MyConnector {
    // MARK: - 核心组件
    private let controller: MyController
    private let viewModel: MyViewModel
    
    // MARK: - 服务实例
    private let settingsService: MySettingsRepositoryService
    private let audioService: MetronomeAudioService
    private let timerService: MetronomeTimerService
    
    // MARK: - 初始化
    init() {
        // 1. 初始化服务
        self.settingsService = MySettingsRepositoryService()
        self.audioService = MetronomeAudioService.shared
        self.timerService = MetronomeTimerService()
        
        // 2. 初始化控制器
        self.controller = MyController(
            settingsService: settingsService,
            audioService: audioService,
            timerService: timerService
        )
        
        // 3. 初始化视图模型
        self.viewModel = MyViewModel(controller: controller)
    }
    
    // MARK: - 公共接口
    var metronomeViewModel: MyViewModel {
        return viewModel
    }
    
    // MARK: - 服务访问
    var metronomeController: MyController {
        return controller
    }
}
