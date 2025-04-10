//
//  StepTimerView.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/3/23.
//

import SwiftUI

struct ProgressivePracticeView: View {
   
   @EnvironmentObject var practiceViewModel: PracticeViewModel
   @Environment(\.metronomeTheme) var theme
   @Environment(\.dismiss) var dismiss

   @State private var selectedTimerType: String = "time" // time or bar
   @State private var showCannotStartAlert: Bool = false
   
   // BPM设置状态
   @State private var startBPM: Int = 60
   @State private var targetBPM: Int = 120
   @State private var stepBPM: Int = 5
   @State private var timeInterval: Int = 60 // 每60秒变化一次
   @State private var barInterval: Int = 4   // 每4小节变化一次
   
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
               
               if(practiceViewModel.practiceStatus == .standby) {
                   ToolbarItem(placement: .principal) {
                       Picker("", selection: $selectedTimerType) {
                           Text("By Time").tag("time")
                           Text("By Bar").tag("bar")
                       }
                       .pickerStyle(.segmented)
                       .frame(width: 200)
                       .onChange(of: selectedTimerType) { newValue in
                           let countdownType: CountdownType = newValue == "time" ? .time : .bar
                           practiceViewModel.updateCountdownType(countdownType)
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
           // 初始化选择类型
           selectedTimerType = practiceViewModel.countdownType == .time ? "time" : "bar"
           
           // 从ViewModel同步设置
           startBPM = practiceViewModel.startBPM
           targetBPM = practiceViewModel.targetBPM
           stepBPM = practiceViewModel.stepBPM
           
           // 确保设置为渐进式模式
           let countdownType = selectedTimerType == "time" ? CountdownType.time : CountdownType.bar
           practiceViewModel.setupProgressiveMode(
               startBPM: startBPM,
               targetBPM: targetBPM, 
               stepBPM: stepBPM,
               countdownType: countdownType
           )
       }
   }
   
   // 验证设置是否有效
   private var isSettingValid: Bool {
       return startBPM != targetBPM
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
               if isSettingValid {
                   // 更新渐进模式设置
                   let countdownType = selectedTimerType == "time" ? CountdownType.time : CountdownType.bar
                   
                   practiceViewModel.updateStartBPM(startBPM)
                   practiceViewModel.updateTargetBPM(targetBPM)
                   practiceViewModel.updateStepBPM(stepBPM)
                   
                   if countdownType == .time {
                       practiceViewModel.updateTargetTime(timeInterval)
                   } else {
                       practiceViewModel.updateTargetBars(barInterval)
                   }
                   
                   // 设置模式并开始练习
                   practiceViewModel.setupProgressiveMode(
                       startBPM: startBPM,
                       targetBPM: targetBPM,
                       stepBPM: stepBPM,
                       countdownType: countdownType
                   )
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
               .foregroundColor(isSettingValid ? Color("textPrimaryColor") : Color("textSecondaryColor").opacity(0.5))
               .frame(height: 52)
               .frame(maxWidth: .infinity)
               .background(
                   RoundedRectangle(cornerRadius: 12)
                       .fill(isSettingValid ? .green.opacity(0.2) : Color("backgroundSecondaryColor").opacity(0.3))
               )
           }
           .disabled(!isSettingValid)
           .alert(isPresented: $showCannotStartAlert) {
               Alert(
                   title: Text("无法开始渐进练习"),
                   message: Text("请确保起始BPM和目标BPM不同"),
                   dismissButton: .default(Text("我知道了"))
               )
           }
       }
       .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
       .background(Color("backgroundPrimaryColor"))
   }
   
