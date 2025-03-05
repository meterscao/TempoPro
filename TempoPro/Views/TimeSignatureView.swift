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
    
    // 临时存储修改的值
    @State private var tempBeatsPerBar: Int = 4
    @State private var tempBeatUnit: Int = 4
    @State private var selectedSubdivision: SubdivisionType = .whole
    
    // 可选的拍号单位
    private let availableBeatUnits = [1, 2, 4, 8, 16, 32]
    
    // 获取有效的切分音符选项（确保不超过32分音符）
    private var validSubdivisions: [SubdivisionType] {
        let allTypes = SubdivisionType.allCases
        // 如果是32分音符，就不再提供更小的划分
        if tempBeatUnit == 32 {
            return [.whole]
        } else if tempBeatUnit == 16 {
            // 16分音符只提供部分划分
            return [.whole, .duple, .dotted, .triplet]
        }
        return allTypes
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 拍号设置（横向排列）
            HStack(spacing: 30) {
                // 每小节拍数
                VStack(alignment: .center, spacing: 5) {
                    Text("每小节拍数")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            if tempBeatsPerBar > 1 {
                                tempBeatsPerBar -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(theme.primaryColor)
                        }
                        
                        Text("\(tempBeatsPerBar)")
                            .font(.system(size: 28, weight: .medium))
                        
                        Button(action: {
                            if tempBeatsPerBar < 12 {
                                tempBeatsPerBar += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                }
                
        
                
                // 拍号单位
                VStack(alignment: .center, spacing: 5) {
                    Text("拍号单位")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            if let index = availableBeatUnits.firstIndex(of: tempBeatUnit),
                               index > 0 {
                                tempBeatUnit = availableBeatUnits[index - 1]
                                // 重置切分音符选择（如果当前选择在新的拍号单位下无效）
                                if !validSubdivisions.contains(selectedSubdivision) {
                                    selectedSubdivision = .whole
                                }
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(theme.primaryColor)
                        }
                        
                        Text("\(tempBeatUnit)")
                            .font(.system(size: 28, weight: .medium))
                        
                        Button(action: {
                            if let index = availableBeatUnits.firstIndex(of: tempBeatUnit),
                               index < availableBeatUnits.count - 1 {
                                tempBeatUnit = availableBeatUnits[index + 1]
                                // 重置切分音符选择（如果当前选择在新的拍号单位下无效）
                                if !validSubdivisions.contains(selectedSubdivision) {
                                    selectedSubdivision = .whole
                                }
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                }
            }
            
            // 切分音符选择区域
            VStack(spacing: 15) {
                Text("切分音符")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // 切分音符选项（网格布局）
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(validSubdivisions) { subdivision in
                        Button(action: {
                            selectedSubdivision = subdivision
                        }) {
                            VStack(spacing: 5) {
                                Text(subdivision.getDescription(forBeatUnit: tempBeatUnit))
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 5)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedSubdivision == subdivision ? theme.primaryColor.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedSubdivision == subdivision ? theme.primaryColor : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(selectedSubdivision == subdivision ? theme.primaryColor : .primary)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // 确认按钮
            Button(action: {
                print("TimeSignatureView - 更新为 \(tempBeatsPerBar)/\(tempBeatUnit), 切分音符: \(selectedSubdivision.rawValue)")
                
                // 直接更新AppStorage，自动保存到UserDefaults
                metronomeState.updateBeatsPerBar(tempBeatsPerBar)
                metronomeState.updateBeatUnit(tempBeatUnit)
                // 存储选择的切分音符类型
                metronomeState.updateSubdivisionType(selectedSubdivision)
                
                dismiss()
            }) {
                Text("确认")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            // 在视图出现时，使用AppStorage的值初始化临时变量
            tempBeatsPerBar = metronomeState.beatsPerBar
            tempBeatUnit = metronomeState.beatUnit
            // 初始化切分音符类型
            selectedSubdivision = metronomeState.subdivisionType
        }
    }
}

#Preview {
    TimeSignatureView()
        .environmentObject(MetronomeState())
}
