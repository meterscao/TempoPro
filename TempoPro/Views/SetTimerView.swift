//
//  SetTimerView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/13.
//

import SwiftUI

struct SetTimerView: View {
    // 时间选项（分钟）
    private let timeOptions = [1, 2, 5, 10, 20, 30, 45, 60, 90, 120]
    
    // 状态变量
    @State private var selectedTimeIndex = 2 // 默认选择5分钟
    @State private var isLoopEnabled = false
    @State private var isTimerRunning = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer? = nil
    
    // 环境变量
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    // 计算属性
    private var selectedMinutes: Int {
        return timeOptions[selectedTimeIndex]
    }
    
    private var totalSeconds: Int {
        return selectedMinutes * 60
    }
    
    private var remainingSeconds: Int {
        return max(0, totalSeconds - elapsedSeconds)
    }
    
    private var progress: CGFloat {
        return CGFloat(elapsedSeconds) / CGFloat(totalSeconds)
    }
    
    // 时间格式化
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if !isTimerRunning {
                    // 默认状态 - 设置视图
                    setupView
                } else {
                    // 计时状态 - 计时视图
                    timerView
                }
            }
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            .background(theme.backgroundColor)
            .toolbarBackground(theme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }
    
    // 设置视图
    private var setupView: some View {
        List {
            // 时间选择
            Section(header: Text("选择时长").foregroundColor(theme.primaryColor)) {
                timeSelectionView
            }
            .listRowBackground(theme.primaryColor.opacity(0.1))
            
            // 循环选项
            Section {
                loopToggleView
            }
            .listRowBackground(theme.primaryColor.opacity(0.1))
            
            // 开始按钮
            Section {
                Button(action: startTimer) {
                    HStack {
                        
                        Text("开始练习")
                            .font(.custom("MiSansLatin-Semibold", size: 18))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                        
                    }
                    .frame(maxWidth: .infinity)
                    .background(theme.primaryColor)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Color.clear)
            }
            .listRowBackground(theme.primaryColor.opacity(0.1))
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
    }
    
    // 时间选择视图
    private var timeSelectionView: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<timeOptions.count, id: \.self) { index in
                let timeOption = timeOptions[index]
                
                Button(action: {
                    selectedTimeIndex = index
                }) {
                    Text("\(timeOption)分钟")
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(selectedTimeIndex == index ? .white : theme.primaryColor)
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeIndex == index ? theme.primaryColor : theme.backgroundColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.primaryColor.opacity(0.3), lineWidth: 1)
                        )
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
    
    // 循环开关视图
    private var loopToggleView: some View {
        Toggle(isOn: $isLoopEnabled) {
            Text("循环计时")
                .font(.custom("MiSansLatin-Regular", size: 16))
                .foregroundColor(theme.primaryColor)
        }
        .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
    }
    
    // 计时视图
    private var timerView: some View {
        VStack(spacing: 40) {
            // 进度环
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.1)
                    .foregroundColor(theme.primaryColor)
                
                // 进度圆环
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(theme.primaryColor)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear(duration: 1.0), value: progress)
                
                // 时间文本
                VStack(spacing: 8) {
                    Text(formatTime(remainingSeconds))
                        .font(.custom("MiSansLatin-Semibold", size: 40))
                        .foregroundColor(theme.primaryColor)
                    
                    Text("总时长 \(formatTime(totalSeconds))")
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(theme.primaryColor.opacity(0.7))
                }
            }
            .frame(width: 250, height: 250)
            .padding()
            
            // 控制按钮
            HStack(spacing: 30) {
                // 暂停/继续按钮
                Button(action: togglePause) {
                    Image(systemName: timer == nil ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(theme.primaryColor)
                        .clipShape(Circle())
                }
                
                // 停止按钮
                Button(action: stopTimer) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            
            if isLoopEnabled {
                Text("循环模式已开启")
                    .font(.custom("MiSansLatin-Regular", size: 14))
                    .foregroundColor(theme.primaryColor.opacity(0.6))
                    .padding(.top, 20)
            }
        }
        .padding()
    }
    
    // 开始计时器
    private func startTimer() {
        isTimerRunning = true
        elapsedSeconds = 0
        startTimerTick()
    }
    
    // 开始计时器滴答
    private func startTimerTick() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if elapsedSeconds < totalSeconds {
                elapsedSeconds += 1
            } else {
                // 计时结束
                timer?.invalidate()
                timer = nil
                
                // 如果启用了循环，重新开始计时
                if isLoopEnabled {
                    elapsedSeconds = 0
                    startTimerTick()
                }
            }
        }
    }
    
    // 暂停/继续计时器
    private func togglePause() {
        if timer == nil {
            // 继续计时
            startTimerTick()
        } else {
            // 暂停计时
            timer?.invalidate()
            timer = nil
        }
    }
    
    // 停止计时器
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        elapsedSeconds = 0
    }
}

#Preview {
    SetTimerView()
}
