//
//  ThemeManager.swift
//  TempoPro
//
//  Created by Meters on 28/2/2025.
//

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
        "green": .greenTheme,
        "purple": .purpleTheme,
        "skyBlue": .skyBlueTheme,
        "coral": .coralTheme,
        "amber": .amberTheme,
        "lavender": .lavenderTheme,
        "teal": .tealTheme,
        "roseGold": .roseGoldTheme,
        "desert": .desertTheme
    ]
    
    // 可供选择的主题名称
    var availableThemes: [String] {
        return Array(themes.keys)
    }
    
    init() {
        // 读取保存的主题
        let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme") ?? "green"
        self.currentThemeName = savedThemeName
        self.currentTheme = themes[savedThemeName] ?? .greenTheme
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

    // 在 ThemeManager 类中添加此方法
    func themeColor(for themeName: String) -> Color {
        switch themeName.lowercased() {
        case "green": return MetronomeTheme.greenTheme.primaryColor
        case "purple": return MetronomeTheme.purpleTheme.primaryColor
        case "skyblue": return MetronomeTheme.skyBlueTheme.primaryColor
        case "coral": return MetronomeTheme.coralTheme.primaryColor
        case "amber": return MetronomeTheme.amberTheme.primaryColor
        case "lavender": return MetronomeTheme.lavenderTheme.primaryColor
        case "teal": return MetronomeTheme.tealTheme.primaryColor
        case "rosegold": return MetronomeTheme.roseGoldTheme.primaryColor
        case "desert": return MetronomeTheme.desertTheme.primaryColor
        default: return .gray
        }
    }
}
