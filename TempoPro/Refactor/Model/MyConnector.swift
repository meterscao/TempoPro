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
    private let thePracticeController: PracticeController
    private let thePracticeViewModel: PracticeViewModel
    
    // MARK: - 服务实例
    
    // MARK: - 初始化
    init() {
        // 1. 初始化服务
        
        // 2. 初始化控制器
        self.controller = MyController()
        self.thePracticeController = PracticeController(myController: controller)
        
        // 3. 初始化视图模型
        self.viewModel = MyViewModel(controller: controller)
        self.thePracticeViewModel = PracticeViewModel(practiceController: thePracticeController)
    }
    
    // MARK: - 公共接口
    var myViewModel: MyViewModel {
        return viewModel
    }

    var practiceViewModel: PracticeViewModel {
        return thePracticeViewModel
    }
    


    
}
