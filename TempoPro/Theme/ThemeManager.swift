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
    @Published var currentThemeName: String = "silver" {
        didSet {
            if let theme = themes[currentThemeName] {
                currentTheme = theme
            }
        }
    }
    
    // 定义一个有序的主题名称数组
    private let themeNames: [String] = [
        
        "silver",
        "olive",
        "purple",
        "skyBlue",
        "coral",
        "amber",
        "lavender",
        "teal",
        "roseGold",
        "desert",
        
        // 复古科技风格主题
        "retroTerminal",
        "cyberpunk",
        "techBlue",
        "amberRetro",
        "vintageViolet",
        "neonFuture",
        "rustTech",
        "militaryTech",
        "circuitBoard",
        "deepSpace",
        "deepGray"
    ]
    
    // 所有可用主题
    private var themes: [String: MetronomeTheme] = [:]
    
    // 可供选择的主题名称（有序）
    var availableThemes: [String] {
        return themeNames
    }
    
    init() {
        // 先设置一个默认主题，确保所有属性都被初始化
        self.currentTheme = .defaultTheme
        
        // 初始化主题字典
        setupThemes()
        
        // 读取保存的主题
        let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme") ?? "silver"
        self.currentThemeName = savedThemeName
        if let theme = themes[savedThemeName] {
            self.currentTheme = theme
        }
    }
    
    // 设置所有主题
    private func setupThemes() {
        // 现有主题
        themes["silver"] = .defaultTheme
        themes["purple"] = .purpleTheme
        themes["skyBlue"] = .skyBlueTheme
        themes["coral"] = .coralTheme
        themes["amber"] = .amberTheme
        themes["lavender"] = .lavenderTheme
        themes["teal"] = .tealTheme
        themes["roseGold"] = .roseGoldTheme
        themes["desert"] = .desertTheme
        
        // 新的复古科技风格主题
        themes["retroTerminal"] = .retroTerminalTheme
        themes["cyberpunk"] = .cyberpunkTheme
        themes["techBlue"] = .techBlueTheme
        themes["amberRetro"] = .amberRetroTheme
        themes["vintageViolet"] = .vintageVioletTheme
        themes["neonFuture"] = .neonFutureTheme
        themes["rustTech"] = .rustTechTheme
        themes["militaryTech"] = .militaryTechTheme
        themes["circuitBoard"] = .circuitBoardTheme
        themes["deepSpace"] = .deepSpaceTheme
        themes["olive"] = .oliveTheme
        themes["deepGray"] = .deepGrayTheme
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
        case "silver": return MetronomeTheme.defaultTheme
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
        case "olive": return MetronomeTheme.oliveTheme
        case "deepgray": return MetronomeTheme.deepGrayTheme
        default: return MetronomeTheme.defaultTheme
        }
    }
}