//
//  SubscriptionManager.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/18.
//


import SwiftUI
import RevenueCat

// 修改类继承自NSObject
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()
    
    // 发布订阅状态
    @Published var isProUser: Bool = false
    @Published var offerings: Offerings?
    @Published var isLoading: Bool = true
    @Published var isPurchasing: Bool = false
    @Published var purchaseSuccess: Bool = false
    
    // 私有初始化方法
    private override init() {
        // 先调用父类初始化
        super.init()
        
        // 配置RevenueCat
        Purchases.logLevel = .debug
        Purchases.proxyURL = URL(string: "https://api.rc-backup.com/")!
        Purchases.configure(withAPIKey: "appl_dAQzpTOdlfPEjSFkQNwqPYxfnvj")
        Purchases.shared.delegate = self
        
        // 初始化时检查订阅状态
        checkSubscriptionStatus()
        loadOfferings()
    }
    
    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, error) in
            guard let self = self else { return }
            
            if let customerInfo = customerInfo {
                // 检查"Premium Access"权限
                let isActive = customerInfo.entitlements["Premium Access"]?.isActive == true
                
                // 在主线程更新状态
                DispatchQueue.main.async {
                    self.isProUser = isActive
                }
            }
        }
    }
    
    // 从 SubscriptionView 迁移的方法
    func loadOfferings() {
        isLoading = true
        Purchases.shared.getOfferings { [weak self] offerings, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.offerings = offerings
                self.isLoading = false
            }
        }
    }
    
    // 从 SubscriptionView 迁移并优化的方法
    func purchasePackage(package: Package) {
        isPurchasing = true
        purchaseSuccess = false
        
        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isPurchasing = false
                
                if let error = error {
                    print("购买错误: \(error.localizedDescription)")
                    return
                }
                
                if userCancelled {
                    print("用户取消了购买")
                    return
                }
                
                // 购买成功
                if customerInfo?.entitlements["Premium Access"]?.isActive == true {
                    self.isProUser = true
                    self.purchaseSuccess = true
                    print("Premium权益已激活")
                }
            }
        }
    }

    func restorePurchase() {

        isPurchasing = true
        purchaseSuccess = false

        Purchases.shared.restorePurchases { customerInfo, error in
            self.isPurchasing = false
            
            // ... check customerInfo to see if entitlement is now active
            if customerInfo?.entitlements["Premium Access"]?.isActive == true {
                self.isProUser = true
                self.purchaseSuccess = true
                print("Premium权益已激活")
            }   
        }
    }

}

// 实现PurchasesDelegate
extension SubscriptionManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        // 订阅状态更新时，检查Premium Access权限
        let isActive = customerInfo.entitlements["Premium Access"]?.isActive == true
        
        // 在主线程更新状态
        DispatchQueue.main.async {
            self.isProUser = isActive
        }
    }
}

