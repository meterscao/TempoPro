import SwiftUI

struct MetronomeTheme: Equatable {
    // 基础颜色
    let primaryColor: Color       // 主色调
    let backgroundColor: Color    // 背景色
    let textColor: Color          // 文本颜色
    let beatBarColor: Color       // 节拍bar 颜色
    let beatBarHighlightColor: Color      // 节拍bar 高亮色
    
    // 绿色主题 - 原版保留
    static let defaultTheme = MetronomeTheme(
        primaryColor: Color(red: 0.56, green: 0.64, blue: 0.51),
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        textColor: .white,
        beatBarColor: Color(red: 0.9, green: 0.2, blue: 0.7) ,
        beatBarHighlightColor: .red
    )
    
    // 紫色主题
    static let purpleTheme = MetronomeTheme(
        primaryColor: Color(red: 0.58, green: 0.44, blue: 0.86),
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        textColor: .white,
        beatBarColor: Color(red: 0.95, green: 0.95, blue: 0.1), // 亮黄色，紫色的对比色
        beatBarHighlightColor: .red
    )
    
    // 天蓝色主题
    static let skyBlueTheme = MetronomeTheme(
        primaryColor: Color(red: 0.40, green: 0.69, blue: 0.90),
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        textColor: .white,
        beatBarColor: Color(red: 0.95, green: 0.6, blue: 0.1), // 橙色，蓝色的对比色
        beatBarHighlightColor: Color(red: 0.95, green: 0.6, blue: 0.1)
    )

    // 珊瑚红主题
    static let coralTheme = MetronomeTheme(
        primaryColor: Color(red: 0.96, green: 0.45, blue: 0.45),
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        textColor: .white,
        beatBarColor: Color(red: 0.1, green: 0.8, blue: 0.8), // 青色，红色的对比色
        beatBarHighlightColor: .red
    )
    
    // 琥珀色主题
    static let amberTheme = MetronomeTheme(
        primaryColor: Color(red: 0.95, green: 0.69, blue: 0.28),
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        textColor: .white,  
        beatBarColor: Color(red: 0.1, green: 0.3, blue: 0.9), // 深蓝色，琥珀色的对比色
        beatBarHighlightColor: .red
    )
    
    // 薰衣草色主题
    static let lavenderTheme = MetronomeTheme(
        primaryColor: Color(red: 0.71, green: 0.52, blue: 0.90),
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        textColor: .white,
        beatBarColor: Color(red: 0.6, green: 0.95, blue: 0.1), // 黄绿色，薰衣草色的对比色
        beatBarHighlightColor: .red
    )
    
    // 青绿色主题
    static let tealTheme = MetronomeTheme(
        primaryColor: Color(red: 0.18, green: 0.70, blue: 0.67),
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        textColor: .white,
        beatBarColor: Color(red: 0.95, green: 0.1, blue: 0.3), // 红色，青绿色的对比色
        beatBarHighlightColor: .red
    )
    
    // 玫瑰金主题
    static let roseGoldTheme = MetronomeTheme(
        primaryColor: Color(red: 0.93, green: 0.56, blue: 0.54),
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        textColor: .white,
        beatBarColor: Color(red: 0.1, green: 0.6, blue: 0.9), // 青蓝色，玫瑰金的对比色
        beatBarHighlightColor: .red
    )
    
    // 沙漠色主题
    static let desertTheme = MetronomeTheme(
        primaryColor: Color(red: 0.92, green: 0.87, blue: 0.73),
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        textColor: .white,
        beatBarColor: Color(red: 0.3, green: 0.2, blue: 0.9), // 蓝紫色，沙漠色的对比色
        beatBarHighlightColor: .red
    )

    // 新的复古科技风格主题
    static let retroTerminalTheme = MetronomeTheme(
        primaryColor: Color(red: 0.0, green: 0.8, blue: 0.2),
        backgroundColor: Color(red: 0.05, green: 0.05, blue: 0.05),
        textColor: Color(red: 0.0, green: 0.9, blue: 0.3),
        beatBarColor: Color(red: 0.5, green: 0.0, blue: 0.5),       // 紫色对比
        beatBarHighlightColor: Color(red: 1.0, green: 1.0, blue: 0.0) // 黄色高亮
    )
    
    static let cyberpunkTheme = MetronomeTheme(
        primaryColor: Color(red: 0.9, green: 0.1, blue: 0.6),
        backgroundColor: Color(red: 0.07, green: 0.0, blue: 0.1),
        textColor: Color(red: 0.0, green: 0.9, blue: 1.0),
        beatBarColor: Color(red: 0.0, green: 0.6, blue: 0.8),       // 青色对比
        beatBarHighlightColor: Color(red: 1.0, green: 0.8, blue: 0.0) // 金黄色高亮
    )
    
