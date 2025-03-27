import Foundation

enum SubdivisionType: String, CaseIterable, Codable {
    case whole = "whole"
    case duple = "duple" 
    case resteighth = "resteighth"
    case triplet = "triplet"
    case tripletRestBegin = "triplet_rest_begin"
    case tripletRestMiddle = "triplet_rest_middle" 
    case tripletRestEnd = "triplet_rest_end"
    case tripletRestSurround = "triplet_rest_surround"
    case quadruplet = "quadruplet"
    case doubleRestSixteenth = "double_rest_sixteenth"
    case eighthTwoSixteenth = "eighth_two_sixteenth"
    case twoSixteenthEighth = "two_sixteenth_eighth"
    case eighthDottedSixteenth = "eighth_dotted_sixteenth"
    case sixteenthEighthSixteenth = "sixteenth_eighth_sixteenth"
    case sixteenthEighthDotted = "sixteenth_eighth_dotted"
}

// 单个子音符结构
struct SubdivisionNote{
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
        // 全音符拍号单位的切分模式
        1: fullNotePatterns,

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
            print("patterns: \(patterns)")
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
        case 1: prefix = "full"
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
    
    private static let quarterNotePatterns: [SubdivisionPattern] = [
        // 1. 基本4分音符 (不切分) - Frame 12
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
        
        // 2. 二等分 (2个8分音符) - Frame 3
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
        
        // 3. 8分音符加8分休止符 - Frame 22
        SubdivisionPattern(
            name: "quarter_resteighth",
            displayName: "八分-休止",
            type: .resteighth,
            notes: [
                SubdivisionNote(length: 0.5, isMuted: true, noteValue: 8),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8),
            ],
            beatUnit: 4,
            order: 2
        ),
        
