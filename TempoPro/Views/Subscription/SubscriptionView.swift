//
//  SubscriptionView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/14.
//


import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack {
            if subscriptionManager.isLoading {
                ProgressView()
            } else if subscriptionManager.purchaseSuccess || subscriptionManager.isProUser {
                // 购买成功视图
                PurchaseSuccessView {
                    dismiss()
                }
            } else {
                // 自定义订阅UI
                SubscriptionOptionsView(offerings: subscriptionManager.offerings)
                    .environmentObject(subscriptionManager)
            }
        }
        .onAppear {
            subscriptionManager.checkSubscriptionStatus()
            subscriptionManager.loadOfferings()
        }
    }
}

// 新增购买成功视图
struct PurchaseSuccessView: View {
    @Environment(\.metronomeTheme) var theme
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .padding(.top, 40)
            
            Text("购买成功！")
                .font(.largeTitle)
                .bold()
                .foregroundColor(theme.primaryColor)
            
            Text("感谢您成为高级会员！\n您现在可以使用所有高级功能了。")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.primaryColor)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("开始使用")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryColor)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
    }
}

struct SubscriptionOptionsView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    let offerings: Offerings?
    @State private var selectedOption = 2 // 默认选中终身会员
    
    var body: some View {
        VStack(spacing: 24) {
            Text("升级到Premium会员")
                .font(.title)
                .bold()
                .foregroundColor(theme.primaryColor)
            
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
                if let package = getSelectedPackage() {
                    subscriptionManager.purchasePackage(package: package)
                }
            }) {
                Text(subscriptionManager.isPurchasing ? "处理中..." : "立即订阅")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryColor)
                    .cornerRadius(10)
            }
            .disabled(subscriptionManager.isPurchasing)
            
            // 条款说明
            Text("订阅会在到期前自动续费，可随时在账户设置中取消")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // 辅助方法获取选中的套餐
    private func getSelectedPackage() -> Package? {
        guard let offering = offerings?.current else { return nil }
        
        switch selectedOption {
        case 0:
            return offering.monthly
        case 1:
            return offering.annual
        case 2:
            return offering.lifetime
        default:
            return nil
        }
    }
}

struct FeatureRow: View {
    @Environment(\.metronomeTheme) var theme
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(theme.primaryColor)
            Text(text)
                .font(.body)
                .foregroundColor(theme.primaryColor)
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

