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
    @State private var isTimerCompleted = false // 跟踪计时器是否已完成
    
    // 环境变量
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var metronomeState: MetronomeState
    
    // 计算属性
    private var totalSeconds: Int {
        return (selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds
    }
    
    private var remainingSeconds: Int {
        return max(0, totalSeconds - elapsedSeconds)
    }
    
    private var progress: CGFloat {
        return totalSeconds > 0 ? CGFloat(elapsedSeconds) / CGFloat(totalSeconds) : 0.01
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
                            .foregroundColor(Color("textPrimaryColor"))
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
        VStack(spacing: 20) {
            
            Spacer()
            
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
                    .frame(maxHeight:.infinity)
                    .clipped()
                    
                    Text("hours")
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
                    .frame(maxHeight:.infinity)
                    .clipped()
                    
                    Text("min")
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
                    .frame(maxHeight:.infinity)
                    .clipped()
                    
                    Text("sec")
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(Color("textSecondaryColor"))
                        .offset(x: -5)
                }
            }
            
            
            Spacer()
            
            // 循环选项
            Toggle(isOn: $isLoopEnabled) {
                Text("Loop")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
            }
            
            
            
            
            // 开始按钮
            Button(action: startTimer) {
                HStack(spacing: 5) {
                    Image("icon-play")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)   
                    Text("Start")
                    .font(.custom("MiSansLatin-Semibold", size: 17))
                }
                .foregroundColor(.white)
                .frame(height:52)
                .frame(maxWidth: .infinity)
                
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.primaryColor)
                )
                    
            }
            .disabled(totalSeconds == 0)
            .opacity(totalSeconds == 0 ? 0.5 : 1)
        }
        .padding(20)
        .frame(maxWidth:.infinity,maxHeight:.infinity, alignment: .top)
        .background(Color("backgroundPrimaryColor"))
    }
    
    // 计时视图
    private var timerView: some View {

        let lineWidth: CGFloat = 16

        return VStack(spacing: 20) {
            
            Spacer()
            
            GeometryReader { geometry in// 进度环
                ZStack {

                    RoundedRectangle(cornerRadius: 40)
                        .stroke(lineWidth: lineWidth)
                        .foregroundColor(theme.primaryColor.opacity(0.3))
                    
                    // 时间文本
                    VStack() {
                        Text(formatTime(remainingSeconds))
                            .font(.custom("MiSansLatin-Semibold", size: 40))
                            .foregroundColor(Color("textPrimaryColor"))
                        
                        Text("Total Time \(formatTime(totalSeconds))")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(Color("textSecondaryColor"))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .trim(from: 0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                        .foregroundColor(theme.primaryColor)
                        .rotationEffect(Angle(degrees: -90.0))
                        .animation(.linear(duration: 1.0), value: progress)
                        .frame(width:geometry.size.height,height: geometry.size.width)
                )   
                

            }
            .frame(maxWidth:.infinity,maxHeight: .infinity)
            .padding(lineWidth/2)
            
            Spacer()
            
            if isLoopEnabled {
                Text("Loop Mode")
                    .font(.custom("MiSansLatin-Regular", size: 14))
                    .foregroundColor(Color("textSecondaryColor"))
            }
            // 控制按钮
            HStack(spacing: 15) {
                // 暂停/继续/重新开始按钮
                Button(action: {
                    if isTimerCompleted {
                        // 重新开始
                        elapsedSeconds = 0
                        isTimerCompleted = false
                        startTimerTick()
                        metronomeState.play()
                    } else {
                        // 暂停或继续
                        togglePause()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(isTimerCompleted ? "icon-replay" : (timer == nil ? "icon-play" : "icon-pause"))
                            .renderingMode(.template)   
                            .resizable()
                            .frame(width: 20, height: 20)   
                            
                        Text(isTimerCompleted ? "Replay" : (timer == nil ? "Continue" : "Pause"))
                            .font(.custom("MiSansLatin-Semibold", size: 17))
                    }
                    .foregroundColor(.white)
                    .frame(height: 52)
                    .frame(maxWidth:.infinity)
                    .background(theme.primaryColor)
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .contentShape(Rectangle())
                
                // 停止按钮
                Button(action: stopTimer) {
                        HStack(spacing: 5) {
                            Image("icon-stop")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 20, height: 20)   
                                
                            Text("Stop")
                                .font(.custom("MiSansLatin-Semibold", size: 17))
                        }   
                        .foregroundColor(.white)
                        .frame(maxWidth:.infinity)
                        .frame(height: 52)
                        .background(Color.red.opacity(0.8))
                }
                .contentShape(Rectangle())
                .clipShape(RoundedRectangle(cornerRadius: 15))
                
            }
            
            
        }
        .padding(20)
        .frame(maxWidth:.infinity,maxHeight: .infinity)
        .background(Color("backgroundPrimaryColor"))
        
    }
    
    // 开始计时器
    private func startTimer() {
        isTimerRunning = true
        elapsedSeconds = 0
        _ = remainingSeconds

        startTimerTick()
        metronomeState.play()
    }
    
    // 开始计时器滴答
    private func startTimerTick() {
        isTimerCompleted = false // 重置完成状态
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if elapsedSeconds < totalSeconds {
                elapsedSeconds += 1
            } else {
                // 计时结束
                timer?.invalidate()
                timer = nil
                isTimerCompleted = true // 设置为已完成
                
                // 如果启用了循环，重新开始计时
                if isLoopEnabled {
                    elapsedSeconds = 0
                    isTimerCompleted = false // 重置完成状态
                    startTimerTick()
                }
                else {
                    metronomeState.stop()
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
        metronomeState.stop()
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        elapsedSeconds = 0
        isTimerCompleted = false // 重置完成状态
    }
}

#Preview {
    SetTimerView()
        .environmentObject(MetronomeState())
}
