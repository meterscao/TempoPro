//
//  SetTimerView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/13.
//

import SwiftUI

struct SetTimerView: View {
    // 添加新的时间状态变量
    @State private var selectedHours = 0
    @State private var selectedMinutes = 5 // 默认5分钟
    @State private var selectedSeconds = 0
    
    @State private var isLoopEnabled = false
    @State private var isTimerRunning = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer? = nil
    
    // 环境变量
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    // 计算属性
    private var totalSeconds: Int {
        return (selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds
    }
    
    private var remainingSeconds: Int {
        return max(0, totalSeconds - elapsedSeconds)
    }
    
    private var progress: CGFloat {
        return totalSeconds > 0 ? CGFloat(elapsedSeconds) / CGFloat(totalSeconds) : 0
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
                        Image("icon-x")
                            .renderingMode(.template)
                            .foregroundColor(theme.primaryColor)
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .contentShape(Rectangle())
                    
                    
                }
            }
            .background(theme.backgroundColor)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }
    
    // 设置视图
    private var setupView: some View {
        VStack(spacing: 15) {
            
                HStack(spacing: 10) {
                    // 小时
                    HStack(spacing: 0) {
                        Picker("", selection: $selectedHours) {
                            ForEach(0...23, id: \.self) { hour in
                                Text("\(hour)")
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()
                        
                        Text("小时")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(Color("textSecondaryColor"))
                            .offset(x: -5)
                    }
                    
                    // 分钟
                    HStack(spacing: 0) {
                        Picker("", selection: $selectedMinutes) {
                            ForEach(0...59, id: \.self) { minute in
                                Text("\(minute)")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()
                        
                        Text("分钟")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(Color("textSecondaryColor"))
                            .offset(x: -5)
                    }
                    
                    // 秒
                    HStack(spacing: 0) {
                        Picker("", selection: $selectedSeconds) {
                            ForEach(0...59, id: \.self) { second in
                                Text("\(second)")
                                    .tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()
                        
                        Text("秒")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(Color("textSecondaryColor"))
                            .offset(x: -5)
                    }
                }
            
            
            
            // 循环选项
            Toggle(isOn: $isLoopEnabled) {
                Text("循环计时")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
            }
            
            
            // 开始按钮
            Button(action: startTimer) {
                Text("开始计时")
                    .font(.custom("MiSansLatin-Semibold", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primaryColor)
                    )
                    
            }
            .padding(.bottom, 40)
            .disabled(totalSeconds == 0)
            .opacity(totalSeconds == 0 ? 0.5 : 1)
        }
        .padding(20)
        .frame(maxWidth:.infinity,maxHeight:.infinity, alignment: .top)
        .background(Color("backgroundPrimaryColor"))
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
