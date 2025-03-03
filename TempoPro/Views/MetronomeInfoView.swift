//
//  MetronomeInfoView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI
import UIKit

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
    var status: BeatStatus
    var isCurrentBeat: Bool
    var isPlaying: Bool
    @Environment(\.metronomeTheme) var theme
    
    private func barColors() -> [Color] {
        let baseColor = isPlaying && isCurrentBeat ?   .red : theme.beatHightColor 
        let accentBeatColor = baseColor
        let mutedBeatColor = baseColor.opacity(0.2)
        let colors: [Color] = switch status {
            
        case .strong:
            [accentBeatColor, accentBeatColor, accentBeatColor]
        case .medium:
            [mutedBeatColor, accentBeatColor, accentBeatColor]
        case .normal:
            [mutedBeatColor, mutedBeatColor, accentBeatColor]
        case .muted:
            [mutedBeatColor, mutedBeatColor, mutedBeatColor]
        }
        
        // 只在播放状态下显示高亮
        return colors
    }
    
    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Image("bg-noise")
                    .resizable(resizingMode: .tile)
                    .opacity(0.06)
                    .frame(maxHeight: .infinity)
                    .background(barColors()[index])
                    .cornerRadius(2)
                    
                    
            }
        }
        
        
        // 移除所有手势相关代码，由父视图统一处理
    }
}

struct MetronomeInfoView: View {
    @Binding var tempo: Double
    @Binding var showingKeypad: Bool
    @Binding var beatStatuses: [BeatStatus]
    
    // 直接使用AppStorage替代Binding
    @AppStorage(AppStorageKeys.Metronome.beatsPerBar) private var beatsPerBar: Int = 4
    @AppStorage(AppStorageKeys.Metronome.beatUnit) private var beatUnit: Int = 4
    
    let currentBeat: Int
    let isPlaying: Bool
    
    // 选择节拍的变量
    @State private var showingTimeSignature = false
    
    // 添加滑动状态变量
    @State private var horizontalDragAmount = CGSize.zero
    @State private var isHorizontalDragging = false
    @State private var initialBeatIndex: Int? = nil // 添加初始BeatView索引跟踪
    
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showingThemeSettings = false
    
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
            VStack(spacing: 10) {

                HStack {
                    Button(action: {
                        showingThemeSettings = true
                    }) {
                        Image("icon-setting")
                            .renderingMode(.template)
                            .foregroundColor(theme.primaryColor)
                    }
                    Spacer()
                    Button(action: {}) {
                        Image("icon-timer")
                            .renderingMode(.template) 
                            .foregroundColor(theme.primaryColor)
                    }
                }
                .padding(.top,10)
                .frame(height: 50)
                .padding(.horizontal,20)
                
                // 节拍显示区域和滑动控制区域
                VStack(spacing: 8) {
                    // 节拍显示区域 - 使用水平手势识别器包装
                    beatsViewWithGestures
                    
                    // 移除单独的滑动控制区域
                }
                
                VStack(spacing:0){
                    ZStack{
                        // 速度和拍号显示
                        HStack(spacing: 30) {
                            // 拍号显示 - 添加点击手势
                            HStack(spacing: 2) {
                                Text("\(beatsPerBar)")
                                Text("/")
                                Text("\(beatUnit)")
                                    
                            }
                            .font(.custom("MiSansLatin-Regular", size: 22))
                            .onTapGesture {
                                showingTimeSignature = true
                            }
                            Spacer()
                            Image("icon-time-signature")
                                .renderingMode(.template)
                                .foregroundStyle(theme.primaryColor)
                        }
                        
                        // BPM 显示
                        Text("\(Int(tempo))")
                            .font(.custom("MiSansLatin-Semibold", size: 46))
                            .onTapGesture {
                                showingKeypad = true
                            }
                            .frame(height:52)
                    }
                    Text(getTempoTerm(tempo))
                        .font(.custom("MiSansLatin-Regular", size: 12))
                        .fontWeight(.light)
                        .foregroundColor(theme.primaryColor)
                        .padding(.top,-5)
                        .onTapGesture {
                            showingKeypad = true
                        }
                }
                .foregroundStyle(theme.primaryColor)
                
                
                
                // 新增加的 BPMRulerView
                BPMRulerView(tempo: $tempo)
                
            }
            .padding(.horizontal,15)
            .padding(.bottom,15)
            .background(theme.backgroundColor)
            .foregroundColor(theme.textColor)
            .clipShape(
                .rect(
                    topLeadingRadius: max(15, DisplayCornerRadiusHelper.shared.getCornerRadius() - 7),
                    bottomLeadingRadius: 15,
                    bottomTrailingRadius: 15,
                    topTrailingRadius: max(15, DisplayCornerRadiusHelper.shared.getCornerRadius() - 7)
                )
            )
            
        }
        
        .padding(8)
        .frame(maxHeight: .infinity)
        .ignoresSafeArea() // 忽略所有安全区域
        
        .sheet(isPresented: $showingTimeSignature) {
            TimeSignatureView()
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
        }
        
        .sheet(isPresented: $showingThemeSettings) {
            ThemeSelectionView()
                .presentationDetents([.height(150)])
                .presentationDragIndicator(.visible)
        }
    }
    
    // 将节拍视图和手势提取为计算属性，使代码更清晰
    private var beatsViewWithGestures: some View {
        // 确保 beatStatuses 数组长度正确
        let safeStatuses = ensureBeatStatusesLength(beatStatuses, count: beatsPerBar)
        print("MetronomeInfoView - beatsViewWithGestures - 当前 beatsPerBar: \(beatsPerBar)")
        
        return GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<beatsPerBar, id: \.self) { beat in
                    BeatView(
                        status: safeStatuses[beat],
                        isCurrentBeat: beat == currentBeat,
                        isPlaying: isPlaying
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle()) // 确保形状完整，便于计算位置
                    .cornerRadius(10)
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
                                if translation.width > 0 {
                                    // 向左滑 - 减少拍数
                                    if beatsPerBar > 1 {
                                        print("横向滑动 - 拍数修改前: \(beatsPerBar)")
                                        // 直接修改AppStorage变量，自动保存到UserDefaults
                                        beatsPerBar -= 1
                                        print("横向滑动 - 拍数修改后: \(beatsPerBar)")
                                    }
                                } else {
                                    // 向右滑 - 增加拍数
                                    if beatsPerBar < 12 {
                                        print("横向滑动执行 - 拍数加1: \(beatsPerBar) -> \(beatsPerBar + 1)")
                                        // 直接修改AppStorage变量，自动保存到UserDefaults
                                        beatsPerBar += 1
                                        print("横向滑动 - 拍数修改后: \(beatsPerBar)")
                                    }
                                }
                            }
                            
                            // 重置状态
                            horizontalDragAmount = .zero
                            isHorizontalDragging = false
                            
                            // 添加延迟验证UserDefaults的值
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                let saved = UserDefaults.standard.integer(forKey: AppStorageKeys.Metronome.beatsPerBar)
                                print("横向滑动保存后 - UserDefaults 中的值: \(saved)")
                            }
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
    MetronomeInfoView(
        tempo: .constant(120),
        showingKeypad: .constant(false),
        beatStatuses: .constant([.strong, .normal, .normal, .normal]),
        currentBeat: 0,
        isPlaying: false
    )
    .environmentObject(ThemeManager()) // 添加 ThemeManager 环境对象
}
