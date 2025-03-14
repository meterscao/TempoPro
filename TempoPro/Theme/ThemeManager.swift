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
    func themeSets(for themeName: String) -> MetronomeTheme {
        switch themeName.lowercased() {
        // 现有主题
        case "green": return MetronomeTheme.defaultTheme
        case "purple": return MetronomeTheme.purpleTheme
        case "skyblue": return MetronomeTheme.skyBlueTheme
        case "coral": return MetronomeTheme.coralTheme
        case "amber": return MetronomeTheme.amberTheme
        case "lavender": return MetronomeTheme.lavenderTheme
        case "teal": return MetronomeTheme.tealTheme
        case "rosegold": return MetronomeTheme.roseGoldTheme
        case "desert": return MetronomeTheme.desertTheme
        
        // 新的复古科技风格主题
        case "retroterminal": return MetronomeTheme.retroTerminalTheme
        case "cyberpunk": return MetronomeTheme.cyberpunkTheme
        case "techblue": return MetronomeTheme.techBlueTheme
        case "amberretro": return MetronomeTheme.amberRetroTheme
        case "vintageviolet": return MetronomeTheme.vintageVioletTheme
        case "neonfuture": return MetronomeTheme.neonFutureTheme
        case "rusttech": return MetronomeTheme.rustTechTheme
        case "militarytech": return MetronomeTheme.militaryTechTheme
        case "circuitboard": return MetronomeTheme.circuitBoardTheme
        case "deepspace": return MetronomeTheme.deepSpaceTheme
        
        default: return MetronomeTheme.defaultTheme
        }
    }
}