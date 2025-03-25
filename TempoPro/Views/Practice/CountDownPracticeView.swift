//
//  SetTimerView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/13.
//

import SwiftUI

struct CountDownPracticeView: View {
    @EnvironmentObject var practiceCoordinator: PracticeCoordinator
    @EnvironmentObject var metronomeState: MetronomeState
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var selectedTimerType: String = "time" // time 或 bar
    @State private var showCannotStartAlert: Bool = false
    
    init(){
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if practiceCoordinator.practiceStatus == .standby {
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
                if(practiceCoordinator.practiceStatus == .standby){
                ToolbarItem(placement:.principal) {
                    Picker("", selection: $selectedTimerType) {
                        Text("By Time").tag("time")
                        Text("By Bar").tag("bar")
                    }
                    
                    .pickerStyle(.segmented)
                    .preferredColorScheme(.dark)
                    .frame(width: 200)
                    .onChange(of: selectedTimerType) { newValue in
                        if newValue == "time" {
                            practiceCoordinator.countdownType = .time
                        } else {
                            practiceCoordinator.countdownType = .bar
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
            // 只在非运行状态下设置练习模式
            if practiceCoordinator.practiceStatus == .standby {
                // 设置为Countdown模式
                practiceCoordinator.setPracticeMode(.countdown)
            }
            
            // 初始化选择类型
            selectedTimerType = practiceCoordinator.countdownType == .time ? "time" : "bar"
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
            Toggle(isOn: $practiceCoordinator.isSyncStartEnabled) {
                Text("同步启动节拍器")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
            }
            
            // 同步停止选项
            Toggle(isOn: $practiceCoordinator.isSyncStopEnabled) {
                Text("同步停止节拍器")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
            }
            
            // 循环选项
            Toggle(isOn: $practiceCoordinator.isLoopEnabled) {
                Text("循环")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
            }
            
            // 开始按钮
            Button(action: {
                if practiceCoordinator.activeMode == .none || practiceCoordinator.activeMode == .countdown {
                    practiceCoordinator.startPractice()
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
            .disabled((selectedTimerType == "time" && practiceCoordinator.targetTime == 0) || 
                     (selectedTimerType == "bar" && practiceCoordinator.targetBars == 0))
            .opacity((selectedTimerType == "time" && practiceCoordinator.targetTime == 0) || 
                    (selectedTimerType == "bar" && practiceCoordinator.targetBars == 0) ? 0.5 : 1)
            .alert(isPresented: $showCannotStartAlert) {
                Alert(
                    title: Text("无法开始倒计时"),
                    message: Text("渐进练习正在进行中，请先停止再开始新的倒计时"),
                    dismissButton: .default(Text("我知道了"))
                )
            }
        }
        .padding(20)
        .frame(maxWidth:.infinity,maxHeight:.infinity, alignment: .top)
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
                practiceCoordinator.targetTime = (newValue * 3600) + (mins * 60) + secs
            }
        )
        
        let minutes = Binding<Int>(
            get: { self.targetTimeMinutes },
            set: { newValue in
                let hrs = self.targetTimeHours
                let secs = self.targetTimeSeconds
                practiceCoordinator.targetTime = (hrs * 3600) + (newValue * 60) + secs
            }
        )
        
        let seconds = Binding<Int>(
            get: { self.targetTimeSeconds },
            set: { newValue in
                let hrs = self.targetTimeHours
                let mins = self.targetTimeMinutes
                practiceCoordinator.targetTime = (hrs * 3600) + (mins * 60) + newValue
            }
        )
        
        return HStack(spacing: 10) {
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
                
                Text("hours")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textSecondaryColor"))
                    .offset(x: -5)
            }
            
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
                
                Text("min")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textSecondaryColor"))
                    .offset(x: -5)
            }
            
            // 秒
            HStack(spacing: 0) {
                Picker("", selection: seconds) {
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
    
    // 便捷计算属性 - 获取时分秒
    private var targetTimeHours: Int {
        practiceCoordinator.targetTime / 3600
    }
    
    private var targetTimeMinutes: Int {
        (practiceCoordinator.targetTime % 3600) / 60
    }
    
    private var targetTimeSeconds: Int {
        practiceCoordinator.targetTime % 60
    }
    
    // 小节选择器视图
    private var barPickerView: some View {
        HStack(spacing: 0) {
            Picker("", selection: $practiceCoordinator.targetBars) {
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
                        if practiceCoordinator.countdownType == .time {
                            // 时间显示
                            Text(practiceCoordinator.getCountdownDisplayText())
                                .font(.custom("MiSansLatin-Semibold", size: 40))
                                .foregroundColor(Color("textPrimaryColor"))
                            
                            HStack(){
                                Text(practiceCoordinator.formatTime(practiceCoordinator.targetTime))
                                    .font(.custom("MiSansLatin-Regular", size: 14))
                                    .foregroundColor(Color("textSecondaryColor"))
                                if practiceCoordinator.isLoopEnabled {
                                    Text("Loop Mode")
                                        .font(.custom("MiSansLatin-Regular", size: 14))
                                        .foregroundColor(Color("textSecondaryColor"))
                                }
                            }
                        } else {
                            // 小节显示
                            Text("\(practiceCoordinator.remainingBars)")
                                .font(.custom("MiSansLatin-Semibold", size: 40))
                                .foregroundColor(Color("textPrimaryColor"))
                            
                            HStack(){
                                Text("\(practiceCoordinator.targetBars) Bars")
                                    .font(.custom("MiSansLatin-Regular", size: 14))
                                    .foregroundColor(Color("textSecondaryColor"))
                                if practiceCoordinator.isLoopEnabled {
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
                        .foregroundColor(theme.primaryColor)
                        .rotationEffect(Angle(degrees: -90.0))
                        .animation(practiceCoordinator.isCompletingCycle ? .linear(duration: 0.5) : .linear(duration: 1.0), value: practiceCoordinator.progress)
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
                    if practiceCoordinator.practiceStatus == .completed {
                        practiceCoordinator.startPractice()
                    } else if practiceCoordinator.practiceStatus == .paused {
                        practiceCoordinator.resumePractice()
                    } else {
                        practiceCoordinator.pausePractice()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(practiceCoordinator.practiceStatus == .completed ? "icon-replay" : 
                              (practiceCoordinator.practiceStatus == .paused ? "icon-play" : "icon-pause"))
                            .renderingMode(.template)   
                            .resizable()
                            .frame(width: 20, height: 20)   
                            
                        Text(practiceCoordinator.practiceStatus == .completed ? "重新播放" : 
                             (practiceCoordinator.practiceStatus == .paused ? "继续" : "暂停"))
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
                    practiceCoordinator.stopPractice()
                }) {
                    HStack(spacing: 5) {
                        Image(practiceCoordinator.practiceStatus == .completed ? "icon-x" : "icon-stop")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)   
                            
                        Text(
                            practiceCoordinator.practiceStatus == .completed ? "返回" : "停止")
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
    let practiceCoordinator = PracticeCoordinator(metronomeState: metronomeState)
    
    return CountDownPracticeView()
        .environmentObject(practiceCoordinator)
        .environmentObject(metronomeState)
}

