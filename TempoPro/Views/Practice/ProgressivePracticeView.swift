//
//  StepTimerView.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/23.
//

import SwiftUI

struct ProgressivePracticeView: View {
    @EnvironmentObject var practiceTimerState: PracticeTimerState
    @EnvironmentObject var metronomeState: MetronomeState
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var selectedTimerType: String = "time" // time or bar
    @State private var showCannotStartAlert: Bool = false
    
    init() {
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
                
                if(practiceTimerState.timerStatus == .standby) {
                    ToolbarItem(placement: .principal) {
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
            
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
            .background(Color("backgroundPrimaryColor"))
            .toolbarBackground(.visible)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
        }
        .onAppear {
            // 记录当前状态，以便在切换时保留
            let wasRunning = practiceTimerState.isAnyTimerRunning()
            let previousMode = practiceTimerState.practiceMode
            
            // 设置为Step模式，但不改变计时器运行状态
            if !wasRunning || previousMode == .progressive {
                practiceTimerState.practiceMode = .progressive
                
                // 初始化选择类型
                selectedTimerType = practiceTimerState.stepTimerType.rawValue
            }
        }
    }
    
    // 验证设置是否有效
    private var isSettingValid: Bool {
        return practiceTimerState.stepFromBPM <= practiceTimerState.stepToBPM
    }
    
    // 设置视图
    private var setupView: some View {
        VStack(spacing: 20) {
            if selectedTimerType == "time" {
                // 时间模式设置
                timeSetupView
            } else {
                // 小节模式设置
                barSetupView
            }
            
            
            // 开始按钮
            Button(action: {
                if practiceTimerState.canStartNewPractice(mode: .progressive) {
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
                .foregroundColor(Color("textPrimaryColor"))
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                    
                        .fill(isSettingValid ? Color("backgroundSecondaryColor") : Color("backgroundSecondaryColor").opacity(0.5))
                )
            }
            .disabled(!isSettingValid)
            .alert(isPresented: $showCannotStartAlert) {
                Alert(
                    title: Text("无法开始渐进练习"),
                    message: Text(practiceTimerState.getCannotStartMessage()),
                    dismissButton: .default(Text("我知道了"))
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // .padding(20)
        .background(Color("backgroundPrimaryColor"))
    }
    
    // 时间模式设置视图
    private var timeSetupView: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                // From BPM
                HStack(spacing: 0) {
                    Text("From")
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                    Picker("", selection: $practiceTimerState.stepFromBPM) {
                        ForEach(30...240, id: \.self) { bpm in
                            Text("\(bpm)")
                                .tag(bpm)
                                .foregroundStyle(Color("textPrimaryColor"))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()
                    Text("BPM")
                        .font(.custom("MiSansLatin-Regular", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                        .frame(width: 40, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .background(Color("backgroundSecondaryColor"))
                .cornerRadius(6)
                
                
                
                // To BPM
                HStack(spacing: 0) {
                    Text("To")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))

                    Picker("", selection: $practiceTimerState.stepToBPM) {
                        ForEach(30...240, id: \.self) { bpm in
                            Text("\(bpm)")
                                .tag(bpm)
                                .foregroundStyle(Color("textPrimaryColor"))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()
                    
                    Text("BPM")
                        .font(.custom("MiSansLatin-Regular", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                        .frame(width: 40, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .background(Color("backgroundSecondaryColor"))
                .cornerRadius(6)
                
                
                
                
            }
            HStack(spacing:5){
                // Every X Seconds
                HStack(spacing: 0) {
                    Text("Every")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
                    Picker("", selection: $practiceTimerState.stepEverySeconds) {
                        ForEach(1...120, id: \.self) { sec in
                            Text("\(sec)")
                                .tag(sec)
                                .foregroundStyle(Color("textPrimaryColor"))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()
                    
                    Text("sec")
                        .font(.custom("MiSansLatin-Regular", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                        .frame(width: 40, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .background(Color("backgroundSecondaryColor"))
                .cornerRadius(6)

                // Increment BPM
                HStack(spacing: 0) {
                    Text("By")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
                    Picker("", selection: $practiceTimerState.stepIncrement) {
                        ForEach(-30..<0, id: \.self) { change in
                            Text("\(change)")
                                .tag(change)
                                .foregroundStyle(Color("textPrimaryColor"))
                        }
                        ForEach(1...30, id: \.self) { change in
                            Text("+\(change)")
                                .tag(change)
                                .foregroundStyle(Color("textPrimaryColor"))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()
                    
                    Text("BPM")
                        .font(.custom("MiSansLatin-Regular", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                        .frame(width: 40, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .background(Color("backgroundSecondaryColor"))
                .cornerRadius(6)
            }
            
            
        }
        .cornerRadius(15)
    }
    
    // 小节模式设置视图
    private var barSetupView: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                // From BPM
                HStack(spacing: 0) {
                    Text("From")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
                    
                    Picker("", selection: $practiceTimerState.stepFromBPM) {
                        ForEach(30...240, id: \.self) { bpm in
                            Text("\(bpm)")
                                .tag(bpm)
                                .foregroundStyle(Color("textPrimaryColor"))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()
                    
                    Text("BPM")
                        .font(.custom("MiSansLatin-Regular", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                        .frame(width: 40, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .background(Color("backgroundSecondaryColor"))
                .cornerRadius(6)
                
                // To BPM
                HStack(spacing: 0) {
                        Text("To")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
                    
                    Picker("", selection: $practiceTimerState.stepToBPM) {
                        ForEach(30...240, id: \.self) { bpm in
                            Text("\(bpm)")
                                .tag(bpm)
                                .foregroundStyle(Color("textPrimaryColor"))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()
                    
                    Text("BPM")
                        .font(.custom("MiSansLatin-Regular", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                        .frame(width: 40, alignment: .leading)
                        
                }
                .frame(maxWidth: .infinity)
                .background(Color("backgroundSecondaryColor"))
                .cornerRadius(6)
                
                
                
                
            }
            
            HStack(spacing: 5){
                // Every X Bars
                    HStack(spacing: 0) {
                        Text("Every")
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(Color("textPrimaryColor")) 

                        Picker("", selection: $practiceTimerState.stepEveryBars) {
                            ForEach(1...16, id: \.self) { bars in
                                Text("\(bars)")
                                    .tag(bars)
                                    .foregroundStyle(Color("textPrimaryColor"))
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()
                        
                        Text("bar")
                            .font(.custom("MiSansLatin-Regular", size: 14))
                            .foregroundColor(Color("textSecondaryColor"))
                            .frame(width: 40, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color("backgroundSecondaryColor"))
                    .cornerRadius(6)
                
                
                // Increment BPM
                
                    
                    
                HStack(spacing: 0) {
                    Text("By")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
                    Picker("", selection: $practiceTimerState.stepIncrement) {
                        ForEach(-30..<0, id: \.self) { change in
                            Text("\(change)")
                                .tag(change)
                                .foregroundStyle(Color("textPrimaryColor"))
                        }
                        ForEach(1...30, id: \.self) { change in
                            Text("+\(change)")
                                .tag(change)
                                .foregroundStyle(Color("textPrimaryColor"))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()
                    
                    Text("BPM")
                        .font(.custom("MiSansLatin-Regular", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                        .frame(width: 40, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .background(Color("backgroundSecondaryColor"))
                .cornerRadius(6)
                
            }
            
        }
        .cornerRadius(15)
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
                    
                    VStack {
                        // 当前BPM值显示
                        Text("\(practiceTimerState.currentBPM)")
                            .font(.custom("MiSansLatin-Semibold", size: 40))
                            .foregroundColor(Color("textPrimaryColor"))
                        
                        // 显示剩余多少小节/秒后变化BPM
                        if practiceTimerState.timerStatus != .completed {
                            if practiceTimerState.activeTimerType == .time {
                                let remainingSeconds = practiceTimerState.getRemainingSecondsToNextUpdate()
                                let nextBPM = practiceTimerState.getNextBPM()
                                
                                Text("\(remainingSeconds) sec → \(nextBPM) BPM")
                                    .font(.custom("MiSansLatin-Semibold", size: 18))
                                    .foregroundColor(Color("textPrimaryColor"))
                            } else {
                                let remainingBars = practiceTimerState.getRemainingBarsToNextUpdate()
                                let nextBPM = practiceTimerState.getNextBPM()
                                
                                Text("\(remainingBars) bars → \(nextBPM) BPM")
                                    .font(.custom("MiSansLatin-Semibold", size: 18))
                                    .foregroundColor(Color("textPrimaryColor"))
                            }
                        }
                        
                        VStack{
                          // From到To信息
                            Text("\(practiceTimerState.stepFromBPM) → \(practiceTimerState.stepToBPM) BPM")
                                .font(.custom("MiSansLatin-Regular", size: 14))
                                .foregroundColor(Color("textSecondaryColor"))
                        }

                        // 模式和进度信息
                        HStack {
                            // 更新间隔信息
                            if practiceTimerState.activeTimerType == .time {
                                Text("Every \(practiceTimerState.stepEverySeconds) seconds")
                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                    .foregroundColor(Color("textSecondaryColor"))
                                Text("Increase \(practiceTimerState.stepIncrement) BPM" )
                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                    .foregroundColor(Color("textSecondaryColor"))
                            } else {
                                Text("Every \(practiceTimerState.stepEveryBars) bars")
                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                    .foregroundColor(Color("textSecondaryColor"))
                                Text("Increase \(practiceTimerState.stepIncrement) BPM")
                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                    .foregroundColor(Color("textSecondaryColor"))
                            }
                        }
                        
                        // 显示剩余小节或时间
                        if practiceTimerState.timerStatus != .completed {
                            if practiceTimerState.activeTimerType == .time {
                                let remainingSeconds = practiceTimerState.getRemainingSecondsToNextUpdate()
                                
                                Text("Remaining: \(remainingSeconds) sec")
                                    .font(.custom("MiSansLatin-Regular", size: 14))
                                    .foregroundColor(Color("textSecondaryColor"))
                                    
                            } else {
                                let remainingBars = practiceTimerState.getRemainingBarsToNextUpdate()
                                
                                Text("Remaining: \(remainingBars) bars")
                                    .font(.custom("MiSansLatin-Regular", size: 14))
                                    .foregroundColor(Color("textSecondaryColor"))
                                    
                            }
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .trim(from: 0, to: practiceTimerState.stepCycleProgress)
                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                        .foregroundColor(theme.primaryColor)
                        .rotationEffect(Angle(degrees: -90.0))
                        .animation(practiceTimerState.isCompletingCycle ? .linear(duration: 0.5) : .linear(duration: 1.0), value: practiceTimerState.stepCycleProgress)
                        .frame(width: geometry.size.height, height: geometry.size.width)
                )   
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(lineWidth/2)
            
            Spacer()
            
            // 控制按钮
            HStack(spacing: 15) {
                // 暂停/继续按钮
                Button(action: {
                    practiceTimerState.togglePause()
                }) {
                    HStack(spacing: 5) {
                        Image(practiceTimerState.timerStatus == .paused ? "icon-play" : "icon-pause")
                            .renderingMode(.template)   
                            .resizable()
                            .frame(width: 20, height: 20)   
                            
                        Text(practiceTimerState.timerStatus == .paused ? "继续" : "暂停")
                            .font(.custom("MiSansLatin-Semibold", size: 17))
                    }
                    .foregroundColor(.white)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .background(theme.primaryColor)
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .contentShape(Rectangle())
                .disabled(practiceTimerState.timerStatus == .completed)
                .opacity(practiceTimerState.timerStatus == .completed ? 0.5 : 1)
                
                // 停止按钮
                Button(action: {
                    practiceTimerState.stopTimer()
                }) {
                    HStack(spacing: 5) {
                        Image("icon-stop")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)   
                            
                        Text("停止")
                            .font(.custom("MiSansLatin-Semibold", size: 17))
                    }   
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red.opacity(0.8))
                }
                .contentShape(Rectangle())
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("backgroundPrimaryColor"))
    }
}

#Preview {
    let metronomeState = MetronomeState()
    let timerState = PracticeTimerState()
    timerState.setMetronomeState(metronomeState)
    
    return ProgressivePracticeView()
        .environmentObject(timerState)
        .environmentObject(metronomeState)
}

