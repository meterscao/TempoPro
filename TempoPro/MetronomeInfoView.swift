//
//  MetronomeInfoView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

// 添加节拍状态枚举
enum BeatStatus {
    case strong    // 最强
    case medium    // 次强
    case normal    // 普通
    case muted     // 静音
}

// 为 BeatStatus 添加循环切换方法
extension BeatStatus {
    func next() -> BeatStatus {
        switch self {
        case .muted:
            return .normal
        case .normal:
            return .medium
        case .medium:
            return .strong
        case .strong:
            return .muted
        }
    }
    
    // 添加向前循环切换方法（用于下滑）
    func previous() -> BeatStatus {
        switch self {
        case .muted:
            return .strong
        case .normal:
            return .muted
        case .medium:
            return .normal
        case .strong:
            return .medium
        }
    }
}

// 简化 BeatView，移除手势处理
struct BeatView: View {
    var status: BeatStatus  // 不再需要 @State，由父视图控制
    var isCurrentBeat: Bool
    var isPlaying: Bool
    
    private func barColors() -> [Color] {
        let colors: [Color] = switch status {
        case .strong:
            [Color.blue, Color.blue, Color.blue]
        case .medium:
            [Color.gray.opacity(0.2), Color.blue, Color.blue]
        case .normal:
            [Color.gray.opacity(0.2), Color.gray.opacity(0.2), Color.blue]
        case .muted:
            [Color.gray.opacity(0.2), Color.gray.opacity(0.2), Color.gray.opacity(0.2)]
        }
        
        // 只在播放状态下显示红色高亮
        return (isPlaying && isCurrentBeat) ? [Color.red, Color.red, Color.red] : colors
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(barColors()[index])
                    .frame(maxHeight: .infinity)
                    .cornerRadius(2)
            }
        }
        // 移除所有手势相关代码，由父视图统一处理
    }
}

struct MetronomeInfoView: View {
    let tempo: Double
    let beatsPerBar: Int
    let beatUnit: Int
    @Binding var showingKeypad: Bool
    @Binding var beatStatuses: [BeatStatus]
    let currentBeat: Int
    let isPlaying: Bool
    @State private var showingTimeSignature = false
    @Binding var beatsPerBarBinding: Int
    @Binding var beatUnitBinding: Int
    
    // 添加滑动状态变量
    @State private var horizontalDragAmount = CGSize.zero
    @State private var isHorizontalDragging = false
    @State private var initialBeatIndex: Int? = nil // 添加初始BeatView索引跟踪
    
    // 添加速度术语判断函数
    private func getTempoTerm(_ bpm: Double) -> String {
        switch bpm {
        case 0..<40:
            return "Grave"
        case 40..<45:
            return "Larghissimo"
        case 45..<50:
            return "Largo"
        case 50..<55:
            return "Lento"
        case 55..<65:
            return "Adagio"
        case 65..<75:
            return "Adagietto"
        case 75..<85:
            return "Andantino"
        case 85..<95:
            return "Andante"
        case 95..<108:
            return "Andante Moderato"
        case 108..<120:
            return "Moderato"
        case 120..<140:
            return "Allegretto"
        case 140..<160:
            return "Allegro"
        case 160..<176:
            return "Vivace"
        case 176..<200:
            return "Presto"
        case 200...:
            return "Prestissimo"
        default:
            return "Moderato"
        }
    }
    
    var body: some View {
        ZStack {
            
            
            VStack(spacing: 0) {
                HStack{}
                    .frame(maxWidth:.infinity)
                    .frame(height:0)
                    .background(.white)
                // 顶部工具栏
                HStack {
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                    }
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "timer")
                    }
                }
                
                // 节拍显示区域和滑动控制区域
                VStack(spacing: 8) {
                    // 节拍显示区域 - 使用水平手势识别器包装
                    beatsViewWithGestures
                    
                    // 移除单独的滑动控制区域
                }
                .padding(.horizontal)
                
                // 速度和拍号显示
                HStack(spacing: 30) {
                    // 拍号显示 - 添加点击手势
                    HStack(spacing: 2) {
                        Text("\(beatsPerBar)")
                            .font(.system(size: 24, weight: .medium))
                        Text("/")
                            .font(.system(size: 24, weight: .medium))
                        Text("\(beatUnit)")
                            .font(.system(size: 24, weight: .medium))
                    }
                    .onTapGesture {
                        showingTimeSignature = true
                    }
                    
                    Spacer()
                    
                    // BPM 显示
                    VStack {
                        Text("\(Int(tempo))")
                            .font(.system(size: 42, weight: .medium))
                            .onTapGesture {
                                showingKeypad = true
                            }
                        Text(getTempoTerm(tempo))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    Text("切分")
                }
                .foregroundStyle(.white)
            }
            
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.black)
            .cornerRadius(50)
            .padding(10)
            
            
