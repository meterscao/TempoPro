//
//  BPMRulerView.swift
//  TempoPro
//
//  Created by Meters on 28/2/2025.
//

import SwiftUI

struct BPMRulerView: View {
    @Binding var tempo: Double
    
    // BPM 范围
    private let minBPM: Int = 30
    private let maxBPM: Int = 240
    
    // 视图参数
    private let tickWidth: CGFloat = 1
    private let tickHeight: CGFloat = 15
    
    private let majorTickWidth: CGFloat = 2
    private let majorTickHeight: CGFloat = 20
    private let pointerWidth: CGFloat = 2
    private let pointerHeight: CGFloat = 20
    private let tickSpacing: CGFloat = 8  // 刻度线之间的固定间距
    
    // 添加动画状态变量
    @State private var animatedTempo: Double = 120
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 使用固定位置布局而非 ScrollView 以提高性能和准确性
                
                // 创建整个刻度尺视图 - 只移动这一个视图而不是每个刻度
                RulerScaleView(minBPM: minBPM, maxBPM: maxBPM,
                              tickSpacing: tickSpacing,
                              tickHeight: tickHeight, majorTickHeight: majorTickHeight,
                              tickWidth: tickWidth, majorTickWidth: majorTickWidth)
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
                        gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                    
                    Spacer()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0), Color.black]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                }
            }
        }
        .frame(height: 60)
        
        .clipped() // 裁剪超出边界的内容
        .onChange(of: tempo) { newTempo in
            // 改进的动画方式
            if abs(animatedTempo - newTempo) > 20 {
                // 大幅度变化直接跳转，避免过长的动画
                animatedTempo = newTempo
            } else {
                // 小幅度变化使用动画
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
                    animatedTempo = newTempo
                }
            }
        }
        .onAppear {
            // 初始化 animatedTempo
            animatedTempo = tempo
        }
    }
    
    // 计算整个刻度尺的偏移量
    private func calculateOffset(for tempo: Double, in geometry: GeometryProxy) -> CGFloat {
        let visibleCenter = geometry.size.width / 2
        let tempoOffset = CGFloat(tempo - Double(minBPM)) * tickSpacing
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
    
    var body: some View {
        // 使用ZStack和精确定位替代HStack以确保均匀刻度
        ZStack(alignment: .bottom) {
            
             ForEach(minBPM...maxBPM, id: \.self) { bpm in
                 // 在确切位置放置每个刻度
                 VStack(spacing: 4) {
                     // 刻度数字 (仅显示10的倍数)
                     if bpm % 10 == 0 {
                         Text("\(bpm)")
                             .font(.system(size: 12, weight: .bold))
                             .foregroundColor(.gray)
                     }
                    
                     // 刻度线
                     Rectangle()
                         .fill(bpm % 10 == 0 ? Color.gray : Color.gray.opacity(0.5))
                         .frame(width: bpm % 10 == 0 ? majorTickWidth : tickWidth, 
                                height: bpm % 10 == 0 ? majorTickHeight : tickHeight)

                    
                 }
//                 Rectangle().fill(Color.purple)
//                     .frame(width: 200,height: 30)

                 .frame(maxHeight: .infinity,alignment: .bottom)
                 .position(x: CGFloat(bpm - minBPM) * tickSpacing,y:30)
                 
                
             }
            
//            Rectangle().fill(Color.purple)
//                .frame(width: 200,height: 30)

            
//            Text("123")
        }
        .frame(maxHeight: .infinity,alignment: .bottom)
//        .background(Color.purple)
        
    }
}

#Preview {
    BPMRulerView(tempo: .constant(120))
        .frame(height: 60)
        .background(Color.black)
}
