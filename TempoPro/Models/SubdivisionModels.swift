import Foundation

enum SubdivisionType: String, CaseIterable, Codable {
    case whole = "whole"
    case duple = "duple"
    case triplet = "triplet"
    case quadruple = "quadruple"
    case dotted = "dotted"
    case dupleTriplet = "duple_triplet" 
}

// 单个子音符结构
struct SubdivisionNote{
    // var id = UUID()
    var length: Double       // 相对长度 (例如: 0.5表示半拍)
    var isMuted: Bool        // 是否静音
    var noteValue: Int       // 音符类型 (例如: 8表示8分音符)
    
    // 辅助属性：获取音符名称
    var noteName: String {
        return "\(noteValue)分音符"
    }
}

// 一组切分音符模式
struct SubdivisionPattern{
//    var id = UUID()
    var name: String                    // 模式名称
    var displayName: String             // 显示名称
    var type: SubdivisionType           // 切分类型
    var notes: [SubdivisionNote]        // 组成这个模式的所有子音符
    var beatUnit: Int                   // 这个模式适用的拍号单位 (例如: 4表示4/4拍)
    var order: Int                      // 显示顺序，用于排序
    
    
    // 辅助计算属性：总长度
    var totalLength: Double {
        return notes.reduce(0) { $0 + $1.length }
    }
    
    // 辅助计算属性：描述
    var description: String {
        // 根据音符情况生成描述
        let notesDescription = notes.map { note -> String in
            if note.isMuted {
                return "休止"
            } else {
                return "\(note.noteValue)分音符"
            }
        }.joined(separator: "+")
        
        return notesDescription
    }
    
    // 详细描述，包含更多信息
    var detailedDescription: String {
        let notesDetail = notes.map { note -> String in
            let muteStatus = note.isMuted ? "静音" : "发音"
            return "\(note.noteValue)分音符(长度:\(note.length), \(muteStatus))"
        }.joined(separator: ", ")
        
        return "\(displayName)[\(name)]: \(notesDetail)"
    }
}

// 切分音符管理器 - 保存预定义的切分模式
struct SubdivisionManager {
    // 全局配置词典，按拍号单位组织所有可能的切分音符配置
    private static let globalSubdivisionPatterns: [Int: [SubdivisionPattern]] = [
        // 4分音符拍号单位的切分模式
        4: quarterNotePatterns,
        
        // 2分音符拍号单位的切分模式
        2: halfNotePatterns,
        
        // 8分音符拍号单位的切分模式
        8: eighthNotePatterns
    ]
    
    // 获取指定拍号单位下的所有切分模式列表，有序
    static func getSubdivisionPatterns(forBeatUnit beatUnit: Int) -> [SubdivisionPattern] {
        // 如果找到配置，返回按order排序的列表
        if let patterns = globalSubdivisionPatterns[beatUnit] {
            return patterns.sorted { $0.order < $1.order }
        }
        
        // 未找到配置时，返回空列表
        return []
    }
    
    // 获取特定拍号单位和切分类型的切分模式
    static func getSubdivisionPattern(forBeatUnit beatUnit: Int, type: SubdivisionType) -> SubdivisionPattern? {
        // 获取该拍号单位下的所有模式
        let patterns = getSubdivisionPatterns(forBeatUnit: beatUnit)
        
        // 如果没有找到相应拍号单位的配置，尝试使用4分音符的配置
        if patterns.isEmpty && beatUnit != 4 {
            return getSubdivisionPattern(forBeatUnit: 4, type: type)
        }
        
        let patternName = getPatternName(forBeatUnit: beatUnit, type: type)
        
        // 根据模式名称查找匹配的配置
        return patterns.first { $0.name == patternName }
    }
    
    // 根据名称获取切分模式
    static func getSubdivisionPattern(byName name: String) -> SubdivisionPattern? {
        // 遍历所有拍号单位的配置
        for (_, patterns) in globalSubdivisionPatterns {
            if let pattern = patterns.first(where: { $0.name == name }) {
                return pattern
            }
        }
        return nil
    }


    // 生成模式名称
    static func getPatternName(forBeatUnit beatUnit: Int, type: SubdivisionType) -> String {
        // 根据拍号单位确定前缀
        let prefix: String
        switch beatUnit {
        case 2: prefix = "half"
        case 4: prefix = "quarter"
        case 8: prefix = "eighth"
        case 16: prefix = "sixteenth"
        default: prefix = "quarter" // 默认使用四分音符
        }
        // 完整的模式名称
        let patternName = "\(prefix)_\(type.rawValue)"
        return patternName
    }
        
    
    // ===== 预定义的切分音符模式 =====
    
