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
    private let availableBeatUnits = [1, 2, 4, 8, 16]
    
    var body: some View {
        ScrollView{
            VStack(spacing: 20) {
                
                // 拍号设置（横向排列）
                HStack(spacing: 30) {
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
                }
                
                // 显示当前拍号单位下所有可用的切分音符
                VStack(alignment: .leading, spacing: 10) {
                    Text("当前拍号单位支持的切分音符")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        let patterns = SubdivisionManager.getSubdivisionPatterns(forBeatUnit: metronomeState.beatUnit)
                        
                        if patterns.isEmpty {
                            Text("当前拍号单位没有预设的切分音符")
                                .foregroundColor(.gray)
                                .padding(.vertical, 5)
                        } else {
                            ForEach(patterns, id: \.name) { pattern in
                                HStack {
                                    Text("• \(pattern.displayName)")
                                        .font(.system(.body))
                                    
                                    Spacer()
                                    
                                    Text(pattern.description)
                                        .font(.system(.caption))
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(5)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 返回按钮
                Button(action: {
                    dismiss()
                }) {
                    Text("返回")
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
            
        }
        .padding(30)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    TimeSignatureView()
        .environmentObject(MetronomeState())
}
