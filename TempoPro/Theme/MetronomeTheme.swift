import SwiftUI

struct MetronomeTheme: Equatable {
    // 基础颜色
    let primaryColor: Color       // 主色调
    let backgroundColor: Color    // 背景色
    let textColor: Color          // 文本颜色
    let beatBarColor: Color       // 节拍bar 颜色
    let beatBarHighlightColor: Color      // 节拍bar 高亮色
    
    // 绿色主题 - 原版保留
    static let oliveTheme = MetronomeTheme(
        primaryColor: Color(hex: "B9B9B9"),
        backgroundColor: Color(hex: "1a1a1a"),
        textColor: .white,
        beatBarColor: Color(hex: "#468B6C"),
        beatBarHighlightColor: .red
    )

     static let defaultTheme = MetronomeTheme(
        primaryColor: Color(hex: "CCCCCC"),
        backgroundColor: Color(hex: "0D0D0D"),
        textColor: Color(hex: "1A1A1A"),
        beatBarColor: Color(hex: "F2F219"), // 亮黄色，紫色的对比色
        beatBarHighlightColor: Color(hex: "FF0000")
    )  
    
    // 紫色主题
    static let purpleTheme = MetronomeTheme(
        primaryColor: Color(hex: "9470DB"),
        backgroundColor: Color(hex: "1a1a1a"),
        textColor: .white,
        beatBarColor: Color(hex: "F2F219"), // 亮黄色，紫色的对比色
        beatBarHighlightColor: .red
    )
    
    // 天蓝色主题
    static let skyBlueTheme = MetronomeTheme(
        primaryColor: Color(hex: "66B0E6"),
        backgroundColor: Color(hex: "1a1a1a"),
        textColor: .white,
        beatBarColor: Color(hex: "F2991A"), // 橙色，蓝色的对比色
        beatBarHighlightColor: Color(hex: "F2991A")
    )

    // 珊瑚红主题
    static let coralTheme = MetronomeTheme(
        primaryColor: Color(hex: "F57373"),
        backgroundColor: Color(hex: "1a1a1a"),
        textColor: .white,
        beatBarColor: Color(hex: "19CCCC"), // 青色，红色的对比色
        beatBarHighlightColor: .red
    )
    
    // 琥珀色主题
    static let amberTheme = MetronomeTheme(
        primaryColor: Color(hex: "F2B047"),
        backgroundColor: Color(hex: "1a1a1a"),
        textColor: .white,  
        beatBarColor: Color(hex: "194DE6"), // 深蓝色，琥珀色的对比色
        beatBarHighlightColor: .red
    )
    
    // 薰衣草色主题
    static let lavenderTheme = MetronomeTheme(
        primaryColor: Color(hex: "B585E6"),
        backgroundColor: Color(hex: "1a1a1a"),
        textColor: .white,
        beatBarColor: Color(hex: "99F219"), // 黄绿色，薰衣草色的对比色
        beatBarHighlightColor: .red
    )
    
    // 青绿色主题
    static let tealTheme = MetronomeTheme(
        primaryColor: Color(hex: "2EB3AB"),
        backgroundColor: Color(hex: "1a1a1a"),
        textColor: .white,
        beatBarColor: Color(hex: "F2194D"), // 红色，青绿色的对比色
        beatBarHighlightColor: .red
    )
    
    // 玫瑰金主题
    static let roseGoldTheme = MetronomeTheme(
        primaryColor: Color(hex: "ED8F8A"),
        backgroundColor: Color(hex: "1a1a1a"),
        textColor: .white,
        beatBarColor: Color(hex: "1999E6"), // 青蓝色，玫瑰金的对比色
        beatBarHighlightColor: .red
    )
    
    // 沙漠色主题
    static let desertTheme = MetronomeTheme(
        primaryColor: Color(hex: "EBDEBA"),
        backgroundColor: Color(hex: "1a1a1a"),
        textColor: .white,
        beatBarColor: Color(hex: "4D33E6"), // 蓝紫色，沙漠色的对比色
        beatBarHighlightColor: .red
    )

