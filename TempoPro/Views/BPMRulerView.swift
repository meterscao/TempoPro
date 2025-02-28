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
    private let maxBPM: Int = 300
    
    // 视图参数
    private let tickHeight: CGFloat = 12
    private let majorTickHeight: CGFloat = 20
    private let tickWidth: CGFloat = 1
    private let majorTickWidth: CGFloat = 2
    private let pointerWidth: CGFloat = 2
    private let pointerHeight: CGFloat = 30
    private let tickSpacing: CGFloat = 5  // 刻度线之间的固定间距
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // 使用固定位置布局而非 ScrollView 以提高性能和准确性
                ZStack {
                    // 计算滑尺的总宽度和单个刻度宽度
                    let totalWidth = geometry.size.width * 5 // 扩大可视范围以容纳所有刻度
                    let visibleCenter = geometry.size.width / 2
                    let pixelsPerBPM = tickSpacing // 每个BPM占据的像素宽度
                    
                    // 计算当前tempo对应的偏移量
                    let tempoOffset = CGFloat(tempo - Double(minBPM)) * pixelsPerBPM
                    let startOffset = visibleCenter - tempoOffset
                    
                    // 绘制所有刻度和标签
                    ForEach(minBPM...maxBPM, id: \.self) { bpm in
                        VStack(spacing: 4) {
                            // 刻度数字 (仅显示10的倍数)
                            if bpm % 10 == 0 {
                                Text("\(bpm)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                                    .fixedSize()
                            } else {
                                Spacer()
                                    .frame(height: 16)
                            }
                            
                            // 刻度线
                            Rectangle()
                                .fill(bpm % 10 == 0 ? Color.gray : Color.gray.opacity(0.5))
                                .frame(width: bpm % 10 == 0 ? majorTickWidth : tickWidth, 
                                       height: bpm % 10 == 0 ? majorTickHeight : tickHeight)
                        }
                        .position(
                            x: startOffset + CGFloat(bpm - minBPM) * pixelsPerBPM,
                            y: 25
                        )
                    }
                }
                
                // 中心红色指针
                Rectangle()
                    .fill(Color.red)
                    .frame(width: pointerWidth, height: pointerHeight)
                
                // 渐变遮罩
                HStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 50)
                    
                    Spacer()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0), Color.black]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 50)
                }
            }
        }
        .frame(height: 60)
        .background(Color.black)
        .clipped() // 裁剪超出边界的内容
    }
}

#Preview {
    BPMRulerView(tempo: .constant(120))
        .frame(height: 60)
        .background(Color.black)
}