//                VStack(){
//                    HStack{}
//                        .frame(maxWidth:.infinity)
//                        .frame(height:0)
//                        .background(.white)
//                
//                        
//                }
//                
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//                .background(.black)
//                .cornerRadius(50)
//                .padding(10)
            
        }
        
        
        .ignoresSafeArea() // 忽略所有安全区域
        .sheet(isPresented: $showingTimeSignature) {
            TimeSignatureView(
                beatsPerBar: $beatsPerBarBinding,
                beatUnit: $beatUnitBinding
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // 将节拍视图和手势提取为计算属性，使代码更清晰
    private var beatsViewWithGestures: some View {
        // 确保 beatStatuses 数组长度正确
        let safeStatuses = ensureBeatStatusesLength(beatStatuses, count: beatsPerBar)
        
        return GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<beatsPerBar, id: \.self) { beat in
                    BeatView(
                        status: safeStatuses[beat],
                        isCurrentBeat: beat == currentBeat,
                        isPlaying: isPlaying
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle()) // 确保形状完整，便于计算位置
                    .id(beat) // 为每个BeatView添加ID
                    .onTapGesture {
                        // 保留点击切换功能
                        var updatedStatuses = safeStatuses
                        updatedStatuses[beat] = updatedStatuses[beat].next()
                        beatStatuses = updatedStatuses
                        print("点击切换BeatView \(beat) 状态为: \(updatedStatuses[beat])")
                    }
                }
            }
//            .frame(height: 100) // 设置合适的高度
            .contentShape(Rectangle()) // 确保整个区域可以接收手势
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { gesture in
                        // 记录手势位置和方向
                        let location = gesture.location
                        let translation = gesture.translation
                        print("手势检测 - 位置: \(location), 位移: \(translation)")
                        
                        // 判断手势方向
                        let isHorizontal = abs(translation.width) > abs(translation.height) * 1.3
                        
                        if isHorizontal {
                            // 处理横向滑动
                            horizontalDragAmount = translation
                            isHorizontalDragging = true
                            print("检测到横向滑动")
                            initialBeatIndex = nil // 重置初始索引，因为这是横向滑动
                        } else {
                            // 垂直滑动 - 识别是哪个BeatView
                            // 如果是第一次移动，记录初始BeatView索引
                            if initialBeatIndex == nil {
                                let totalWidth = geometry.size.width
                                let beatIndex = min(beatsPerBar - 1, max(0, Int(location.x / (totalWidth / CGFloat(beatsPerBar)))))
                                initialBeatIndex = beatIndex
                                print("垂直滑动起始BeatView索引: \(beatIndex), x坐标: \(location.x), 总宽度: \(totalWidth)")
                            }
                        }
                    }
                    .onEnded { gesture in
                        let translation = gesture.translation
                        print("手势结束 - 最终位移: \(translation)")
                        
                        // 判断手势方向
                        let isHorizontal = abs(translation.width) > abs(translation.height) * 1.3
                        
                        if isHorizontal {
                            // 横向滑动结束 - 调整拍数
                            if abs(translation.width) > 30 {
                                if translation.width < 0 {
                                    // 向左滑 - 减少拍数
                                    if beatsPerBarBinding > 1 {
                                        print("横向滑动执行 - 拍数减1: \(beatsPerBarBinding) -> \(beatsPerBarBinding - 1)")
                                        beatsPerBarBinding -= 1
                                    }
                                } else {
                                    // 向右滑 - 增加拍数
                                    if beatsPerBarBinding < 12 {
                                        print("横向滑动执行 - 拍数加1: \(beatsPerBarBinding) -> \(beatsPerBarBinding + 1)")
                                        beatsPerBarBinding += 1
                                    }
                                }
                            }
                            
                            // 重置状态
                            horizontalDragAmount = .zero
                            isHorizontalDragging = false
                        } else {
                            // 垂直滑动结束 - 调整特定BeatView的状态
                            if abs(translation.height) > 20 && initialBeatIndex != nil { // 最小阈值
                                // 使用记录的初始BeatView索引
                                let beatIndex = initialBeatIndex!
                                print("垂直滑动 - 作用于初始BeatView索引: \(beatIndex)")
                                
                                // 更新对应BeatView的状态
                                var updatedStatuses = safeStatuses
                                if translation.height > 0 {
                                    // 向下滑 - 强度减弱
                                    print("垂直滑动 - BeatView \(beatIndex) 向下滑动，强度减弱")
                                    updatedStatuses[beatIndex] = updatedStatuses[beatIndex].previous()
                                } else {
                                    // 向上滑 - 强度增强
                                    print("垂直滑动 - BeatView \(beatIndex) 向上滑动，强度增强")
                                    updatedStatuses[beatIndex] = updatedStatuses[beatIndex].next()
                                }
                                beatStatuses = updatedStatuses
                            }
                            
                            // 重置初始索引
                            initialBeatIndex = nil
                        }
                    }
            )
            .id(beatsPerBar) // 添加ID确保拍数变化时视图能重新加载
            .animation(.spring(response: 0.3), value: isHorizontalDragging)
        }
        .frame(maxHeight: .infinity) // 确保GeometryReader有固定高度
    }
    
    // 添加一个辅助函数来确保数组长度正确
    private func ensureBeatStatusesLength(_ statuses: [BeatStatus], count: Int) -> [BeatStatus] {
        if statuses.count == count {
            return statuses
        }
        
        var newStatuses = Array(repeating: BeatStatus.normal, count: count)
        // 复制现有的状态
        for i in 0..<min(statuses.count, count) {
            newStatuses[i] = statuses[i]
        }
        // 确保第一拍是强拍
        if newStatuses.count > 0 {
            newStatuses[0] = .strong
        }
        
        DispatchQueue.main.async {
            // 异步更新绑定的数组，避免在视图更新过程中修改状态
            beatStatuses = newStatuses
        }
        
        return newStatuses
    }
}

#Preview {
    MetronomeInfoView(tempo: 120, beatsPerBar: 4, beatUnit: 4, showingKeypad: .constant(false), beatStatuses: .constant([.strong, .normal, .normal, .normal]), currentBeat: 0, isPlaying: false, beatsPerBarBinding: .constant(4), beatUnitBinding: .constant(4))
}
