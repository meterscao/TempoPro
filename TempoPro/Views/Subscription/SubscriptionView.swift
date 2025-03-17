//
//  SubscriptionView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/14.
//


import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @State private var offerings: Offerings?
    @State private var isLoading = true
    @State private var customerInfo: CustomerInfo?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                // 自定义订阅UI
                SubscriptionOptionsView(offerings: offerings)
            }
        }
        .onAppear {
            loadOfferings()
            checkSubscriptionStatus()
        }
    }
    
    func loadOfferings() {
        isLoading = true
        Purchases.shared.getOfferings { offerings, error in
            self.offerings = offerings
            isLoading = false
        }
    }
    
    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { info, error in
            self.customerInfo = info
        }
    }
}

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

struct SubscriptionOption: View {
    let title: String
    let price: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(price)
                        .font(.title3)
                        .bold()
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubscriptionOptionsView: View {
    let offerings: Offerings?
    @State private var selectedOption = 2 // 默认选中年度
    @State private var isPurchasing = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("升级到Premium会员")
                .font(.title)
                .bold()
            
            // 会员特权展示
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(text: "无限访问所有高级功能")
                FeatureRow(text: "无广告体验")
                FeatureRow(text: "优先客户支持")
            }
            .padding(.vertical)
            
            // 选项选择器
            VStack(spacing: 12) {
                if let standardOffering = offerings?.current {
                    
                    
                    // 终身选项
                    SubscriptionOption(
                        title: "终身会员",
                        price: standardOffering.lifetime?.localizedPriceString ?? "¥??",
                        description: "一次性付款，永久有效",
                        isSelected: selectedOption == 2,
                        action: { selectedOption = 2 }
                    )
                }
            }
            
            // 订阅按钮
            Button(action: {
                purchaseSelectedOption()
            }) {
                Text(isPurchasing ? "处理中..." : "立即订阅")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(isPurchasing)
            
            // 条款说明
            Text("订阅会在到期前自动续费，可随时在账户设置中取消")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    func purchaseSelectedOption() {
        guard let offering = offerings?.current else { return }
        
        var packageToPurchase: Package?
        
        switch selectedOption {
        case 0:
            packageToPurchase = offering.monthly
        case 1:
            packageToPurchase = offering.annual
        case 2:
            packageToPurchase = offering.lifetime
        default:
            return
        }
        
        guard let package = packageToPurchase else { return }
        
        isPurchasing = true
        Purchases.shared.purchase(package: package) { transaction, customerInfo, error, userCancelled in
            isPurchasing = false
            
            if let error = error {
                print("购买错误: \(error.localizedDescription)")
                return
            }
            
            if userCancelled {
                print("用户取消了购买")
                return
            }
            
            // 购买成功
            if customerInfo?.entitlements["Premium"]?.isActive == true {
                print("Premium权益已激活")
                // 处理成功购买后的UI更新
            }
        }
    }
}