    // 新的复古科技风格主题
    static let retroTerminalTheme = MetronomeTheme(
        primaryColor: Color(hex: "00CC33"),
        backgroundColor: Color(hex: "0D0D0D"),
        textColor: Color(hex: "00E64D"),
        beatBarColor: Color(hex: "800080"),       // 紫色对比
        beatBarHighlightColor: Color(hex: "FFFF00") // 黄色高亮
    )
    
    static let cyberpunkTheme = MetronomeTheme(
        primaryColor: Color(hex: "E61A99"),
        backgroundColor: Color(hex: "12001A"),
        textColor: Color(hex: "00E6FF"),
        beatBarColor: Color(hex: "0099CC"),       // 青色对比
        beatBarHighlightColor: Color(hex: "FFCC00") // 金黄色高亮
    )
    
    static let techBlueTheme = MetronomeTheme(
        primaryColor: Color(hex: "1A80E6"),
        backgroundColor: Color(hex: "0D121F"),
        textColor: Color(hex: "B3CCFF"),
        beatBarColor: Color(hex: "E6331A"),       // 红色对比
        beatBarHighlightColor: Color(hex: "00FF80") // 青绿色高亮
    )
    
    static let amberRetroTheme = MetronomeTheme(
        primaryColor: Color(hex: "E69900"),
        backgroundColor: Color(hex: "1A1208"),
        textColor: Color(hex: "FFCC4D"),
        beatBarColor: Color(hex: "1A33B3"),       // 深蓝色对比
        beatBarHighlightColor: Color(hex: "FF4D00") // 亮橙色高亮
    )
    
    static let vintageVioletTheme = MetronomeTheme(
        primaryColor: Color(hex: "9933CC"),
        backgroundColor: Color(hex: "14081F"),
        textColor: Color(hex: "CC99FF"),
        beatBarColor: Color(hex: "00CC4D"),       // 绿色对比
        beatBarHighlightColor: Color(hex: "FFB300") // 金色高亮
    )
    
    static let neonFutureTheme = MetronomeTheme(
        primaryColor: Color(hex: "00E6E6"),
        backgroundColor: Color(hex: "0F051A"),
        textColor: Color(hex: "00FFFF"),
        beatBarColor: Color(hex: "E619E6"),       // 桃红色对比
        beatBarHighlightColor: Color(hex: "FFE600") // 明黄色高亮
    )
    
    static let rustTechTheme = MetronomeTheme(
        primaryColor: Color(hex: "B3401A"),
        backgroundColor: Color(hex: "1A0D08"),
        textColor: Color(hex: "E6804D"),
        beatBarColor: Color(hex: "0099CC"),       // 青蓝色对比
        beatBarHighlightColor: Color(hex: "FFE666") // 亮黄色高亮
    )
    
    static let militaryTechTheme = MetronomeTheme(
        primaryColor: Color(hex: "336633"),
        backgroundColor: Color(hex: "0D120D"),
        textColor: Color(hex: "B3E680"),
        beatBarColor: Color(hex: "B30000"),       // 红色对比
        beatBarHighlightColor: Color(hex: "FFCC00") // 金黄色高亮
    )
    
    static let circuitBoardTheme = MetronomeTheme(
        primaryColor: Color(hex: "1AB34D"),
        backgroundColor: Color(hex: "08140D"),
        textColor: Color(hex: "80E699"),
        beatBarColor: Color(hex: "CC33CC"),       // 紫色对比
        beatBarHighlightColor: Color(hex: "FFE600") // 亮黄色高亮
    )
    
    static let deepSpaceTheme = MetronomeTheme(
        primaryColor: Color(hex: "4D4D99"),
        backgroundColor: Color(hex: "050814"),
        textColor: Color(hex: "99B3FF"),
        beatBarColor: Color(hex: "E68000"),       // 橙色对比
        beatBarHighlightColor: Color(hex: "00FFCC") // 青绿色高亮
    )

    

    static let deepGrayTheme = MetronomeTheme(
        primaryColor: Color(hex: "333333"),
        backgroundColor: Color(hex: "0D0D0D"),
        textColor: Color(hex: "CCCCCC"),
        beatBarColor: Color(hex: "CCCCCC"),
        beatBarHighlightColor: Color(hex: "CCCCCC")
    )   
}