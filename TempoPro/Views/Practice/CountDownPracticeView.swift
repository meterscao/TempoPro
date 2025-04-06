//
//  SetTimerView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/13.
//

import SwiftUI

struct CountDownPracticeView: View {
    @EnvironmentObject var practiceCoordinator: PracticeCoordinator
    @EnvironmentObject var practiceViewModel: PracticeViewModel

    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var selectedTimerType: String = ""
    @State private var showCannotStartAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if practiceViewModel.practiceStatus == .standby {
                    // 默认状态 - 设置视图
                    setupView
                } else {
                    // 计时状态 - 计时视图
                    timerView
                }
            }
            .background(Color("backgroundPrimaryColor"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon-x")
                            .renderingMode(.template)
                            .foregroundColor(Color("textSecondaryColor"))
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .contentShape(Rectangle())
                }
                if(practiceViewModel.practiceStatus == .standby){
                ToolbarItem(placement:.principal) {
                    Picker("", selection: $selectedTimerType) {
                        Text("By Time").tag("time")
                        Text("By Bar").tag("bar")
                    }
                    
                    .pickerStyle(.segmented)
                    .preferredColorScheme(.dark)
                    .frame(width: 200)
                    .onChange(of: selectedTimerType) { newValue in
                        // 确保在更改前保存之前的状态
                        let previousType = practiceViewModel.countdownType
                        
                        if newValue == "time" {
                            practiceViewModel.countdownType = .time
                            // 确保时间值有效
                            if practiceViewModel.targetTime == 0 {
                                practiceViewModel.updateTargetTime(60) // 设置默认值，例如1分钟
                            }
                        } else {
                            practiceViewModel.updateCountdownType(.bar)
                            // 确保小节值有效
                            if practiceViewModel.targetBars == 0 {
                                practiceViewModel.updateTargetBars(4) // 设置默认值，例如4小节
                            }
                        }
                        
                        // 如果需要，进行额外的状态重置
                        if previousType != practiceViewModel.countdownType {
                            // 重置相关状态
                        }
                    }
                    
                    }
                }
            }
            .toolbarBackground(.visible)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
        }
        .onAppear {
            // 初始化选择类型
            selectedTimerType = practiceViewModel.countdownType == .time ? "time" : "bar"
        }
    }
    
    // 设置视图
    private var setupView: some View {
        VStack(spacing: 0){
            VStack(){
                    if selectedTimerType == "time" {
                        // 时间选择器
                        timePickerView
                    } else {
                        // 小节选择器
                        barPickerView
                    }
                
                    // // 同步启动选项
                    // Toggle(isOn: $practiceCoordinator.isSyncStartEnabled) {
                    //     Text("同步启动节拍器")
                    //         .font(.custom("MiSansLatin-Regular", size: 16))
                    //         .foregroundColor(Color("textPrimaryColor"))
                    // }
                    
                    // // 同步停止选项
                    // Toggle(isOn: $practiceCoordinator.isSyncStopEnabled) {
                    //     Text("同步停止节拍器")
                    //         .font(.custom("MiSansLatin-Regular", size: 16))
                    //         .foregroundColor(Color("textPrimaryColor"))
                    // }
                    
                    // 循环选项
                    // Toggle(isOn: $practiceCoordinator.isLoopEnabled) {
                    //     Text("循环播放")
                    //         .font(.custom("MiSansLatin-Regular", size: 16))
                    //         .foregroundColor(Color("textPrimaryColor"))
                    // }
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .background(Color("backgroundSecondaryColor"))
            .cornerRadius(15)
            .padding(.horizontal,20)
            .padding(.vertical,20)
            

            HStack(spacing: 15){
                Button(action: {
                    practiceViewModel.updateIsLoopEnabled(!practiceViewModel.isLoopEnabled)
                }){
                    HStack(spacing: 5){
                        Image("icon-repeat-s")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)   
                    }
                    .foregroundColor(practiceViewModel.isLoopEnabled ? Color("backgroundSecondaryColor") : Color("textPrimaryColor"))
                    .frame(height:50)
                    .padding(.horizontal,15)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(practiceViewModel.isLoopEnabled ? Color("textPrimaryColor") : Color("backgroundSecondaryColor"))
                    )
                }
                Button(action: {
                    if practiceViewModel.practiceStatus == .standby {
                        practiceViewModel.startPractice()
                    } else {
                        // 显示警告
                        showCannotStartAlert = true
                    }
                }) {
                    HStack(spacing: 5) {
                        Image("icon-play-s")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)   
                        Text("Start")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                    }
                    .foregroundColor(.accent)
                    .frame(height:50)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("backgroundSecondaryColor"))
                    )
                }
                .disabled((selectedTimerType == "time" && practiceViewModel.targetTime == 0) || 
                        (selectedTimerType == "bar" && practiceViewModel.targetBars == 0))
                .opacity((selectedTimerType == "time" && practiceViewModel.targetTime == 0) || 
                        (selectedTimerType == "bar" && practiceViewModel.targetBars == 0) ? 0.5 : 1)
                .alert(isPresented: $showCannotStartAlert) {
                    Alert(
                        title: Text("无法开始倒计时"),
                        message: Text("渐进练习正在进行中，请先停止再开始新的倒计时"),
                        dismissButton: .default(Text("我知道了"))
                    )
                }
            }
            .padding(.horizontal,20)
            .padding(.bottom,20)    
        }
        .background(Color("backgroundPrimaryColor"))

    }
    
    // 时间选择器视图 - 使用本地状态绑定到协调器
    private var timePickerView: some View {
        // 创建本地状态作为中介
        let hours = Binding<Int>(
            get: { self.targetTimeHours },
            set: { newValue in
                let mins = self.targetTimeMinutes
                let secs = self.targetTimeSeconds
                practiceViewModel.updateTargetTime((newValue * 3600) + (mins * 60) + secs)
            }
        )
        
        let minutes = Binding<Int>(
            get: { self.targetTimeMinutes },
            set: { newValue in
                let hrs = self.targetTimeHours
                let secs = self.targetTimeSeconds
                practiceViewModel.updateTargetTime((hrs * 3600) + (newValue * 60) + secs)
            }
        )
        
        let seconds = Binding<Int>(
            get: { self.targetTimeSeconds },
            set: { newValue in
                let hrs = self.targetTimeHours
                let mins = self.targetTimeMinutes
                practiceViewModel.updateTargetTime((hrs * 3600) + (mins * 60) + newValue)
            }
        )
        
        return HStack(spacing: 0) {
            // 小时
            HStack(spacing: 0) {
                Picker("", selection: hours) {
                    ForEach(0...23, id: \.self) { hour in
                        Text("\(hour)")
                            .tag(hour)
                            .foregroundStyle(Color("textPrimaryColor"))
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 76)
                .frame(maxHeight:.infinity)
                .clipped()
                
                Text("Hour")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textSecondaryColor"))
                    .lineLimit(1)
                    .offset(x: -5)
            }
            .frame(maxWidth:.infinity)
            
            
            // 分钟
            HStack(spacing: 0) {
                Picker("", selection: minutes) {
                    ForEach(0...59, id: \.self) { minute in
                        Text("\(minute)")
                            .tag(minute)
                            .foregroundStyle(Color("textPrimaryColor"))
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 76)
                .frame(maxHeight:.infinity)
                .clipped()
                
                Text("Min")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textSecondaryColor"))
                    .lineLimit(1)
                    .offset(x: -5)
            }
            .frame(maxWidth:.infinity)
            
            
            // 秒
            HStack(spacing: 0) {
                Picker("", selection: seconds) {
                    ForEach(0...59, id: \.self) { second in
                        Text("\(second)")
                            .tag(second)
                            .foregroundStyle(Color("textPrimaryColor"))
                    }
                }
                .foregroundColor(Color("textPrimaryColor"))
                .pickerStyle(.wheel)
                .frame(width: 76)
                .frame(maxHeight:.infinity)
                .clipped()
                
                Text("Sec")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textSecondaryColor"))
                    .lineLimit(1)
                    .offset(x: -5)
            }
            .frame(maxWidth:.infinity)
            
        }
        // .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .frame(maxWidth:.infinity)
        .frame(alignment: .center)
    }
    
    // 便捷计算属性 - 获取时分秒
    private var targetTimeHours: Int {
        practiceViewModel.targetTime / 3600
    }
    
    private var targetTimeMinutes: Int {
        (practiceViewModel.targetTime % 3600) / 60
    }
    
    private var targetTimeSeconds: Int {
        practiceViewModel.targetTime % 60
    }
    
    // 小节选择器视图
    private var barPickerView: some View {
        HStack(spacing: 0) {
            Picker("", selection: $practiceViewModel.targetBars) {
                ForEach(1...100, id: \.self) { bar in
                    Text("\(bar)")
                        .tag(bar)
                        .foregroundStyle(Color("textPrimaryColor"))
                }
            }
            .onChange(of: practiceViewModel.targetBars) { newValue in
                practiceViewModel.updateTargetBars(newValue)
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .frame(maxHeight:.infinity)
            .clipped()
            
            Text("Bars")
                .font(.custom("MiSansLatin-Regular", size: 16))
                .foregroundColor(Color("textSecondaryColor"))
                .padding(.leading, 8)
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .center)  
        .frame(alignment: .center)
    }
    
    // 计时视图
    private var timerView: some View {
        let lineWidth: CGFloat = 14

        return VStack(spacing: 20) {
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(lineWidth: lineWidth)
                        .foregroundColor(Color("AccentColor").opacity(0.3))
                    
                    VStack() {
                        if practiceViewModel.countdownType == .time {
                            // 时间显示
                            Text(practiceViewModel.practiceStatus == .completed ? "已完成" : practiceCoordinator.formatTime(practiceViewModel.remainingTime))
                                .font(.custom("MiSansLatin-Semibold", size: 40))
                                .foregroundColor(Color("textPrimaryColor"))
                            
                            HStack(){
                                Text(practiceCoordinator.formatTime(practiceViewModel.targetTime))
                                    .font(.custom("MiSansLatin-Regular", size: 14))
                                    .foregroundColor(Color("textSecondaryColor"))
                                if practiceViewModel.isLoopEnabled {
                                    Text("Loop Mode")
                                        .font(.custom("MiSansLatin-Regular", size: 14))
                                        .foregroundColor(Color("textSecondaryColor"))
                                }
                            }
                        } else {
                            // 小节显示
                            Text(practiceViewModel.practiceStatus == .completed ? "已完成" : "\(practiceViewModel.remainingBars)")
                                .font(.custom("MiSansLatin-Semibold", size: 40))
                                .foregroundColor(Color("textPrimaryColor"))
                            
                            HStack(){
                                Text("\(practiceViewModel.targetBars) Bars")
                                    .font(.custom("MiSansLatin-Regular", size: 14))
                                    .foregroundColor(Color("textSecondaryColor"))
                                if practiceViewModel.isLoopEnabled {
                                    Text("Loop Mode")
                                        .font(.custom("MiSansLatin-Regular", size: 14))
                                        .foregroundColor(Color("textSecondaryColor"))
                                }
                            }
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .trim(from: 0, to: practiceCoordinator.progress)
                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color("AccentColor"))
                        .rotationEffect(Angle(degrees: -90.0))
                        .animation(practiceCoordinator.isCompletingCycle ? .linear(duration: 0.5) : .linear(duration: 1.0), value: practiceCoordinator.progress)
                        .frame(width:geometry.size.height,height: geometry.size.width)
                )   
            }
            .frame(maxWidth:.infinity,maxHeight: .infinity)
            .padding(lineWidth/2)
//            .padding(20)
            // 控制按钮
            HStack(spacing: 15) {
                // 暂停/继续/重新开始按钮
                Button(action: {
                    if practiceViewModel.practiceStatus == .completed {
                        practiceViewModel.startPractice()
                    } else if practiceViewModel.practiceStatus == .paused {
                        practiceViewModel.resumePractice()
                    } else {
                        practiceViewModel.pausePractice()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(practiceViewModel.practiceStatus == .completed ? "icon-replay-s" :
                              (practiceViewModel.practiceStatus == .paused ? "icon-play-s" : "icon-pause-s"))
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)   
                            
                        Text(practiceViewModel.practiceStatus == .completed ? "Replay" :
                             (practiceViewModel.practiceStatus == .paused ? "Continue" : "Pause"))
                            .font(.custom("MiSansLatin-Regular", size: 16))
                    }
                    .foregroundColor(Color("textPrimaryColor"))
                    .frame(height: 50)
                    .frame(maxWidth:.infinity)
                    .background(Color("backgroundSecondaryColor"))
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
                
                // 停止按钮
                Button(action: {
                    practiceViewModel.stopPractice()
                }) {
                    HStack(spacing: 5) {
                        Image(practiceViewModel.practiceStatus == .completed ? "icon-x-s" : "icon-stop-s")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)   
                            
                        Text(
                            practiceViewModel.practiceStatus == .completed ? "Cancel" : "Stop")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                    }   
                    .foregroundColor(Color("textPrimaryColor"))
                    .frame(maxWidth:.infinity)
                    .frame(height: 50)
                    .background(Color.red.opacity(0.2))
                }
                .contentShape(Rectangle())
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .frame(maxWidth:.infinity,maxHeight: .infinity)
        .background(Color("backgroundPrimaryColor"))
    }
}
