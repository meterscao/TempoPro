import UIKit

// 定义音效配置结构体
struct SoundSet {
    let displayName: String  // 显示名称
    let key: String         // 音效唯一标识符
    let fileNamePrefix: String  // 文件名前缀
    
    // 获取强拍、中拍、弱拍的文件名
    func getStrongBeatFileName() -> String {
        return "\(fileNamePrefix)_hi"
    }
    
    func getMediumBeatFileName() -> String {
        return "\(fileNamePrefix)_mid"
    }
    
    func getNormalBeatFileName() -> String {
        return "\(fileNamePrefix)_low"
    }
    
    // 获取所有文件名的元组
    func getAllFileNames() -> (strong: String, medium: String, normal: String) {
        return (
            getStrongBeatFileName(),
            getMediumBeatFileName(),
            getNormalBeatFileName()
        )
    }
}



// 工具类获取音效
class SoundSetManager {
    // 定义全局可用音效数组
    static var availableSoundSets: [SoundSet] = [
        SoundSet(displayName: "咔哒", key: "kada", fileNamePrefix: "kada"),
        SoundSet(displayName: "电子", key: "electronic", fileNamePrefix: "elec"),
        SoundSet(displayName: "木鱼", key: "wood", fileNamePrefix: "wood")
    ]
    // 获取默认音效
    static func getDefaultSoundSet() -> SoundSet {
        return availableSoundSets.first!
    }
    
    // 通过key获取音效
    static func getSoundSet(byKey key: String) -> SoundSet? {
        return availableSoundSets.first { $0.key == key }
    }
    
    // 检查音效文件是否存在
    static func checkSoundSetExists(_ soundSet: SoundSet) -> Bool {
        let fileNames = soundSet.getAllFileNames()
        let fileExtension = "wav"
        // 至少强拍文件必须存在
        return Bundle.main.path(forResource: fileNames.strong, ofType: fileExtension) != nil
    }
}
