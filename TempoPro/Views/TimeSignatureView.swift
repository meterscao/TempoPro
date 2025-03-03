//
//  TimeSignatureView.swift
//  TempoPro
//
//  Created by Meters on 27/2/2025.
//

import SwiftUI

struct TimeSignatureView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 改用AppStorage直接管理状态
    @AppStorage(AppStorageKeys.Metronome.beatsPerBar) private var beatsPerBar: Int = 4
    @AppStorage(AppStorageKeys.Metronome.beatUnit) private var beatUnit: Int = 4
    
    // 临时存储修改的值
    @State private var tempBeatsPerBar: Int
    @State private var tempBeatUnit: Int
    
    // 可选的拍号单位
    private let availableBeatUnits = [1, 2, 4, 8, 16, 32]
    
    init() {
        // 从AppStorage读取初始值
        let savedBeatsPerBar = UserDefaults.standard.integer(forKey: AppStorageKeys.Metronome.beatsPerBar)
        let savedBeatUnit = UserDefaults.standard.integer(forKey: AppStorageKeys.Metronome.beatUnit)
        
        // 使用有效值或默认值
        let initialBeatsPerBar = savedBeatsPerBar != 0 ? savedBeatsPerBar : 4
        let initialBeatUnit = savedBeatUnit != 0 ? savedBeatUnit : 4
        
        self._tempBeatsPerBar = State(initialValue: initialBeatsPerBar)
        self._tempBeatUnit = State(initialValue: initialBeatUnit)
        
        print("TimeSignatureView - 初始化 - 使用AppStorage")
    }
    
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
                print("TimeSignatureView - 确认按钮点击: 从 \(beatsPerBar)/\(beatUnit) 更新为 \(tempBeatsPerBar)/\(tempBeatUnit)")
                
                // 直接更新AppStorage，自动保存到UserDefaults
                beatsPerBar = tempBeatsPerBar
                beatUnit = tempBeatUnit
                
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
    }
}

#Preview {
    TimeSignatureView()
}
