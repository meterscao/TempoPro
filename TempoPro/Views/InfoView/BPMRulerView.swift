//
//  BPMRulerView.swift
//  TempoPro
//
//  Created by Meters on 28/2/2025.
//

import SwiftUI
import UIKit

struct BPMRulerView: View {
    
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var metronomeState: MetronomeState
    @EnvironmentObject var metronomeViewModel: MyViewModel
    
    // 添加中间状态以确保更新正确
    @State private var internalTempo: Int = 120
    
    
    // BPM 范围
    private let minBPM: Int = 30
    private let maxBPM: Int = 240

    private let rulerHeight: CGFloat = 50
    private let textHeight: CGFloat = 16
    private let textMargin: CGFloat = 4
    
    // 视图参数

    private let majorTickWidth: CGFloat = 2
    private var majorTickHeight: CGFloat { rulerHeight - textHeight - (textMargin * 2) }

    private let pointerWidth: CGFloat = 2
    private var pointerHeight: CGFloat { majorTickHeight }
    
    private let tickWidth: CGFloat = 1
    private let tickHeight: CGFloat = 15
    
    
    
    private let tickSpacing: CGFloat = 8  // 刻度线之间的固定间距
    
    // 添加动画状态变量
    @State private var animatedTempo: Int = 120
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 使用固定位置布局而非 ScrollView 以提高性能和准确性
                
                // 创建整个刻度尺视图 - 只移动这一个视图而不是每个刻度
                RulerScaleView(minBPM: minBPM, maxBPM: maxBPM,
                              tickSpacing: tickSpacing,
                              tickHeight: tickHeight, majorTickHeight: majorTickHeight,
                              tickWidth: tickWidth, majorTickWidth: majorTickWidth,
                              textMargin: textMargin,
                              textHeight: textHeight,
                              rulerHeight: rulerHeight,
                              onSelectBPM: { bpm in
                                // 设置内部状态
                                print("🔄 选择了BPM: \(bpm)")
                                withAnimation {
                                    internalTempo = bpm
                                }
                                print("⏩ 内部tempo已设置为: \(internalTempo)")
                              })
                    .frame(maxHeight: .infinity)
                    .offset(x: calculateOffset(for: animatedTempo, in: geometry))
                
                // 中心红色指针 - 修改为底部对齐
                Rectangle()
                    .fill(Color.red)
                    .frame(width: pointerWidth, height: pointerHeight)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - pointerHeight / 2)
                
                // 渐变遮罩
                HStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [theme.backgroundColor, theme.backgroundColor.opacity(0)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 10)
                    
                    Spacer()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [theme.backgroundColor.opacity(0), theme.backgroundColor]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 10)
                }.hidden()
            }
        }
        .frame(height: rulerHeight)
        .clipped() // 裁剪超出边界的内容
        // 监听内部状态变化，同步到外部
        .onChange(of: internalTempo) { newTempo in
            print("🔄 内部tempo变化为: \(newTempo)，正在更新外部绑定")
            metronomeViewModel.updateTempo(newTempo)
            print("✅ 外部tempo已更新为: \(newTempo)")
        }
        // 监听外部绑定变化，同步到内部
        .onChange(of: metronomeViewModel.tempo) { newTempo in
            print("⭐️ 外部tempo变化: \(animatedTempo) -> \(newTempo)")
            // 同步内部状态
            internalTempo = newTempo
            
            // 完全优化的动画处理方式
            let tempoChange = abs(animatedTempo - newTempo)
            
            if tempoChange > 20 {
                // 大幅度变化直接跳转，不使用动画
                print("大幅度变化，直接跳转")
                animatedTempo = newTempo
            } else if tempoChange > 5 {
                // 中等幅度变化使用简单动画
                print("中等幅度变化，使用简单动画")
                withAnimation(.easeOut(duration: 0.2)) {
                    animatedTempo = newTempo
                }
            } else {
                // 小幅度变化使用更精细的弹簧动画
                print("小幅度变化，使用弹簧动画")
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)) {
                    animatedTempo = newTempo
                }
            }
        }
        .onAppear {
            // 初始化内部状态和动画状态
            print("BPMRulerView已加载，初始tempo: \(metronomeViewModel.tempo)")
            internalTempo = metronomeViewModel.tempo
            animatedTempo = metronomeViewModel.tempo
        }
    }
    
    // 计算整个刻度尺的偏移量
    private func calculateOffset(for tempo: Int, in geometry: GeometryProxy) -> CGFloat {
        let visibleCenter = geometry.size.width / 2
        let tempoOffset = CGFloat(Double(tempo) - Double(minBPM)) * tickSpacing
        return visibleCenter - tempoOffset
    }
}

// 单独的刻度尺视图组件 - 改进版本确保均匀刻度
struct RulerScaleView: View {
    let minBPM: Int
    let maxBPM: Int
    let tickSpacing: CGFloat
    let tickHeight: CGFloat
    let majorTickHeight: CGFloat
    let tickWidth: CGFloat
    let majorTickWidth: CGFloat
    let textMargin: CGFloat
    let textHeight: CGFloat
    let rulerHeight: CGFloat

    @Environment(\.metronomeTheme) var theme
    
    // 使用回调处理BPM选择
    var onSelectBPM: (Int) -> Void
    
    var body: some View {
        // 使用ZStack和精确定位替代HStack以确保均匀刻度
        ZStack(alignment: .bottom) {
            // 明确指定ForEach的泛型参数类型
            ForEach(Array(minBPM...maxBPM), id: \.self) { bpm in
                ZStack(alignment: .bottom) {
                    // 在确切位置放置每个刻度
                    VStack(spacing: textMargin) {
                        // 刻度数字 (仅显示10的倍数)
                        if bpm % 10 == 0 {
                            Text("\(bpm)")
                                .font(.custom("MiSansLatin-Semibold", size: 12))
                                .frame(height:textHeight)
                                .foregroundColor(theme.primaryColor)
                        }
                       
                        // 刻度线
                        Rectangle()
                            .fill(bpm % 10 == 0 ? theme.primaryColor : theme.primaryColor.opacity(0.4))
                            .frame(width: bpm % 10 == 0 ? majorTickWidth : tickWidth,
                                   height: bpm % 10 == 0 ? majorTickHeight : tickHeight)
                    }
                    .padding(.top,textMargin)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    
                    // 为10的倍数BPM添加可点击区域
                    if bpm % 10 == 0 {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 30, height: 50)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                print("BPM值\(bpm)被点击")
                                
                                // 提供触觉反馈
                                let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                                feedbackGenerator.prepare()
                                feedbackGenerator.impactOccurred()
                                
                                // 使用主线程确保UI更新
                                DispatchQueue.main.async {
                                    // 只使用回调更新
                                    onSelectBPM(bpm)
                                }
                            }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .position(x: CGFloat(bpm - minBPM) * tickSpacing, y: rulerHeight / 2)
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .onAppear {
            print("RulerScaleView已加载，BPM范围:\(minBPM)-\(maxBPM)")
        }
    }
}

#Preview {
    BPMRulerView()
        .frame(height: 60)
        .background(Color.black)
}
