//
//  StreaksDayStatsView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/27.
//

import SwiftUI
import CoreData

struct StreaksDayStatsView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var practiceManager: CoreDataPracticeManager
    
    // 状态变量
    @State private var weeklyData: [PracticeDataPoint] = []
    @State private var currentWeekStartDate: Date = Date()
    
    // 每日目标练习时间（分钟）
    private let dailyTargetMinutes: Double = 60.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 内容区域 - 圆环日历
            VStack(spacing: 20) {
                HStack {
                    // 提示文字
                    VStack(alignment: .leading, spacing: 0){
                        Text("Good Job!")
                            .font(.custom("MiSansLatin-Semibold", size: 20))
                            .foregroundColor(Color("textPrimaryColor"))
                        Text("Track your practice to hit a streak.")
                            .font(.custom("MiSansLatin-Regular", size: 14))
                            .foregroundColor(Color("textSecondaryColor"))
                    }
                        
                    Spacer()
                    Button(action: {
                        // 分享功能
                    }) {
                        Image("icon-ellipsis")
                            .renderingMode(.template)
                            .foregroundColor(Color("textSecondaryColor"))
                    }
                }


                VStack(spacing: 8){
                    // 星期几指示器
                    HStack(spacing: 12) {
                        ForEach(getWeekdaySymbols(), id: \.self) { weekday in
                            Text(weekday)
                                .font(.custom("MiSansLatin-Regular", size: 12))
                                .foregroundColor( Color("textSecondaryColor"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // 圆环进度视图
                    HStack(spacing: 12) {
                        ForEach(0..<weeklyData.count, id: \.self) { index in
                            let dataPoint = weeklyData[index]
                            let isToday = isDateToday(dataPoint.date)
                            let isFutureDay = isDateInFuture(dataPoint.date)
                            
                            StreakDayCircleView(
                                progress: min(1.0, dataPoint.duration / dailyTargetMinutes),
                                isToday: isToday,
                                isFutureDay: isFutureDay,
                                isCompleted: dataPoint.duration >= dailyTargetMinutes
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(20)
            .background(Color("backgroundSecondaryColor"))
            .cornerRadius(16)
        }
        .onAppear {
            // 计算当前周的周一日期
            calculateCurrentWeekMonday()
            // 加载数据
            loadWeeklyData()
        }
    }
    
    // 计算当前日期所在周的周一
    private func calculateCurrentWeekMonday() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 设置周一为每周第一天
        
        let today = Date()
        let weekdayComponent = calendar.component(.weekday, from: today)
        // 计算需要减去的天数以获得周一
        let daysToSubtract = (weekdayComponent + 5) % 7 // 把周几转换为距离周一的天数
        
        if let monday = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) {
            currentWeekStartDate = monday
        }
    }
    
    // 加载周视图数据
    private func loadWeeklyData() {
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: currentWeekStartDate) else {
            weeklyData = []
            return
        }
        
        // 使用练习管理器获取一周的数据
        weeklyData = practiceManager.getPracticeDataForDateRange(from: currentWeekStartDate, to: endDate)
    }
    
    // 获取星期几缩写
    private func getWeekdaySymbols() -> [String] {
        let calendar = Calendar.current
        let weekdaySymbols = calendar.shortWeekdaySymbols
        // 调整顺序以周一为第一天
        return Array(weekdaySymbols[1..<weekdaySymbols.count] + [weekdaySymbols[0]])
    }
    
    // 判断日期是否为今天
    private func isDateToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    // 判断日期是否在未来
    private func isDateInFuture(_ date: Date) -> Bool {
        return date > Date()
    }
}

// 单日圆环进度视图
struct StreakDayCircleView: View {
    @Environment(\.metronomeTheme) var theme
    
    let progress: Double // 0.0-1.0
    let isToday: Bool
    let isFutureDay: Bool
    let isCompleted: Bool
    let lineWidth: CGFloat = 3
    
    var body: some View {
        
        GeometryReader { geometry in
            ZStack {
            
                let size = geometry.size.width - (lineWidth )
                // 底层圆环 - 灰色背景
                Circle()
                    .stroke(
                        isFutureDay ? .accent.opacity(0.1) : .accent.opacity(0.1),
                        lineWidth: lineWidth
                    )
                    .frame(width: size, height: size)
                
            
                // 进度圆环
                if !isFutureDay {
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            isToday ? .accent : .accent,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: size, height: size)
                }
                
                // 完成标记
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(isToday ? .accent : .accent)
                        .font(.system(size: 16, weight: .bold))
                }
            }   
            .frame(maxWidth: .infinity, maxHeight: .infinity)    
            
        }
        .aspectRatio(1, contentMode: .fit)
        
    }
}

