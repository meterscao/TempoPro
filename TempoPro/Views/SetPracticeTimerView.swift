//
//  SetTimerView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/13.
//

import SwiftUI

struct SetPracticeTimerView: View {
    @EnvironmentObject var practiceTimerState: PracticeTimerState
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var selectedTimerType : String = "time" // time or bar
    
    init(){
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if !practiceTimerState.isTimerRunning {
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
                ToolbarItem(placement:.principal) {
                    Picker("", selection: $selectedTimerType) {
                        Text("By Time").tag("time")
                        Text("By Bar").tag("bar")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
            .background(theme.backgroundColor)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
        }
    }
    
    // 设置视图
    private var setupView: some View {
        VStack(spacing: 20) {
            Spacer()
            
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
            
            Spacer()
            
            // 循环选项
            Toggle(isOn: $practiceTimerState.isLoopEnabled) {
                Text("Loop")
                    .font(.custom("MiSansLatin-Regular", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
            }
            
            // 开始按钮
            Button(action: {
                practiceTimerState.startTimer()
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
            .disabled(practiceTimerState.totalSeconds == 0)
            .opacity(practiceTimerState.totalSeconds == 0 ? 0.5 : 1)
        }
        .padding(20)
        .frame(maxWidth:.infinity,maxHeight:.infinity, alignment: .top)
        .background(Color("backgroundPrimaryColor"))
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
                    if practiceTimerState.isTimerCompleted {
                        practiceTimerState.elapsedSeconds = 0
                        practiceTimerState.isTimerCompleted = false
                        practiceTimerState.startTimerTick()
                    } else {
                        practiceTimerState.togglePause()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(practiceTimerState.isTimerCompleted ? "icon-replay" : (practiceTimerState.timer == nil ? "icon-play" : "icon-pause"))
                            .renderingMode(.template)   
                            .resizable()
                            .frame(width: 20, height: 20)   
                            
                        Text(practiceTimerState.isTimerCompleted ? "Replay" : (practiceTimerState.timer == nil ? "Continue" : "Pause"))
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
}

