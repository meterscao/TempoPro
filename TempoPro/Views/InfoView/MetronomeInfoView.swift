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
    func next(shouldLoop: Bool = false) -> BeatStatus {
        switch self {
        case .muted:
            return .normal
        case .normal:
            return .medium
        case .medium:
            return .strong
        case .strong:
            return shouldLoop ? .muted : .strong
        }
    }
    
    // 添加向前循环切换方法（用于下滑）
    func previous(shouldLoop: Bool = false) -> BeatStatus {
        switch self {
        case .muted:
            return shouldLoop ? .strong : .muted
        case .normal:
            return .muted
        case .medium:
            return .normal
        case .strong:
            return .medium
        }
    }
}
struct ClockView: View {
    @State private var currentTime = Date()
    @Environment(\.metronomeTheme) var theme
    
    // 每秒更新一次的定时器
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // 将 formatter 移到 body 外部或者使用计算属性
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }
    
    var body: some View {
        Text(timeString)
            .font(.custom("MiSansLatin-Semibold", size: 17))
            .foregroundColor(theme.primaryColor)
            // 每秒接收定时器事件,更新时间
            .onReceive(timer) { _ in
                self.currentTime = Date() // 更新为当前时间
            }
            // 视图出现时初始化当前时间
            .onAppear {
                self.currentTime = Date()
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
        let baseColor = isPlaying && isCurrentBeat ?   theme.beatBarHighlightColor : theme.beatBarColor 
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
    // 选择节拍的变量
    @State private var showingTimeSignature = false
    @State private var showingKeypad = false
    @State private var showSetting = false
    
    // 添加滑动状态变量
    @State private var horizontalDragAmount = CGSize.zero
    @State private var isHorizontalDragging = false
    @State private var initialBeatIndex: Int? = nil // 添加初始BeatView索引跟踪
    
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var metronomeState: MetronomeState

    @EnvironmentObject var metronomeViewModel: MyViewModel
    
    @State private var showingThemeSettings = false
    
    // 添加速度术语判断函数
    private func getTempoTerm(_ bpm: Int) -> String {
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

                HStack {
                    ClockView()
                    Spacer()
                    VStack() {
                        Image("icon-menu")
                            .renderingMode(.template)
                            .foregroundColor(theme.primaryColor)
                    }
                    .frame(maxHeight:.infinity)
                    .padding(10)
                    .onTapGesture {
                        showSetting = true
                    }
                }
//                .padding(.top,10)
                .frame(height: 50)
                .padding(.horizontal,20)
//                .background(.blue)
                
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
                                Text("\(metronomeViewModel.beatsPerBar)")
                                Text("/")
                                Text("\(metronomeViewModel.beatUnit)")
                                    
                            }
                            .font(.custom("MiSansLatin-Semibold", size: 22))
                            .onTapGesture {
                                showingTimeSignature = true
                            }
                            Spacer()
                            HStack(spacing: 2) {
                                Image(metronomeViewModel.subdivisionPattern.name)
                                    .renderingMode(.template)
                                    .foregroundStyle(theme.primaryColor)
                                    .frame(width: 44, height: 44)
                                    
                            }
                            .onTapGesture {
                                showingTimeSignature = true
                            }
                        }
                        
                        // BPM 显示
                        Text("\(Int(metronomeViewModel.tempo))")
                            .font(.custom("MiSansLatin-Semibold", size: 52))
                            .onTapGesture {
                                showingKeypad = true
                            }
                            .frame(height:60)
                    }
                    Text(getTempoTerm(metronomeViewModel.tempo))
                        .font(.custom("MiSansLatin-Regular", size: 12))
                        .fontWeight(.light)
                        .foregroundColor(theme.primaryColor)
                        .padding(.top,-5)
                        .onTapGesture {
                            showingKeypad = true
                        }
                }
                .foregroundStyle(theme.primaryColor)
                .padding(.vertical,15)
                // 新增加的 BPMRulerView
                BPMRulerView()
            }
            .padding(.horizontal,15)
            .padding(.bottom,15)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, theme.backgroundColor]),
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
            )
            .clipShape(
                .rect(
                    topLeadingRadius: max(15, DisplayCornerRadiusHelper.shared.getCornerRadius() - 7),
                    bottomLeadingRadius: 15,
                    bottomTrailingRadius: 15,
                    topTrailingRadius: max(15, DisplayCornerRadiusHelper.shared.getCornerRadius() - 7)
                )
            )
            
        }
        
        .padding(.top,8)
        .padding(.horizontal,8)
        .frame(maxHeight: .infinity)
        .ignoresSafeArea() // 忽略所有安全区域
        
        .sheet(isPresented: $showingTimeSignature) {
            TimeSignatureView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .compatibleCornerRadius(15)
        }
        
        
        .sheet(isPresented: $showingKeypad) {
            BPMKeypadView()
            .ignoresSafeArea()
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
            .compatibleCornerRadius(15)
            
        }
        
        .sheet(isPresented: $showSetting) {
            SettingsView()
                .compatibleCornerRadius(15)
        }
    }
    
    // 将节拍视图和手势提取为计算属性，使代码更清晰
    private var beatsViewWithGestures: some View {
        // 确保 beatStatuses 数组长度正确
        let safeStatuses = ensureBeatStatusesLength(metronomeViewModel.beatStatuses, count: metronomeViewModel.beatsPerBar)
        print("MetronomeInfoView - beatsViewWithGestures - 当前 beatsPerBar: \(metronomeViewModel.beatsPerBar)")
        
        return GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<metronomeViewModel.beatsPerBar, id: \.self) { beat in
                    BeatView(
                        status: safeStatuses[beat],
                        isCurrentBeat: beat == metronomeState.currentBeat,
                        isPlaying: metronomeState.isPlaying
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle()) // 确保形状完整，便于计算位置
                    .cornerRadius(10)
                    .id(beat) // 为每个BeatView添加ID
                    .onTapGesture {
                        // 保留点击切换功能
                        var updatedStatuses = safeStatuses
                        updatedStatuses[beat] = updatedStatuses[beat].next(shouldLoop: true)
                        metronomeViewModel.updateBeatStatuses(updatedStatuses)
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
                                let beatIndex = min(metronomeViewModel.beatsPerBar - 1, max(0, Int(location.x / (totalWidth / CGFloat(metronomeViewModel.beatsPerBar)))))
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
                                    if metronomeViewModel.beatsPerBar > 1 {
                                        print("横向滑动 - 拍数修改前: \(metronomeViewModel.beatsPerBar)")
                                        // 直接修改AppStorage变量，自动保存到UserDefaults
                                        let tempBeatsPerBar = metronomeViewModel.beatsPerBar
                                        metronomeViewModel.updateBeatsPerBar(tempBeatsPerBar - 1)
                                        print("横向滑动 - 拍数修改后: \(metronomeViewModel.beatsPerBar)")
                                    }
                                } else {
                                    // 向右滑 - 增加拍数
                                    if metronomeViewModel.beatsPerBar < 12 {
                                        print("横向滑动执行 - 拍数加1: \(metronomeViewModel.beatsPerBar) -> \(metronomeViewModel.beatsPerBar + 1)")
                                        // 直接修改AppStorage变量，自动保存到UserDefaults
                                        let tempBeatsPerBar = metronomeViewModel.beatsPerBar
                                        metronomeViewModel.updateBeatsPerBar(tempBeatsPerBar + 1)
                                        print("横向滑动 - 拍数修改后: \(metronomeViewModel.beatsPerBar)")
                                    }
                                }
                            }
                            
                            // 重置状态
                            horizontalDragAmount = .zero
                            isHorizontalDragging = false
                            
                            // 添加延迟验证AppStorage的值
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                print("横向滑动保存后 - AppStorage 中的值: \(metronomeViewModel.beatsPerBar)")
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
                                metronomeViewModel.updateBeatStatuses(updatedStatuses)
                            }
                            
                            // 重置初始索引
                            initialBeatIndex = nil
                        }
                    }
            )
            .animation(.easeInOut(duration: 0.2), value: isHorizontalDragging)
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
            metronomeViewModel.updateBeatStatuses(newStatuses)
//            beatStatuses = newStatuses
        }
        
        return newStatuses
    }
}

#Preview {
    MetronomeInfoView()
    .environmentObject(ThemeManager()) // 添加 ThemeManager 环境对象
    .environmentObject(MetronomeState())
}
