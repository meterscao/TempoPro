// ThemeManager.swift
import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var currentTheme: MetronomeTheme {
        didSet {
            // 保存主题选择
            UserDefaults.standard.set(currentThemeName, forKey: "selectedTheme")
        }
    }
    
    // 当前主题名称
    @Published var currentThemeName: String = "green" {
        didSet {
            if let theme = themes[currentThemeName] {
                currentTheme = theme
            }
        }
    }
    
    // 所有可用主题
    private var themes: [String: MetronomeTheme] = [
        // 现有主题
        "green": .defaultTheme,
        "purple": .purpleTheme,
        "skyBlue": .skyBlueTheme,
        "coral": .coralTheme,
        "amber": .amberTheme,
        "lavender": .lavenderTheme,
        "teal": .tealTheme,
        "roseGold": .roseGoldTheme,
        "desert": .desertTheme,
        
        // 新的复古科技风格主题
        "retroTerminal": .retroTerminalTheme,
        "cyberpunk": .cyberpunkTheme,
        "techBlue": .techBlueTheme,
        "amberRetro": .amberRetroTheme,
        "vintageViolet": .vintageVioletTheme,
        "neonFuture": .neonFutureTheme,
        "rustTech": .rustTechTheme,
        "militaryTech": .militaryTechTheme,
        "circuitBoard": .circuitBoardTheme,
        "deepSpace": .deepSpaceTheme
    ]
    
    // 可供选择的主题名称
    var availableThemes: [String] {
        return Array(themes.keys)
    }
    
    init() {
        // 读取保存的主题
        let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme") ?? "green"
        self.currentThemeName = savedThemeName
        self.currentTheme = themes[savedThemeName] ?? .defaultTheme
    }
    
    // 切换主题
    func switchTheme(to themeName: String) {
        guard themes.keys.contains(themeName) else { return }
        self.currentThemeName = themeName
    }
    
    // 添加自定义主题
    func addCustomTheme(name: String, theme: MetronomeTheme) {
        themes[name] = theme
    }

    // 获取主题颜色
    func themeColor(for themeName: String) -> Color {
        switch themeName.lowercased() {
        // 现有主题
        case "green": return MetronomeTheme.defaultTheme.primaryColor
        case "purple": return MetronomeTheme.purpleTheme.primaryColor
        case "skyblue": return MetronomeTheme.skyBlueTheme.primaryColor
        case "coral": return MetronomeTheme.coralTheme.primaryColor
        case "amber": return MetronomeTheme.amberTheme.primaryColor
        case "lavender": return MetronomeTheme.lavenderTheme.primaryColor
        case "teal": return MetronomeTheme.tealTheme.primaryColor
        case "rosegold": return MetronomeTheme.roseGoldTheme.primaryColor
        case "desert": return MetronomeTheme.desertTheme.primaryColor
        
        // 新的复古科技风格主题
        case "retroterminal": return MetronomeTheme.retroTerminalTheme.primaryColor
        case "cyberpunk": return MetronomeTheme.cyberpunkTheme.primaryColor
        case "techblue": return MetronomeTheme.techBlueTheme.primaryColor
        case "amberretro": return MetronomeTheme.amberRetroTheme.primaryColor
        case "vintageviolet": return MetronomeTheme.vintageVioletTheme.primaryColor
        case "neonfuture": return MetronomeTheme.neonFutureTheme.primaryColor
        case "rusttech": return MetronomeTheme.rustTechTheme.primaryColor
        case "militarytech": return MetronomeTheme.militaryTechTheme.primaryColor
        case "circuitboard": return MetronomeTheme.circuitBoardTheme.primaryColor
        case "deepspace": return MetronomeTheme.deepSpaceTheme.primaryColor
        
        default: return .gray
        }
    }
}