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
    
    // MARK: - 初始化
    init() {
        // 1. 初始化服务
        
        // 2. 初始化控制器
        self.controller = MyController()
        
        // 3. 初始化视图模型
        self.viewModel = MyViewModel(controller: controller)
    }
    
    // MARK: - 公共接口
    var myViewModel: MyViewModel {
        return viewModel
    }
    
    // MARK: - 服务访问
    var myController: MyController {
        return controller
    }
}
