//
//  TimeSignatureView.swift
//  TempoPro
//
//  Created by Meters on 27/2/2025.
//

import SwiftUI

struct TimeSignatureView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var metronomeState: MetronomeState
    @Environment(\.metronomeTheme) var theme
    
    // 可选的拍号单位
    private let availableBeatUnits = [1, 2, 4, 8]
    
    var body: some View {
        ScrollView{
            VStack(spacing: 20) {
                
                // 拍号设置（横向排列）
                HStack(spacing: 0) {
                    // 每小节拍数
                    VStack(alignment: .center, spacing: 5) {
                        Text("每小节拍数")
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            Button(action: {
                                if metronomeState.beatsPerBar > 1 {
                                    metronomeState.updateBeatsPerBar(metronomeState.beatsPerBar - 1)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(theme.primaryColor)
                            }
                            
                            Text("\(metronomeState.beatsPerBar)")
                                .font(.system(size: 28, weight: .medium))
                            
                            Button(action: {
                                if metronomeState.beatsPerBar < 12 {
                                    metronomeState.updateBeatsPerBar(metronomeState.beatsPerBar + 1)
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(theme.primaryColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 拍号单位
                    VStack(alignment: .center, spacing: 5) {
                        Text("拍号单位")
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            Button(action: {
                                if let index = availableBeatUnits.firstIndex(of: metronomeState.beatUnit),
                                   index > 0 {
                                    metronomeState.updateBeatUnit(availableBeatUnits[index - 1])
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(theme.primaryColor)
                            }
                            
                            Text("\(metronomeState.beatUnit)")
                                .font(.system(size: 28, weight: .medium))
                            
                            Button(action: {
                                if let index = availableBeatUnits.firstIndex(of: metronomeState.beatUnit),
                                   index < availableBeatUnits.count - 1 {
                                    metronomeState.updateBeatUnit(availableBeatUnits[index + 1])
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(theme.primaryColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // 显示当前拍号单位下所有可用的切分音符
                VStack(alignment: .leading, spacing: 10) {
                    Text("切分音符")
                        .font(.headline)
                    
                     LazyVGrid(columns: [
                         GridItem(.flexible()),
                         GridItem(.flexible()),
                         GridItem(.flexible()),
                         GridItem(.flexible()),
                         GridItem(.flexible())
                     ], spacing: 10) {
                        let patterns = SubdivisionManager.getSubdivisionPatterns(forBeatUnit: metronomeState.beatUnit)
                        
                        if patterns.isEmpty {
                            Text("当前拍号单位没有预设的切分音符")
                                .foregroundColor(.gray)
                                .padding(.vertical, 5)
                        } else {
                            ForEach(patterns, id: \.name) { pattern in
                                Button(action: {
                                    // 点击时更新切分音符
                                    metronomeState.updateSubdivisionPattern(pattern)
                                }) {
                                    Image(pattern.name)
                                        .resizable()
                                        .scaledToFit()
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 5)
                                        .background(
                                            // 检查当前选中的模式，高亮显示
                                            metronomeState.subdivisionPattern?.name == pattern.name 
                                                ? theme.primaryColor.opacity(0.2) 
                                                : Color(UIColor.secondarySystemBackground)
                                        )
                                        .cornerRadius(5)
                                        // 添加选中指示器
                                        .overlay(
                                            Group {
                                                if metronomeState.subdivisionPattern?.name == pattern.name {
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .stroke(theme.primaryColor, lineWidth: 2)
                                                }
                                            }
                                        )
                                }
                                .buttonStyle(PlainButtonStyle()) // 使用PlainButtonStyle以避免默认按钮样式干扰
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
            }
            .padding(20)
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    TimeSignatureView()
        .environmentObject(MetronomeState())
}
