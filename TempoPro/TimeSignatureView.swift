//
//  TimeSignatureView.swift
//  TempoPro
//
//  Created by Meters on 27/2/2025.
//

import SwiftUI

struct TimeSignatureView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var beatsPerBar: Int
    @Binding var beatUnit: Int
    
    // 临时存储修改的值
    @State private var tempBeatsPerBar: Int
    @State private var tempBeatUnit: Int
    
    // 可选的拍号单位
    private let availableBeatUnits = [1, 2, 4, 8, 16, 32]
    
    init(beatsPerBar: Binding<Int>, beatUnit: Binding<Int>) {
        self._beatsPerBar = beatsPerBar
        self._beatUnit = beatUnit
        self._tempBeatsPerBar = State(initialValue: beatsPerBar.wrappedValue)
        self._tempBeatUnit = State(initialValue: beatUnit.wrappedValue)
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
    TimeSignatureView(
        beatsPerBar: .constant(4),
        beatUnit: .constant(4)
    )
}
