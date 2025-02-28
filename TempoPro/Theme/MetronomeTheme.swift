import SwiftUI

struct MetronomeTheme: Equatable {
    // 基础颜色
    let primaryColor: Color       // 主色调
    let secondaryColor: Color     // 次要色调
    let backgroundColor: Color    // 背景色
    let textColor: Color          // 文本颜色
    
    // 节拍器专用颜色
    let strongBeatColor: Color    // 强拍颜色
    let mediumBeatColor: Color    // 次强拍颜色
    let normalBeatColor: Color    // 普通拍颜色
    let mutedBeatColor: Color     // 静音拍颜色
    let currentBeatHighlightColor: Color // 当前拍高亮色
    
    // 预定义主题
    
    
    
    
    // 绿色主题 - 原版保留
    static let greenTheme = MetronomeTheme(
        primaryColor: Color(red: 0.56, green: 0.64, blue: 0.51),
        secondaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        strongBeatColor: Color(red: 0.56, green: 0.64, blue: 0.51),
        mediumBeatColor: Color(red: 0.56, green: 0.64, blue: 0.51),
        normalBeatColor: Color(red: 0.56, green: 0.64, blue: 0.51),
        mutedBeatColor: Color(red: 0.56, green: 0.64, blue: 0.51).opacity(0.2),
        currentBeatHighlightColor: .red
    )
    
    
    
    // 紫色主题
    static let purpleTheme = MetronomeTheme(
        primaryColor: Color(red: 0.58, green: 0.44, blue: 0.86),
        secondaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        strongBeatColor: Color(red: 0.58, green: 0.44, blue: 0.86),
        mediumBeatColor: Color(red: 0.58, green: 0.44, blue: 0.86),
        normalBeatColor: Color(red: 0.58, green: 0.44, blue: 0.86),
        mutedBeatColor: Color(red: 0.58, green: 0.44, blue: 0.86).opacity(0.2),
        currentBeatHighlightColor: .red
    )
    
    // 天蓝色主题
    static let skyBlueTheme = MetronomeTheme(
        primaryColor: Color(red: 0.40, green: 0.69, blue: 0.90),
        secondaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        strongBeatColor: Color(red: 0.40, green: 0.69, blue: 0.90),
        mediumBeatColor: Color(red: 0.40, green: 0.69, blue: 0.90),
        normalBeatColor: Color(red: 0.40, green: 0.69, blue: 0.90),
        mutedBeatColor: Color(red: 0.40, green: 0.69, blue: 0.90).opacity(0.2),
        currentBeatHighlightColor: .red
    )
    
    // 珊瑚红主题
    static let coralTheme = MetronomeTheme(
        primaryColor: Color(red: 0.96, green: 0.45, blue: 0.45),
        secondaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        strongBeatColor: Color(red: 0.96, green: 0.45, blue: 0.45),
        mediumBeatColor: Color(red: 0.96, green: 0.45, blue: 0.45),
        normalBeatColor: Color(red: 0.96, green: 0.45, blue: 0.45),
        mutedBeatColor: Color(red: 0.96, green: 0.45, blue: 0.45).opacity(0.2),
        currentBeatHighlightColor: Color(red: 1.0, green: 0.9, blue: 0.2)
    )
    
    // 琥珀色主题
    static let amberTheme = MetronomeTheme(
        primaryColor: Color(red: 0.95, green: 0.69, blue: 0.28),
        secondaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        strongBeatColor: Color(red: 0.95, green: 0.69, blue: 0.28),
        mediumBeatColor: Color(red: 0.95, green: 0.69, blue: 0.28),
        normalBeatColor: Color(red: 0.95, green: 0.69, blue: 0.28),
        mutedBeatColor: Color(red: 0.95, green: 0.69, blue: 0.28).opacity(0.2),
        currentBeatHighlightColor: .red
    )
    
    // 薰衣草色主题
    static let lavenderTheme = MetronomeTheme(
        primaryColor: Color(red: 0.71, green: 0.52, blue: 0.90),
        secondaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        strongBeatColor: Color(red: 0.71, green: 0.52, blue: 0.90),
        mediumBeatColor: Color(red: 0.71, green: 0.52, blue: 0.90),
        normalBeatColor: Color(red: 0.71, green: 0.52, blue: 0.90),
        mutedBeatColor: Color(red: 0.71, green: 0.52, blue: 0.90).opacity(0.2),
        currentBeatHighlightColor: .red
    )
    
    // 青绿色主题
    static let tealTheme = MetronomeTheme(
        primaryColor: Color(red: 0.18, green: 0.70, blue: 0.67),
        secondaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        strongBeatColor: Color(red: 0.18, green: 0.70, blue: 0.67),
        mediumBeatColor: Color(red: 0.18, green: 0.70, blue: 0.67),
        normalBeatColor: Color(red: 0.18, green: 0.70, blue: 0.67),
        mutedBeatColor: Color(red: 0.18, green: 0.70, blue: 0.67).opacity(0.2),
        currentBeatHighlightColor: .red
    )
    
    // 玫瑰金主题
    static let roseGoldTheme = MetronomeTheme(
        primaryColor: Color(red: 0.93, green: 0.56, blue: 0.54),
        secondaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        strongBeatColor: Color(red: 0.93, green: 0.56, blue: 0.54),
        mediumBeatColor: Color(red: 0.93, green: 0.56, blue: 0.54),
        normalBeatColor: Color(red: 0.93, green: 0.56, blue: 0.54),
        mutedBeatColor: Color(red: 0.93, green: 0.56, blue: 0.54).opacity(0.2),
        currentBeatHighlightColor: .red
    )
    
    // 沙漠色主题
    static let desertTheme = MetronomeTheme(
        primaryColor: Color(red: 0.92, green: 0.87, blue: 0.73),
        secondaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        strongBeatColor: Color(red: 0.92, green: 0.87, blue: 0.73),
        mediumBeatColor: Color(red: 0.92, green: 0.87, blue: 0.73),
        normalBeatColor: Color(red: 0.92, green: 0.87, blue: 0.73),
        mutedBeatColor: Color(red: 0.92, green: 0.87, blue: 0.73).opacity(0.2),
        currentBeatHighlightColor: .red
    )
}
