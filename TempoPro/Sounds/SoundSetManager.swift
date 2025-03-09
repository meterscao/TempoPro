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
        SoundSet(displayName: "木鱼", key: "wood", fileNamePrefix: "wood"),
        SoundSet(displayName: "电子", key: "elec", fileNamePrefix: "elec"),
        SoundSet(displayName: "时钟", key: "clock", fileNamePrefix: "clock"),
        SoundSet(displayName: "拍手", key: "clap", fileNamePrefix: "clap"),
        SoundSet(displayName: "牛铃", key: "cowbell", fileNamePrefix: "cowbell"),
        SoundSet(displayName: "铃铛", key: "bell", fileNamePrefix: "bell"),
        SoundSet(displayName: "咔哒", key: "kada", fileNamePrefix: "kada"),
        
        
        
    ]
    // 获取默认音效
    static func getDefaultSoundSet() -> SoundSet {
        return availableSoundSets.first!
    }
    
    
    
}