        // 4. 三连音 (3个8分音符三连音) - Frame 36
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
            order: 3
        ),
        
        // 5. 三连音-开头休止符 - Frame 15
        SubdivisionPattern(
            name: "quarter_triplet_rest_begin",
            displayName: "三连音-首休",
            type: .tripletRestBegin,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: true, noteValue: 8),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.34, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 4
        ),
        
        // 6. 三连音-中间休止符 - Frame 16
        SubdivisionPattern(
            name: "quarter_triplet_rest_middle",
            displayName: "三连音-中休",
            type: .tripletRestMiddle,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.33, isMuted: true, noteValue: 8),
                SubdivisionNote(length: 0.34, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 5
        ),
        
        // 7. 三连音-末尾休止符 - Frame 17
        SubdivisionPattern(
            name: "quarter_triplet_rest_end",
            displayName: "三连音-尾休",
            type: .tripletRestEnd,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.34, isMuted: true, noteValue: 8)
            ],
            beatUnit: 4,
            order: 6
        ),
        
        // 8. 三连音-两端休止符 - Frame 23
        SubdivisionPattern(
            name: "quarter_triplet_rest_surround",
            displayName: "三连音-双休",
            type: .tripletRestSurround,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: true, noteValue: 8),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.34, isMuted: true, noteValue: 8)
            ],
            beatUnit: 4,
            order: 7
        ),
        
        // 9. 四等分 (4个16分音符) - Frame 4
        SubdivisionPattern(
            name: "quarter_quadruplet",
            displayName: "四等分",
            type: .quadruplet,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16)
            ],
            beatUnit: 4,
            order: 8
        ),
        
        // 10. 双休止符十六分音符 - Frame 24
        SubdivisionPattern(
            name: "quarter_double_rest_sixteenth",
            displayName: "双休-十六分",
            type: .doubleRestSixteenth,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: true, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: true, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
            ],
            beatUnit: 4,
            order: 9
        ),
        
        // 11. 八分音符加两个十六分音符 - Frame 18
        SubdivisionPattern(
            name: "quarter_eighth_two_sixteenth",
            displayName: "八分-两十六分",
            type: .eighthTwoSixteenth,
            notes: [
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16)
            ],
            beatUnit: 4,
            order: 10
        ),
        
        // 12. 两个十六分音符加八分音符 - Frame 19
        SubdivisionPattern(
            name: "quarter_two_sixteenth_eighth",
            displayName: "两十六分-八分",
            type: .twoSixteenthEighth,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 11
        ),
        
        // 13. 八分音符加附点八分音符 - Frame 20
        SubdivisionPattern(
            name: "quarter_eighth_dotted_sixteenth",
            displayName: "八分-附点-十六分",
            type: .eighthDottedSixteenth,
            notes: [
                SubdivisionNote(length: 0.75, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
            ],
            beatUnit: 4,
            order: 12
        ),
        
        // 14. 八分音符加八分音符加八分音符 - Frame 21
        SubdivisionPattern(
            name: "quarter_sixteenth_eighth_sixteenth",
            displayName: "十六分-八分-十六分",
            type: .sixteenthEighthSixteenth,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 13
        ),
        
        // 15. 附点八分音符加八分音符 - Frame 13
        SubdivisionPattern(
            name: "quarter_sixteenth_eighth_dotted",
            displayName: "附点八分-八分",
            type: .sixteenthEighthDotted,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.75, isMuted: false, noteValue: 8),
            ],
            beatUnit: 4,
            order: 14
        )
    ]
    
   private static let halfNotePatterns: [SubdivisionPattern] = [
    // 1. whole
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
    
    // 2. duple
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
    
    // 3. resteighth
    SubdivisionPattern(
        name: "half_resteighth",
        displayName: "四分-休止",
        type: .resteighth,
        notes: [
            SubdivisionNote(length: 0.5, isMuted: true, noteValue: 4),
            SubdivisionNote(length: 0.5, isMuted: false, noteValue: 4),
        ],
        beatUnit: 2,
        order: 2
    ),
    
    // 4. triplet
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
        order: 3
    ),
    
    // 5. tripletRestBegin
    SubdivisionPattern(
        name: "half_triplet_rest_begin",
        displayName: "三连音-首休",
        type: .tripletRestBegin,
        notes: [
            SubdivisionNote(length: 0.33, isMuted: true, noteValue: 4),
            SubdivisionNote(length: 0.33, isMuted: false, noteValue: 4),
            SubdivisionNote(length: 0.34, isMuted: false, noteValue: 4)
        ],
        beatUnit: 2,
        order: 4
    ),
    
    // 6. tripletRestMiddle
    SubdivisionPattern(
        name: "half_triplet_rest_middle",
        displayName: "三连音-中休",
        type: .tripletRestMiddle,
        notes: [
            SubdivisionNote(length: 0.33, isMuted: false, noteValue: 4),
            SubdivisionNote(length: 0.33, isMuted: true, noteValue: 4),
            SubdivisionNote(length: 0.34, isMuted: false, noteValue: 4)
        ],
        beatUnit: 2,
        order: 5
    ),
    
    // 7. tripletRestEnd
    SubdivisionPattern(
        name: "half_triplet_rest_end",
        displayName: "三连音-尾休",
        type: .tripletRestEnd,
        notes: [
            SubdivisionNote(length: 0.33, isMuted: false, noteValue: 4),
            SubdivisionNote(length: 0.33, isMuted: false, noteValue: 4),
            SubdivisionNote(length: 0.34, isMuted: true, noteValue: 4)
        ],
        beatUnit: 2,
        order: 6
    ),
    
    // 8. tripletRestSurround
    SubdivisionPattern(
        name: "half_triplet_rest_surround",
        displayName: "三连音-双休",
        type: .tripletRestSurround,
        notes: [
            SubdivisionNote(length: 0.33, isMuted: true, noteValue: 4),
            SubdivisionNote(length: 0.33, isMuted: false, noteValue: 4),
            SubdivisionNote(length: 0.34, isMuted: true, noteValue: 4)
        ],
        beatUnit: 2,
        order: 7
    ),
    
    // 9. quadruplet
    SubdivisionPattern(
        name: "half_quadruplet",
        displayName: "四等分",
        type: .quadruplet,
        notes: [
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8)
        ],
        beatUnit: 2,
        order: 8
    ),
    
    // 10. doubleRestSixteenth
    SubdivisionPattern(
        name: "half_double_rest_sixteenth",
        displayName: "双休-四分",
        type: .doubleRestSixteenth,
        notes: [
            SubdivisionNote(length: 0.25, isMuted: true, noteValue: 8),
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
            SubdivisionNote(length: 0.25, isMuted: true, noteValue: 8),
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
        ],
        beatUnit: 2,
        order: 9
    ),
    
    // 11. eighthTwoSixteenth
    SubdivisionPattern(
        name: "half_eighth_two_sixteenth",
        displayName: "四分-两八分",
        type: .eighthTwoSixteenth,
        notes: [
            SubdivisionNote(length: 0.5, isMuted: false, noteValue: 4),
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8)
        ],
        beatUnit: 2,
        order: 10
    ),
    
    // 12. twoSixteenthEighth
    SubdivisionPattern(
        name: "half_two_sixteenth_eighth",
        displayName: "两八分-四分",
        type: .twoSixteenthEighth,
        notes: [
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
            SubdivisionNote(length: 0.5, isMuted: false, noteValue: 4)
        ],
        beatUnit: 2,
        order: 11
    ),
    
    // 13. eighthDottedSixteenth
    SubdivisionPattern(
        name: "half_eighth_dotted_sixteenth",
        displayName: "四分-附点四分",
        type: .eighthDottedSixteenth,
        notes: [
            SubdivisionNote(length: 0.75, isMuted: false, noteValue: 4),
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 4),
        ],
        beatUnit: 2,
        order: 12
    ),
    
    // 14. eighthSixteenthEighth
    SubdivisionPattern(
        name: "half_sixteenth_eighth_sixteenth",
        displayName: "四分-四分-四分",
        type: .sixteenthEighthSixteenth,
        notes: [
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 4),
            SubdivisionNote(length: 0.5, isMuted: false, noteValue: 4),
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 4)
        ],
        beatUnit: 2,
        order: 13
    ),
    
    // 15. sixteenthEighthDotted
    SubdivisionPattern(
        name: "half_sixteenth_eighth_dotted",
        displayName: "附点四分-四分",
        type: .sixteenthEighthDotted,
        notes: [
            SubdivisionNote(length: 0.25, isMuted: false, noteValue: 4),
            SubdivisionNote(length: 0.75, isMuted: false, noteValue: 4),
        ],
        beatUnit: 2,
        order: 14
    )
]
    
    // 获取所有支持的拍号单位列表
    static func getSupportedBeatUnits() -> [Int] {
        return Array(globalSubdivisionPatterns.keys).sorted()
    }

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
        
        // 3. 16分音符加16分休止符
        SubdivisionPattern(
            name: "eighth_resteighth",
            displayName: "十六分-休止",
            type: .resteighth,
            notes: [
                SubdivisionNote(length: 0.5, isMuted: true, noteValue: 16),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 16)
            ],
            beatUnit: 8,
            order: 2
        ),
        
        // 4. 三连音 (3个16分音符三连音)
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
            order: 3
        ),
        
        // 5. 三连音-开头休止符
        SubdivisionPattern(
            name: "eighth_triplet_rest_begin",
            displayName: "三连音-首休",
            type: .tripletRestBegin,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: true, noteValue: 16),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.34, isMuted: false, noteValue: 16)
            ],
            beatUnit: 8,
            order: 4
        ),
        
        // 6. 三连音-中间休止符
        SubdivisionPattern(
            name: "eighth_triplet_rest_middle",
            displayName: "三连音-中休",
            type: .tripletRestMiddle,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.33, isMuted: true, noteValue: 16),
                SubdivisionNote(length: 0.34, isMuted: false, noteValue: 16)
            ],
            beatUnit: 8,
            order: 5
        ),
        
        // 7. 三连音-末尾休止符
        SubdivisionPattern(
            name: "eighth_triplet_rest_end",
            displayName: "三连音-尾休",
            type: .tripletRestEnd,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.34, isMuted: true, noteValue: 16)
            ],
            beatUnit: 8,
            order: 6
        ),
        
        // 8. 三连音-两端休止符
        SubdivisionPattern(
            name: "eighth_triplet_rest_surround",
            displayName: "三连音-双休",
            type: .tripletRestSurround,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: true, noteValue: 16),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.34, isMuted: true, noteValue: 16)
            ],
            beatUnit: 8,
            order: 7
        ),
        
        // 9. 四等分 (4个32分音符)
        SubdivisionPattern(
            name: "eighth_quadruplet",
            displayName: "四等分",
            type: .quadruplet,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 32),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 32),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 32),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 32)
            ],
            beatUnit: 8,
            order: 8
        ),
        
        // 10. 双休止符十六分音符
        SubdivisionPattern(
            name: "eighth_double_rest_sixteenth",
            displayName: "双休-十六分",
            type: .doubleRestSixteenth,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: true, noteValue: 32),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 32),
                SubdivisionNote(length: 0.25, isMuted: true, noteValue: 32),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 32),
                
            ],
            beatUnit: 8,
            order: 9
        ),
        
        // 11. 16分音符加两个32分音符
        SubdivisionPattern(
            name: "eighth_eighth_two_sixteenth",
            displayName: "十六分-两三十二分",
            type: .eighthTwoSixteenth,
            notes: [
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 32),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 32)
            ],
            beatUnit: 8,
            order: 10
        ),
        
        // 12. 两个32分音符加16分音符
        SubdivisionPattern(
            name: "eighth_two_sixteenth_eighth",
            displayName: "两三十二分-十六分",
            type: .twoSixteenthEighth,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 32),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 32),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 16)
            ],
            beatUnit: 8,
            order: 11
        ),
        
        // 13. 16分音符加附点16分音符
        SubdivisionPattern(
            name: "eighth_eighth_dotted_sixteenth",
            displayName: "十六分-附点十六分",
            type: .eighthDottedSixteenth,
            notes: [
                SubdivisionNote(length: 0.75, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
            ],
            beatUnit: 8,
            order: 12
        ),
        
        // 14. 16分音符加16分音符加16分音符
        SubdivisionPattern(
            name: "eighth_sixteenth_eighth_sixteenth",
            displayName: "十六分-十六分-十六分",
            type: .sixteenthEighthSixteenth,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16)
            ],
            beatUnit: 8,
            order: 13
        ),
        
        // 15. 附点16分音符加16分音符
        SubdivisionPattern(
            name: "eighth_sixteenth_eighth_dotted",
            displayName: "附点十六分-十六分",
            type: .sixteenthEighthDotted,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.75, isMuted: false, noteValue: 16),
            ],
            beatUnit: 8,
            order: 14
        )
    ]

    private static let fullNotePatterns: [SubdivisionPattern] = [
        // 1. 基本4分音符 (不切分) - Frame 12
        SubdivisionPattern(
            name: "full_whole",
            displayName: "整拍",
            type: .whole,
            notes: [
                SubdivisionNote(length: 1.0, isMuted: false, noteValue: 4)
            ],
            beatUnit: 4,
            order: 0
        ),
        
        // 2. 二等分 (2个8分音符) - Frame 3
        SubdivisionPattern(
            name: "full_duple",
            displayName: "二等分",
            type: .duple,
            notes: [
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 1
        ),
        
        // 3. 8分音符加8分休止符 - Frame 22
        SubdivisionPattern(
            name: "full_resteighth",
            displayName: "八分-休止",
            type: .resteighth,
            notes: [
                SubdivisionNote(length: 0.5, isMuted: true, noteValue: 8),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8),
            ],
            beatUnit: 4,
            order: 2
        ),
        
        // 4. 三连音 (3个8分音符三连音) - Frame 36
        SubdivisionPattern(
            name: "full_triplet",
            displayName: "三连音",
            type: .triplet,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.34, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 3
        ),
        
        // 5. 三连音-开头休止符 - Frame 15
        SubdivisionPattern(
            name: "full_triplet_rest_begin",
            displayName: "三连音-首休",
            type: .tripletRestBegin,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: true, noteValue: 8),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.34, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 4
        ),
        
        // 6. 三连音-中间休止符 - Frame 16
        SubdivisionPattern(
            name: "full_triplet_rest_middle",
            displayName: "三连音-中休",
            type: .tripletRestMiddle,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.33, isMuted: true, noteValue: 8),
                SubdivisionNote(length: 0.34, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 5
        ),
        
        // 7. 三连音-末尾休止符 - Frame 17
        SubdivisionPattern(
            name: "full_triplet_rest_end",
            displayName: "三连音-尾休",
            type: .tripletRestEnd,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.34, isMuted: true, noteValue: 8)
            ],
            beatUnit: 4,
            order: 6
        ),
        
        // 8. 三连音-两端休止符 - Frame 23
        SubdivisionPattern(
            name: "full_triplet_rest_surround",
            displayName: "三连音-双休",
            type: .tripletRestSurround,
            notes: [
                SubdivisionNote(length: 0.33, isMuted: true, noteValue: 8),
                SubdivisionNote(length: 0.33, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.34, isMuted: true, noteValue: 8)
            ],
            beatUnit: 4,
            order: 7
        ),
        
        // 9. 四等分 (4个16分音符) - Frame 4
        SubdivisionPattern(
            name: "full_quadruplet",
            displayName: "四等分",
            type: .quadruplet,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16)
            ],
            beatUnit: 4,
            order: 8
        ),
        
        // 10. 双休止符十六分音符 - Frame 24
        SubdivisionPattern(
            name: "full_double_rest_sixteenth",
            displayName: "双休-十六分",
            type: .doubleRestSixteenth,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: true, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: true, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
            ],
            beatUnit: 4,
            order: 9
        ),
        
        // 11. 八分音符加两个十六分音符 - Frame 18
        SubdivisionPattern(
            name: "full_eighth_two_sixteenth",
            displayName: "八分-两十六分",
            type: .eighthTwoSixteenth,
            notes: [
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16)
            ],
            beatUnit: 4,
            order: 10
        ),
        
        // 12. 两个十六分音符加八分音符 - Frame 19
        SubdivisionPattern(
            name: "full_two_sixteenth_eighth",
            displayName: "两十六分-八分",
            type: .twoSixteenthEighth,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 16),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 11
        ),
        
        // 13. 八分音符加附点八分音符 - Frame 20
        SubdivisionPattern(
            name: "full_eighth_dotted_sixteenth",
            displayName: "八分-附点-十六分",
            type: .eighthDottedSixteenth,
            notes: [
                SubdivisionNote(length: 0.75, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
            ],
            beatUnit: 4,
            order: 12
        ),
        
        // 14. 八分音符加八分音符加八分音符 - Frame 21
        SubdivisionPattern(
            name: "full_sixteenth_eighth_sixteenth",
            displayName: "十六分-八分-十六分",
            type: .sixteenthEighthSixteenth,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.5, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8)
            ],
            beatUnit: 4,
            order: 13
        ),
        
        // 15. 附点八分音符加八分音符 - Frame 13
        SubdivisionPattern(
            name: "full_sixteenth_eighth_dotted",
            displayName: "附点八分-八分",
            type: .sixteenthEighthDotted,
            notes: [
                SubdivisionNote(length: 0.25, isMuted: false, noteValue: 8),
                SubdivisionNote(length: 0.75, isMuted: false, noteValue: 8),
            ],
            beatUnit: 4,
            order: 14
        )
    ]
}