    // 4分音符拍号单位的切分模式
    private static let quarterNotePatterns: [SubdivisionPattern] = [
        // 1. 基本4分音符 (不切分)
        SubdivisionPattern(
            name: "quarter_whole",
            displayName: "整拍",
            type: .whole,
            
            notes: [
                SubdivisionNote(length: 1.0, isMuted: false, noteValue: 4)
            ],
            beatUnit: 4,
            order: 0
        ),
        
        // 2. 二等分 (2个8分音符)
        SubdivisionPattern(
            name: "quarter_duple",
            displayName: "二等分",
            type: .duple,
            notes: [
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 1
        ),
        
        // 3. 三连音 (3个8分音符三连音)
        SubdivisionPattern(
            name: "quarter_triplet",
            displayName: "三连音",
            type: .triplet,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.34, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 2
        ),
        
        // 4. 四等分 (4个16分音符)
        SubdivisionPattern(
            name: "quarter_quadruple",
            displayName: "四等分",
            type: .quadruple,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16)
            ],
            beatUnit: 4,
            order: 3
        ),
        
        // 5. 附点节奏 (附点8分音符+16分音符)
        SubdivisionPattern(
            name: "quarter_dotted",
            displayName: "附点节奏",
            type: .dotted,
            notes: [
                SubdivisionNote(length: 0.75, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16)
            ],
            beatUnit: 4,
            order: 4
        ),
        
        // 6. 二连三连音 (2组三连音)
        SubdivisionPattern(
            name: "quarter_duple_triplet",
            displayName: "二连三连音",
            type: .dupleTriplet,
            notes: [
                SubdivisionNote(length: 0.167, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.167, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.166, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.167, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.167, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.166, isMuted: false, noteValue: 16)
            ],
            beatUnit: 4,
            order: 5
        )
    ]
    
    // 2分音符拍号单位的切分模式
    private static let halfNotePatterns: [SubdivisionPattern] = [
        // 1. 基本2分音符 (不切分)
        SubdivisionPattern(
            name: "half_whole",
            displayName: "整拍",
            type: .whole,
            notes: [
                SubdivisionNote(length: 1.0, isMuted: false, noteValue: 2)
            ],
            beatUnit: 2,
            order: 0
        ),
        
        // 2. 二等分 (2个4分音符)
        SubdivisionPattern(
            name: "half_duple",
            displayName: "二等分",
            type: .duple,
            notes: [
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 4),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 4)
            ],
            beatUnit: 2,
            order: 1
        ),
        
        // 3. 三连音 (3个4分音符三连音)
        SubdivisionPattern(
            name: "half_triplet",
            displayName: "三连音",
            type: .triplet,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 4),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 4),
                SubdivisionNote(length: 0.34, isMuted: false, noteValue: 4)
            ],
            beatUnit: 2,
            order: 2
        ),
        
        // 4. 四等分 (4个8分音符)
        SubdivisionPattern(
            name: "half_quadruple",
            displayName: "四等分",
            type: .quadruple,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8)
            ],
            beatUnit: 2,
            order: 3
        )
    ]
    
    // 8分音符拍号单位的切分模式
    private static let eighthNotePatterns: [SubdivisionPattern] = [
        // 1. 基本8分音符 (不切分)
        SubdivisionPattern(
            name: "eighth_whole",
            displayName: "整拍",
            type: .whole,
            notes: [
                SubdivisionNote(length: 1.0, isMuted: false, noteValue: 8)
            ],
            beatUnit: 8,
            order: 0
        ),
        
        // 2. 二等分 (2个16分音符)
        SubdivisionPattern(
            name: "eighth_duple",
            displayName: "二等分",
            type: .duple,
            notes: [
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 16)
            ],
            beatUnit: 8,
            order: 1
        ),
        
        // 3. 三连音 (3个十六分音符三连音)
        SubdivisionPattern(
            name: "eighth_triplet",
            displayName: "三连音",
            type: .triplet,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.34, isMuted: false, noteValue: 16)
            ],
            beatUnit: 8,
            order: 2
        )
    ]
    
    // 获取所有支持的拍号单位列表
    static func getSupportedBeatUnits() -> [Int] {
        return Array(globalSubdivisionPatterns.keys).sorted()
    }
} 
