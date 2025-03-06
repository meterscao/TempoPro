//
//  PracticeCompletionView.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/6.
//


// 创建新文件 PracticeCompletionView.swift

import SwiftUI

struct PracticeCompletionView: View {
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    let duration: TimeInterval
    let tempo: Int
    
    var body: some View {
        VStack(spacing: 24) {
            // 图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.primaryColor)
            
            // 标题
            Text("练习完成!")
                .font(.custom("MiSansLatin-Semibold", size: 24))
                .foregroundColor(theme.textColor)
            
            // 详情
            VStack(spacing: 16) {
                HStack {
                    Text("持续时间:")
                        .font(.custom("MiSansLatin-Regular", size: 18))
                        .foregroundColor(theme.textColor.opacity(0.8))
                    Spacer()
                    Text(formatDuration(duration))
                        .font(.custom("MiSansLatin-Semibold", size: 18))
                        .foregroundColor(theme.primaryColor)
                }
                
                HStack {
                    Text("速度:")
                        .font(.custom("MiSansLatin-Regular", size: 18))
                        .foregroundColor(theme.textColor.opacity(0.8))
                    Spacer()
                    Text("\(tempo) BPM")
                        .font(.custom("MiSansLatin-Semibold", size: 18))
                        .foregroundColor(theme.primaryColor)
                }
            }
            .padding()
            .background(theme.backgroundColor.opacity(0.2))
            .cornerRadius(12)
            
            // 关闭按钮
            Button(action: {
                dismiss()
            }) {
                Text("继续")
                    .font(.custom("MiSansLatin-Semibold", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryColor)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background(theme.backgroundColor)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(20)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d小时 %02d分钟 %02d秒", hours, minutes, seconds)
        } else {
            return String(format: "%d分钟 %02d秒", minutes, seconds)
        }
    }
}
