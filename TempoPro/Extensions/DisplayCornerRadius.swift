import SwiftUI
import UIKit

// 创建圆角工具类
class DisplayCornerRadiusHelper {
    // 单例
    static let shared = DisplayCornerRadiusHelper()
    
    // 缓存圆角值，避免重复获取
    private var cachedCornerRadius: CGFloat?
    
    func getCornerRadius() -> CGFloat {
        // 如果已有缓存值，直接返回
        if let cachedCornerRadius = cachedCornerRadius {
            return cachedCornerRadius
        }
        
        var cornerRadius: CGFloat = 0
        
        if #available(iOS 13.0, *) {
            // 尝试使用私有API获取圆角值
            if let radius = UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat {
                cornerRadius = radius
            }
        }
        
        // 如果无法获取（旧设备、模拟器或私有API失效），使用设备判断的默认值
        if cornerRadius == 0 {
            let device = UIDevice.current
            
            // 根据设备类型设置默认圆角值
            if device.userInterfaceIdiom == .phone {
                // 判断是否是全面屏iPhone
                let screenHeight = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
                if screenHeight >= 812 { // iPhone X及更新机型的高度至少为812点
                    cornerRadius = 38.5 // 大多数全面屏iPhone的标准圆角
                }
            } else if device.userInterfaceIdiom == .pad {
                // iPad Pro等全面屏iPad
                cornerRadius = 20.0
            }
        }
        
        // 缓存结果
        cachedCornerRadius = cornerRadius
        return cornerRadius
    }
}

// 为View添加便捷方法
extension View {
    func withDeviceCornerRadius(adjustment: CGFloat = 0) -> some View {
        let cornerRadius = DisplayCornerRadiusHelper.shared.getCornerRadius() + adjustment
        return self.clipShape(
            .rect(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: 15,
                bottomTrailingRadius: 15,
                topTrailingRadius: cornerRadius
            )
        )
    }
}