    static let techBlueTheme = MetronomeTheme(
        primaryColor: Color(red: 0.1, green: 0.5, blue: 0.9),
        backgroundColor: Color(red: 0.05, green: 0.07, blue: 0.12),
        textColor: Color(red: 0.7, green: 0.8, blue: 1.0),
        beatBarColor: Color(red: 0.9, green: 0.2, blue: 0.1),       // 红色对比
        beatBarHighlightColor: Color(red: 0.0, green: 1.0, blue: 0.5) // 青绿色高亮
    )
    
    static let amberRetroTheme = MetronomeTheme(
        primaryColor: Color(red: 0.9, green: 0.6, blue: 0.0),
        backgroundColor: Color(red: 0.1, green: 0.07, blue: 0.03),
        textColor: Color(red: 1.0, green: 0.8, blue: 0.3),
        beatBarColor: Color(red: 0.1, green: 0.2, blue: 0.7),       // 深蓝色对比
        beatBarHighlightColor: Color(red: 1.0, green: 0.3, blue: 0.0) // 亮橙色高亮
    )
    
    static let vintageVioletTheme = MetronomeTheme(
        primaryColor: Color(red: 0.6, green: 0.2, blue: 0.8),
        backgroundColor: Color(red: 0.08, green: 0.03, blue: 0.12),
        textColor: Color(red: 0.8, green: 0.6, blue: 1.0),
        beatBarColor: Color(red: 0.0, green: 0.8, blue: 0.3),       // 绿色对比
        beatBarHighlightColor: Color(red: 1.0, green: 0.7, blue: 0.0) // 金色高亮
    )
    
    static let neonFutureTheme = MetronomeTheme(
        primaryColor: Color(red: 0.0, green: 0.9, blue: 0.9),
        backgroundColor: Color(red: 0.06, green: 0.02, blue: 0.1),
        textColor: Color(red: 0.0, green: 1.0, blue: 1.0),
        beatBarColor: Color(red: 0.9, green: 0.1, blue: 0.9),       // 桃红色对比
        beatBarHighlightColor: Color(red: 1.0, green: 0.9, blue: 0.0) // 明黄色高亮
    )
    
    static let rustTechTheme = MetronomeTheme(
        primaryColor: Color(red: 0.7, green: 0.25, blue: 0.1),
        backgroundColor: Color(red: 0.1, green: 0.05, blue: 0.03),
        textColor: Color(red: 0.9, green: 0.5, blue: 0.3),
        beatBarColor: Color(red: 0.0, green: 0.6, blue: 0.8),       // 青蓝色对比
        beatBarHighlightColor: Color(red: 1.0, green: 0.9, blue: 0.4) // 亮黄色高亮
    )
    
    static let militaryTechTheme = MetronomeTheme(
        primaryColor: Color(red: 0.2, green: 0.4, blue: 0.2),
        backgroundColor: Color(red: 0.05, green: 0.07, blue: 0.05),
        textColor: Color(red: 0.7, green: 0.9, blue: 0.5),
        beatBarColor: Color(red: 0.7, green: 0.0, blue: 0.0),       // 红色对比
        beatBarHighlightColor: Color(red: 1.0, green: 0.8, blue: 0.0) // 金黄色高亮
    )
    
    static let circuitBoardTheme = MetronomeTheme(
        primaryColor: Color(red: 0.1, green: 0.7, blue: 0.3),
        backgroundColor: Color(red: 0.03, green: 0.08, blue: 0.05),
        textColor: Color(red: 0.5, green: 0.9, blue: 0.6),
        beatBarColor: Color(red: 0.8, green: 0.2, blue: 0.8),       // 紫色对比
        beatBarHighlightColor: Color(red: 1.0, green: 0.9, blue: 0.0) // 亮黄色高亮
    )
    
    static let deepSpaceTheme = MetronomeTheme(
        primaryColor: Color(red: 0.3, green: 0.3, blue: 0.6),
        backgroundColor: Color(red: 0.02, green: 0.03, blue: 0.08),
        textColor: Color(red: 0.6, green: 0.7, blue: 1.0),
        beatBarColor: Color(red: 0.9, green: 0.5, blue: 0.0),       // 橙色对比
        beatBarHighlightColor: Color(red: 0.0, green: 1.0, blue: 0.8) // 青绿色高亮
    )

    static let silverTheme = MetronomeTheme(
        primaryColor: Color(red: 0.8, green: 0.8, blue: 0.8),
        backgroundColor: Color(red: 0.05, green: 0.05, blue: 0.05),
        textColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        beatBarColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        beatBarHighlightColor: Color(red: 0.1, green: 0.1, blue: 0.1)
    )   

    static let deepGrayTheme = MetronomeTheme(
        primaryColor: Color(red: 0.2, green: 0.2, blue: 0.2),
        backgroundColor: Color(red: 0.05, green: 0.05, blue: 0.05),
        textColor: Color(red: 0.8, green: 0.8, blue: 0.8),
        beatBarColor: Color(red: 0.8, green: 0.8, blue: 0.8),
        beatBarHighlightColor: Color(red: 0.8, green: 0.8, blue: 0.8)
    )   
}
