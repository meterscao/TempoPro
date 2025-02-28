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
    static let defaultTheme = MetronomeTheme(
        primaryColor: .blue,
        secondaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        strongBeatColor: .blue,
        mediumBeatColor: .blue,
        normalBeatColor: .blue,
        mutedBeatColor: Color.gray.opacity(0.2),
        currentBeatHighlightColor: .red
    )
    
    static let darkBlueTheme = MetronomeTheme(
        primaryColor: .blue.opacity(0.8),
        secondaryColor: .white,
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.2),
        textColor: .white,
        strongBeatColor: .blue,
        mediumBeatColor: .cyan,
        normalBeatColor: .teal,
        mutedBeatColor: Color.gray.opacity(0.2),
        currentBeatHighlightColor: .orange
    )
    
    static let warmTheme = MetronomeTheme(
        primaryColor: .orange,
        secondaryColor: .black,
        backgroundColor: Color(red: 0.95, green: 0.95, blue: 0.9),
        textColor: .black,
        strongBeatColor: .orange,
        mediumBeatColor: .yellow,
        normalBeatColor: .yellow.opacity(0.7),
        mutedBeatColor: Color.gray.opacity(0.3),
        currentBeatHighlightColor: .red
    )
}