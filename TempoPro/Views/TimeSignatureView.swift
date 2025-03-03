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
    
    // 临时存储修改的值
    @State private var tempBeatsPerBar: Int = 4
    @State private var tempBeatUnit: Int = 4
    
    // 可选的拍号单位
    private let availableBeatUnits = [1, 2, 4, 8, 16, 32]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("拍号设置")
                .font(.title2)
                .padding(.top)
            
            // 每小节拍数设置
            VStack(spacing: 10) {
                Text("每小节拍数")
                    .font(.headline)
                
                HStack(spacing: 30) {
                    Button(action: {
                        if tempBeatsPerBar > 1 {
                            tempBeatsPerBar -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(tempBeatsPerBar)")
                        .font(.system(size: 40, weight: .medium))
                    
                    Button(action: {
                        if tempBeatsPerBar < 8 {
                            tempBeatsPerBar += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // 拍号单位设置
            VStack(spacing: 10) {
                Text("拍号单位")
                    .font(.headline)
                
                HStack(spacing: 30) {
                    Button(action: {
                        if let index = availableBeatUnits.firstIndex(of: tempBeatUnit),
                           index > 0 {
                            tempBeatUnit = availableBeatUnits[index - 1]
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(tempBeatUnit)")
                        .font(.system(size: 40, weight: .medium))
                    
                    Button(action: {
                        if let index = availableBeatUnits.firstIndex(of: tempBeatUnit),
                           index < availableBeatUnits.count - 1 {
                            tempBeatUnit = availableBeatUnits[index + 1]
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // 确认按钮
            Button(action: {
                print("TimeSignatureView - 更新为 \(tempBeatsPerBar)/\(tempBeatUnit)")
                
                // 直接更新AppStorage，自动保存到UserDefaults
                metronomeState.updateBeatsPerBar(tempBeatsPerBar)
                metronomeState.updateBeatUnit(tempBeatUnit)
                
                dismiss()
            }) {
                Text("确认")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            // 在视图出现时，使用AppStorage的值初始化临时变量
            tempBeatsPerBar = metronomeState.beatsPerBar
            tempBeatUnit = metronomeState.beatUnit
        }
    }
}

#Preview {
    TimeSignatureView()
}
