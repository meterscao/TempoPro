//
//  SetTimerView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/13.
//

import SwiftUI

struct CountDownTimerView: View {
    @EnvironmentObject var practiceTimerState: PracticeTimerState
    @EnvironmentObject var metronomeState: MetronomeState
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var selectedTimerType : String = "time" // time or bar
    @State private var showCannotStartAlert: Bool = false
    
    init(){
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if practiceTimerState.timerStatus == .standby {
                    // 默认状态 - 设置视图
                    setupView
                } else {
                    // 计时状态 - 计时视图
                    timerView
                }
            }
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
                if(practiceTimerState.timerStatus == .standby){
                ToolbarItem(placement:.principal) {
                    Picker("", selection: $selectedTimerType) {
                        Text("By Time").tag("time")
                        Text("By Bar").tag("bar")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .onChange(of: selectedTimerType) { newValue in
                        if newValue == "time" {
                            practiceTimerState.setTimerType(.time)
                        } else {
                            practiceTimerState.setTimerType(.bar)
                        }
                    }
                    
                    }
                }
            }
            .background(theme.backgroundColor)
            .toolbarBackground(.visible)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
        }
        .onAppear {
            // 记录当前状态，以便在切换时保留
            let wasRunning = practiceTimerState.isAnyTimerRunning()
            let previousMode = practiceTimerState.practiceMode
            
            // 设置为Countdown模式
            if !wasRunning || previousMode == .countdown {
                practiceTimerState.practiceMode = .countdown
                
                // 初始化选择类型
                selectedTimerType = practiceTimerState.countdownTimerType.rawValue
                
                // 记录初始状态
                print("DEBUG: SetPracticeTimerView出现 - timerType: \(practiceTimerState.activeTimerType), completedBars: \(metronomeState.completedBars), isPlaying: \(metronomeState.isPlaying)")
                
                // 如果metronomeState已有completedBars值且不处于播放状态，可能导致问题
                if metronomeState.completedBars > 0 && !metronomeState.isPlaying {
                    print("DEBUG: ⚠️ 警告 - metronomeState.completedBars未重置: \(metronomeState.completedBars)")
                }
            }
        }
    }
    
    // 设置视图
    private var setupView: some View {
        VStack(spacing: 20) {
            
            
            if selectedTimerType == "time" {
                // 时间选择器
                timePickerView
            } else {
                // 小节选择器
                barPickerView
            }
            
            

            // 同步启动选项
            Toggle(isOn: $practiceTimerState.isSyncStartEnabled) {
                Text("同步启动节拍器")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
            }
            
            // 同步停止选项
            Toggle(isOn: $practiceTimerState.isSyncStopEnabled) {
                Text("同步停止节拍器")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
            }
            
            // 循环选项
            Toggle(isOn: $practiceTimerState.isLoopEnabled) {
                Text("循环")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
            }
    
    
            
            // 开始按钮
            Button(action: {
                if practiceTimerState.canStartNewPractice(mode: .countdown) {
                    print("DEBUG: 点击开始按钮 - 计时类型: \(selectedTimerType), 目标小节: \(practiceTimerState.targetBars)")
                    practiceTimerState.startTimer()
                } else {
                    // 显示警告
                    showCannotStartAlert = true
                }
            }) {
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
            .disabled((selectedTimerType == "time" && practiceTimerState.totalSeconds == 0) || 
                     (selectedTimerType == "bar" && practiceTimerState.targetBars == 0))
            .opacity((selectedTimerType == "time" && practiceTimerState.totalSeconds == 0) || 
                    (selectedTimerType == "bar" && practiceTimerState.targetBars == 0) ? 0.5 : 1)
            .alert(isPresented: $showCannotStartAlert) {
                Alert(
                    title: Text("无法开始倒计时"),
                    message: Text(practiceTimerState.getCannotStartMessage()),
                    dismissButton: .default(Text("我知道了"))
                )
            }
        }
        .padding(20)
        .frame(maxWidth:.infinity,maxHeight:.infinity, alignment: .top)
        .background(Color("backgroundPrimaryColor"))
    }
    
    // 时间选择器视图
    private var timePickerView: some View {
        HStack(spacing: 10) {
            // 小时
            HStack(spacing: 0) {
                Picker("", selection: $practiceTimerState.selectedHours) {
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
                
                Text("hours")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textSecondaryColor"))
                    .offset(x: -5)
            }
            
            // 分钟
            HStack(spacing: 0) {
                Picker("", selection: $practiceTimerState.selectedMinutes) {
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
                
                Text("min")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textSecondaryColor"))
                    .offset(x: -5)
            }
            
            // 秒
            HStack(spacing: 0) {
                Picker("", selection: $practiceTimerState.selectedSeconds) {
                    ForEach(0...59, id: \.self) { second in
                        Text("\(second)")
                            .tag(second)
                            .foregroundStyle(Color("textPrimaryColor"))
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 76)
                .frame(maxHeight:.infinity)
                .clipped()
                
                Text("sec")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textSecondaryColor"))
                    .offset(x: -5)
            }
        }
    }
    
    // 小节选择器视图
    private var barPickerView: some View {
        HStack(spacing: 0) {
            Picker("", selection: $practiceTimerState.targetBars) {
                ForEach(1...100, id: \.self) { bar in
                    Text("\(bar)")
                        .tag(bar)
                        .foregroundStyle(Color("textPrimaryColor"))
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .frame(maxHeight:.infinity)
            .clipped()
            #if os(iOS)
            .onChange(of: practiceTimerState.targetBars) { newValue in
                print("DEBUG: 目标小节变更 - 新值:\(newValue)")
                print("DEBUG: 目标小节变更后 - completedBars: \(metronomeState.completedBars), previousCompletedBars: \(practiceTimerState.previousCompletedBars), remainingBars: \(practiceTimerState.remainingBars)")
            }
            #endif
            
            Text("bars")
                .font(.custom("MiSansLatin-Regular", size: 16))
                .foregroundColor(Color("textSecondaryColor"))
                .padding(.leading, 8)
        }
    }
    
    // 计时视图
    private var timerView: some View {
        let lineWidth: CGFloat = 14

        return VStack(spacing: 20) {
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(lineWidth: lineWidth)
                        .foregroundColor(theme.primaryColor.opacity(0.3))
                    
                    VStack() {
                        if practiceTimerState.activeTimerType == .time {
                            // 时间显示
                            Text(practiceTimerState.formatTime(practiceTimerState.remainingSeconds))
                                .font(.custom("MiSansLatin-Semibold", size: 40))
                                .foregroundColor(Color("textPrimaryColor"))
                            
                            HStack(){
                                Text("\(practiceTimerState.formatTime(practiceTimerState.totalSeconds))")
                                    .font(.custom("MiSansLatin-Regular", size: 14))
                                    .foregroundColor(Color("textSecondaryColor"))
                                if practiceTimerState.isLoopEnabled {
                                    Text("Loop Mode")
                                        .font(.custom("MiSansLatin-Regular", size: 14))
                                        .foregroundColor(Color("textSecondaryColor"))
                                }
                            }
                        } else {
                            // 小节显示
                            let remainingBars = practiceTimerState.remainingBars
                            
                            Text("\(remainingBars)")
                                .font(.custom("MiSansLatin-Semibold", size: 40))
                                .foregroundColor(Color("textPrimaryColor"))
                                .onAppear {
                                    print("DEBUG: 显示剩余小节 - remainingBars: \(remainingBars), targetBars: \(practiceTimerState.targetBars)")
                                }
                                #if os(iOS)
                                .onChange(of: remainingBars) { newValue in
                                    print("DEBUG: 剩余小节变更 - remainingBars: \(newValue), targetBars: \(practiceTimerState.targetBars)")
                                }
                                #endif
                            
                            HStack(){
                                Text("\(practiceTimerState.targetBars) Bars")
                                    .font(.custom("MiSansLatin-Regular", size: 14))
                                    .foregroundColor(Color("textSecondaryColor"))
                                if practiceTimerState.isLoopEnabled {
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
                        .trim(from: 0, to: practiceTimerState.progress)
                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                        .foregroundColor(theme.primaryColor)
                        .rotationEffect(Angle(degrees: -90.0))
                        .animation(.linear(duration: 1.0), value: practiceTimerState.progress)
                        .frame(width:geometry.size.height,height: geometry.size.width)
                )   
            }
            .frame(maxWidth:.infinity,maxHeight: .infinity)
            .padding(lineWidth/2)
            
            Spacer()
            
            // 控制按钮
            HStack(spacing: 15) {
                // 暂停/继续/重新开始按钮
                Button(action: {
                    if practiceTimerState.timerStatus == .completed {
                        practiceTimerState.elapsedSeconds = 0
                        practiceTimerState.startTimerTick()
                    } else {
                        practiceTimerState.togglePause()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(practiceTimerState.timerStatus == .completed ? "icon-replay" : 
                              (practiceTimerState.timerStatus == .paused ? "icon-play" : "icon-pause"))
                            .renderingMode(.template)   
                            .resizable()
                            .frame(width: 20, height: 20)   
                            
                        Text(practiceTimerState.timerStatus == .completed ? "重新播放" : 
                             (practiceTimerState.timerStatus == .paused ? "继续" : "暂停"))
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
                Button(action: {
                    practiceTimerState.stopTimer()
                }) {
                    HStack(spacing: 5) {
                        Image(practiceTimerState.timerStatus == .completed ? "icon-x" : "icon-stop")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)   
                            
                        Text(
                            practiceTimerState.timerStatus == .completed ? "返回" : "停止")
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
}

#Preview {
    let metronomeState = MetronomeState()
    let timerState = PracticeTimerState()
    timerState.setMetronomeState(metronomeState)
    
    return CountDownTimerView()
        .environmentObject(timerState)
        .environmentObject(metronomeState)
}

