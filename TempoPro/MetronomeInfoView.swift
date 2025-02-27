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

// 更新 BeatView 组件
struct BeatView: View {
    @State var status: BeatStatus
    var onStatusChanged: (BeatStatus) -> Void
    var isCurrentBeat: Bool
    var isPlaying: Bool  // 添加 isPlaying 参数
    
    // 添加滑动状态
    @State private var dragAmount = CGSize.zero
    @State private var isDragging = false
    
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
        .contentShape(Rectangle()) // 确保整个区域可点击
        .onTapGesture {
            status = status.next()
            onStatusChanged(status)
        }
        // 创建更高优先级的垂直滑动手势
        .highPriorityGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { gesture in
                    // 只响应明确是垂直方向的滑动
                    if abs(gesture.translation.height) > abs(gesture.translation.width) * 1.3 {
                        print("BeatView - 检测到垂直滑动: \(gesture.translation)")
                        dragAmount = gesture.translation
                        isDragging = true
                    }
                }
                .onEnded { gesture in
                    // 只处理明确是垂直方向的滑动
                    if abs(gesture.translation.height) > abs(gesture.translation.width) * 1.3 {
                        print("BeatView - 结束垂直滑动: \(gesture.translation)")
                        // 判断是向上滑还是向下滑
                        if abs(gesture.translation.height) > 20 { // 设置一个最小阈值
                            if gesture.translation.height > 0 {
                                // 向下滑 - 强度减弱
                                print("BeatView - 向下滑动，强度减弱")
                                status = status.previous()
                            } else {
                                // 向上滑 - 强度增强
                                print("BeatView - 向上滑动，强度增强")
                                status = status.next()
                            }
                            onStatusChanged(status)
                        }
                    }
                    
                    // 重置状态
                    dragAmount = .zero
                    isDragging = false
                }
        )
        .animation(.spring(response: 0.3), value: isDragging)
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
            Color.white
            
            VStack(spacing: 20) {
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
            .padding(.horizontal, 10)
            .padding(.top, 10)
        }
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
        .ignoresSafeArea(.all, edges: [.horizontal, .bottom])
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
        // 首先创建基本的节拍视图
        let beatView = HStack(spacing: 4) {
            // 确保 beatStatuses 数组长度正确
            let safeStatuses = ensureBeatStatusesLength(beatStatuses, count: beatsPerBar)
            ForEach(0..<beatsPerBar, id: \.self) { beat in
                BeatView(
                    status: safeStatuses[beat],
                    onStatusChanged: { newStatus in
                        var updatedStatuses = safeStatuses
                        updatedStatuses[beat] = newStatus
                        beatStatuses = updatedStatuses
                    },
                    isCurrentBeat: beat == currentBeat,
                    isPlaying: isPlaying
                )
            }
        }
        .frame(height: 100) // 设置合适的高度
        .contentShape(Rectangle()) // 确保整个区域可以接收手势
        .onAppear {
            print("节拍显示区域已加载，区域内拍数: \(beatsPerBar)")
        }
        .id(beatsPerBar) // 添加ID确保拍数变化时视图能重新加载
        
        // 创建水平滑动手势识别器
        let horizontalDragGesture = DragGesture(minimumDistance: 10)
            .onChanged { gesture in
                print("横向滑动检测 - onChanged: 位移 = \(gesture.translation)")
                
                // 只有当明确是水平方向的滑动时才处理
                if abs(gesture.translation.width) > abs(gesture.translation.height) * 1.3 {
                    horizontalDragAmount = gesture.translation
                    isHorizontalDragging = true
                    print("横向滑动检测 - 处理中")
                }
            }
            .onEnded { gesture in
                // 只有当明确是水平方向的滑动时才处理
                if abs(gesture.translation.width) > abs(gesture.translation.height) * 1.3 {
                    print("横向滑动检测 - 结束，水平位移 = \(gesture.translation.width)")
                    
                    if abs(gesture.translation.width) > 30 {
                        if gesture.translation.width < 0 {
                            // 向左滑 - 减少拍数
                            if beatsPerBarBinding > 1 {
                                print("横向滑动执行 - 拍数减1")
                                beatsPerBarBinding -= 1
                            }
                        } else {
                            // 向右滑 - 增加拍数
                            if beatsPerBarBinding < 12 {
                                print("横向滑动执行 - 拍数加1")
                                beatsPerBarBinding += 1
                            }
                        }
                    }
                }
                
                // 无论如何，都重置状态
                horizontalDragAmount = .zero
                isHorizontalDragging = false
            }
        
        // 将手势应用到视图上，并添加动画效果
        return beatView
            .gesture(horizontalDragGesture)
            .animation(.spring(response: 0.3), value: isHorizontalDragging)
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
