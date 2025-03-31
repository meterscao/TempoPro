//
//  StorageService.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/31.
//

import Foundation

// 存储服务
class UserDefaultsStorageService {
    private let settingsKey = "com.metronome.settings"
    private let presetsKey = "com.metronome.presets"
    
    func saveSettings(_ settings: MetronomeSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    func loadSettings() -> MetronomeSettings? {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(MetronomeSettings.self, from: data) else {
            return nil
        }
        return settings
    }

    func savePresets(_ presets: [MetronomePreset]) {
        if let encoded = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(encoded, forKey: presetsKey)
        }
    }

    func loadPresets() -> [MetronomePreset]? {
        guard let data = UserDefaults.standard.data(forKey: presetsKey),
              let presets = try? JSONDecoder().decode([MetronomePreset].self, from: data) else {
            return nil
        }
        return presets
    }
}
