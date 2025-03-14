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
        NavigationStack {
            List {
                // 拍号设置
                Section(header: Text("拍号设置").foregroundColor(theme.primaryColor)) {
                    // 使用非交互的 Section 内容包装器，让按钮可以正常工作
                    ZStack {
                        HStack(spacing: 0) {
                            // 每小节拍数
                            VStack(alignment: .center, spacing: 10) {
                                Text("每小节拍数")
                                    .font(.custom("MiSansLatin-Regular", size: 16))
                                    .foregroundColor(theme.primaryColor)
                                
                                HStack(spacing: 20) {
                                    // 使用明确的 buttonStyle 和足够大的点击区域
                                    Button {
                                        if metronomeState.beatsPerBar > 1 {
                                            metronomeState.updateBeatsPerBar(metronomeState.beatsPerBar - 1)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(theme.primaryColor)
                                            .frame(width: 44, height: 44) // 增大点击区域
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text("\(metronomeState.beatsPerBar)")
                                        .font(.custom("MiSansLatin-Semibold", size: 28))
                                        .foregroundColor(theme.primaryColor)
                                    
                                    Button {
                                        if metronomeState.beatsPerBar < 12 {
                                            metronomeState.updateBeatsPerBar(metronomeState.beatsPerBar + 1)
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(theme.primaryColor)
                                            .frame(width: 44, height: 44) // 增大点击区域
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .background(theme.primaryColor.opacity(0.3))
                                .frame(height: 40)
                                .padding(.horizontal, 8)
                            
                            // 拍号单位
                            VStack(alignment: .center, spacing: 10) {
                                Text("拍号单位")
                                    .font(.custom("MiSansLatin-Regular", size: 16))
                                    .foregroundColor(theme.primaryColor)
                                
                                HStack(spacing: 20) {
                                    Button {
                                        if let index = availableBeatUnits.firstIndex(of: metronomeState.beatUnit),
                                           index > 0 {
                                            metronomeState.updateBeatUnit(availableBeatUnits[index - 1])
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(theme.primaryColor)
                                            .frame(width: 44, height: 44) // 增大点击区域
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text("\(metronomeState.beatUnit)")
                                        .font(.custom("MiSansLatin-Semibold", size: 28))
                                        .foregroundColor(theme.primaryColor)
                                    
                                    Button {
                                        if let index = availableBeatUnits.firstIndex(of: metronomeState.beatUnit),
                                           index < availableBeatUnits.count - 1 {
                                            metronomeState.updateBeatUnit(availableBeatUnits[index + 1])
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(theme.primaryColor)
                                            .frame(width: 44, height: 44) // 增大点击区域
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 12)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))
                
                // 切分音符部分
                Section(header: Text("切分音符").foregroundColor(theme.primaryColor)) {
                    let patterns = SubdivisionManager.getSubdivisionPatterns(forBeatUnit: metronomeState.beatUnit)
                    
                    if patterns.isEmpty {
                        Text("当前拍号单位没有预设的切分音符")
                            .font(.custom("MiSansLatin-Regular", size: 14))
                            .foregroundColor(theme.primaryColor.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                    } else {
                        VStack(spacing: 16) {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                            ], spacing: 16) {
                                ForEach(patterns, id: \.name) { pattern in
                                    Button {
                                        metronomeState.updateSubdivisionPattern(pattern)
                                    } label: {
                                        Image(pattern.name)
                                            .resizable()
                                            .scaledToFit()
                                            .padding(6)
                                            .frame(height: 60)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(metronomeState.subdivisionPattern?.name == pattern.name 
                                                        ? theme.primaryColor.opacity(0.3) 
                                                        : theme.backgroundColor)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(
                                                        metronomeState.subdivisionPattern?.name == pattern.name 
                                                            ? theme.primaryColor 
                                                            : theme.primaryColor.opacity(0.2),
                                                        lineWidth: metronomeState.subdivisionPattern?.name == pattern.name ? 2 : 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            if let currentPattern = metronomeState.subdivisionPattern {
                                HStack {
                                    Text("当前选择:")
                                        .font(.custom("MiSansLatin-Regular", size: 14))
                                        .foregroundColor(theme.primaryColor.opacity(0.7))
                                    
                                    Text(currentPattern.displayName)
                                        .font(.custom("MiSansLatin-Semibold", size: 14))
                                        .foregroundColor(theme.primaryColor)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
                .listRowBackground(theme.primaryColor.opacity(0.1))
            }
            .navigationTitle("拍号设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon-x")
                            .renderingMode(.template)
                            .foregroundColor(theme.primaryColor)
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .contentShape(Rectangle())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(theme.backgroundColor)
            .scrollContentBackground(.hidden)
            .toolbarBackground(theme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    TimeSignatureView()
        .environmentObject(MetronomeState())
}