   // 时间模式设置视图
   private var timeSetupView: some View {
       VStack(spacing: 3) {
           HStack(spacing: 3) {
               // From BPM
               HStack(spacing: 0) {
                   Text("From")
                       .font(.custom("MiSansLatin-Regular", size: 16))
                       .foregroundColor(Color("textPrimaryColor"))
                   Picker("", selection: $startBPM) {
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
               .cornerRadius(4)
               
               // To BPM
               HStack(spacing: 0) {
                   Text("To")
                   .font(.custom("MiSansLatin-Regular", size: 16))
                   .foregroundColor(Color("textPrimaryColor"))

                   Picker("", selection: $targetBPM) {
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
               .cornerRadius(4)
           }
           HStack(spacing:3){
               // Every X Seconds
               HStack(spacing: 0) {
                   Text("Every")
                   .font(.custom("MiSansLatin-Regular", size: 16))
                   .foregroundColor(Color("textPrimaryColor"))
                   Picker("", selection: $timeInterval) {
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
               .cornerRadius(4)

               // Increment BPM
               HStack(spacing: 0) {
                   Text("By")
                   .font(.custom("MiSansLatin-Regular", size: 16))
                   .foregroundColor(Color("textPrimaryColor"))
                   Picker("", selection: $stepBPM) {
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
               .cornerRadius(4)
           }
       }
       .cornerRadius(15)
   }
   
   // 小节模式设置视图
   private var barSetupView: some View {
       VStack(spacing: 3) {
           HStack(spacing: 3) {
               // From BPM
               HStack(spacing: 0) {
                   Text("From")
                   .font(.custom("MiSansLatin-Regular", size: 16))
                   .foregroundColor(Color("textPrimaryColor"))
                   
                   Picker("", selection: $startBPM) {
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
               .cornerRadius(4)
               
               // To BPM
               HStack(spacing: 0) {
                       Text("To")
                   .font(.custom("MiSansLatin-Regular", size: 16))
                   .foregroundColor(Color("textPrimaryColor"))
                   
                   Picker("", selection: $targetBPM) {
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
               .cornerRadius(4)
           }
           
           HStack(spacing: 3){
               // Every X Bars
                   HStack(spacing: 0) {
                       Text("Every")
                       .font(.custom("MiSansLatin-Regular", size: 16))
                       .foregroundColor(Color("textPrimaryColor")) 

                       Picker("", selection: $barInterval) {
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
                   .cornerRadius(4)
               
               // Increment BPM
               HStack(spacing: 0) {
                   Text("By")
                   .font(.custom("MiSansLatin-Regular", size: 16))
                   .foregroundColor(Color("textPrimaryColor"))
                   Picker("", selection: $stepBPM) {
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
               .cornerRadius(4)
           }
       }
       .cornerRadius(15)
   }
   
   // 计时视图
   private var timerView: some View {
       let lineWidth: CGFloat = 14
       let progress = practiceViewModel.countdownType == .time ? practiceViewModel.timeProgress : practiceViewModel.barProgress

       return VStack(spacing: 20) {
           GeometryReader { geometry in
               ZStack {
                   RoundedRectangle(cornerRadius: 40)
                       .stroke(lineWidth: lineWidth)
                       .foregroundColor(Color("AccentColor").opacity(0.3))
                   
                   VStack {
                       // 当前BPM值显示
                       Text("\(practiceViewModel.currentBPM)")
                           .font(.custom("MiSansLatin-Semibold", size: 40))
                           .foregroundColor(Color("textPrimaryColor"))
                       
                       // 显示剩余多少小节/秒后变化BPM
                       if practiceViewModel.practiceStatus != .completed {
                           if practiceViewModel.countdownType == .time {
                               Text("\(practiceViewModel.remainingTime) sec → \(practiceViewModel.nextStageBPM) BPM")
                                   .font(.custom("MiSansLatin-Semibold", size: 18))
                                   .foregroundColor(Color("textPrimaryColor"))
                           } else {
                               Text("\(practiceViewModel.remainingBars) bars → \(practiceViewModel.nextStageBPM) BPM")
                                   .font(.custom("MiSansLatin-Semibold", size: 18))
                                   .foregroundColor(Color("textPrimaryColor"))
                           }
                       }
                       
                       VStack{
                         // From到To信息
                           Text("\(practiceViewModel.startBPM) → \(practiceViewModel.targetBPM) BPM")
                               .font(.custom("MiSansLatin-Regular", size: 14))
                               .foregroundColor(Color("textSecondaryColor"))
                       }

                       // 模式和进度信息
                       HStack {
                           // 更新间隔信息
                           if practiceViewModel.countdownType == .time {
                               Text("Every \(practiceViewModel.targetTime) seconds")
                                   .font(.custom("MiSansLatin-Regular", size: 12))
                                   .foregroundColor(Color("textSecondaryColor"))
                               Text("Change \(practiceViewModel.stepBPM) BPM" )
                                   .font(.custom("MiSansLatin-Regular", size: 12))
                                   .foregroundColor(Color("textSecondaryColor"))
                           } else {
                               Text("Every \(practiceViewModel.targetBars) bars")
                                   .font(.custom("MiSansLatin-Regular", size: 12))
                                   .foregroundColor(Color("textSecondaryColor"))
                               Text("Change \(practiceViewModel.stepBPM) BPM")
                                   .font(.custom("MiSansLatin-Regular", size: 12))
                                   .foregroundColor(Color("textSecondaryColor"))
                           }
                       }
                       
                       // 显示当前循环
                       Text(practiceViewModel.getCycleInfoText())
                           .font(.custom("MiSansLatin-Regular", size: 14))
                           .foregroundColor(Color("textSecondaryColor"))
                   }
               }
               .overlay(
                   RoundedRectangle(cornerRadius: 40)
                       .trim(from: 0, to: progress)
                       .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                       .foregroundColor(Color("AccentColor"))
                       .rotationEffect(Angle(degrees: -90.0))
                       .animation(.linear(duration: 0.5), value: progress)
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
                           .font(.custom("MiSansLatin-Semibold", size: 17))
                   }
                   .foregroundColor(.white)
                   .frame(height: 52)
                   .frame(maxWidth: .infinity)
                   .background(Color("AccentColor"))
               }
               .clipShape(RoundedRectangle(cornerRadius: 15))
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
                           
                       Text(practiceViewModel.practiceStatus == .completed ? "Cancel" : "Stop")
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


