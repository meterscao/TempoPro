//
//  MonthlyHeatmapView.swift
//  TempoPro
//
//  Created by Meters on 7/3/2025.
//
import SwiftUI

// 首先定义一个PreferenceKey来传递高度信息
private struct HeatmapHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 100
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 定义一个日期单元格数据结构
private struct DateCellInfo {
    let day: Int  // 日期
    let isVisible: Bool  // 是否显示
}



// 添加日期格式化扩展
extension Date {
    func formattedDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: self)
    }
}

// 月度热力图组件
struct MonthlyHeatmapView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var practiceManager: CoreDataPracticeManager
    
    // 状态变量
    @State private var currentYear: Int
    @State private var currentMonth: Int
    @State private var monthlyData: [[PracticeDataPoint]] = []
    @State private var selectedDay: PracticeDataPoint? = nil
    @State private var monthlyStatsData: (days: Int, totalMinutes: Double) = (0, 0)
    @State private var selectedDayFormattedDate: String = ""
    
    // 月份名称列表
    private let monthNames = ["January", "February", "March", "April", "May", "June", 
                              "July", "August", "September", "October", "November", "December"]
    
    // 星期几缩写
    private let weekdaySymbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    // 选中日期信息的计算属性
    private var selectedDayInfo: (dateString: String, hasPractice: Bool, sessionCount: Int, durationText: String) {
        guard let selected = selectedDay else {
            return ("", false, 0, "")
        }
        
        let hasPractice = selected.sessionCount > 0
        let durationText = hasPractice ? practiceManager.formatDuration(minutes: selected.duration) : "无练习记录"
        
        return (selectedDayFormattedDate, hasPractice, selected.sessionCount, durationText)
    }
    
    init() {
        // 初始化为当前年月
        let calendar = Calendar.current
        let today = Date()
        _currentYear = State(initialValue: calendar.component(.year, from: today))
        _currentMonth = State(initialValue: calendar.component(.month, from: today))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
           VStack(spacing: 0){
             // 月份导航栏
            HStack {
                Text("\(currentYear) \(monthNames[currentMonth-1])")
                    .font(.custom("MiSansLatin-Semibold", size: 20))
                    
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        // 切换到上一个月
                        moveMonth(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            
                    }
                    
                    Button(action: {
                        // 切换到下一个月
                        moveMonth(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            
                    }
                }
            }
            
            
            
            // 统计信息展示 - 使用预计算的信息
            VStack(alignment: .leading, spacing: 8) {
                if selectedDay != nil {
                    // 使用预先计算的信息
                    let info = selectedDayInfo
                    
                    HStack {
                        Text(info.dateString)
                            .font(.custom("MiSansLatin-Regular", size: 14))
                            
                        
                        Spacer()
                        
                        if info.hasPractice {
                            Text("\(info.sessionCount)次练习")
                                .font(.custom("MiSansLatin-Regular", size: 14))
                                .padding(.trailing, 8)
                            
                            Text(info.durationText)
                                .font(.custom("MiSansLatin-Regular", size: 14))
                                
                        } else {
                            Text("无练习记录")
                                .font(.custom("MiSansLatin-Regular", size: 14))
                        }
                    }
                } else {
                    // 显示月度统计信息 - 使用预计算的数据
                    HStack {
                        Text("本月共练习")
                            .font(.custom("MiSansLatin-Regular", size: 14))
                            
                        
                        Text("\(monthlyStatsData.days)天")
                            .font(.custom("MiSansLatin-Semibold", size: 14))
                            
                        
                        Spacer()
                        
                        Text(practiceManager.formatDuration(minutes: monthlyStatsData.totalMinutes))
                            .font(.custom("MiSansLatin-Regular", size: 14))
                            
                    }
                }
            }
           }
            
            
            // 热图主体
            VStack(spacing: 8) {
                ForEach(0..<monthlyData.count, id: \.self) { weekIndex in
                    let week = monthlyData[weekIndex]
                    
                    HStack(spacing: 8) {
                        ForEach(0..<week.count, id: \.self) { dayIndex in
                            let day = week[dayIndex]
                            
                            // 热图单元格
                            ZStack {
                                Rectangle()
                                    .fill(colorForPracticeTime(minutes: day.duration, isDisabled: day.disabled))
                                    .cornerRadius(8)
                                    .aspectRatio(1, contentMode: .fit)
                                
                                // 当天日期
                                // if !day.disabled {
                                //     let dayNumber = Calendar.current.component(.day, from: day.date)
                                //     Text("\(dayNumber)")
                                //         .font(.custom("MiSansLatin-Regular", size: 10))
                                //         .foregroundColor(day.duration > 60 ? Color.white : theme.primaryColor.opacity(0.7))
                                // }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedDay?.dateString == day.dateString ? theme.primaryColor : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                if !day.disabled {
                                    if selectedDay?.dateString == day.dateString {
                                        selectedDay = nil
                                    } else {
                                        selectDay(day)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // 星期几标题
            HStack(spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.custom("MiSansLatin-Regular", size: 12))
                        .foregroundColor(Color("textSecondaryColor"))
                        .frame(maxWidth: .infinity)
                }
            }
            
            
        }
        .padding(20)
        .background(Color("backgroundSecondaryColor"))
        .cornerRadius(16)
        .onAppear {
            loadMonthData()
        }
    }
    
    // 选择日期
    private func selectDay(_ day: PracticeDataPoint) {
        selectedDay = day
        // 预先格式化日期字符串
        selectedDayFormattedDate = day.date.formattedDateString()
    }
    
    // 切换月份
    private func moveMonth(by offset: Int) {
        var newMonth = currentMonth + offset
        var newYear = currentYear
        
        // 处理年份变更
        if newMonth < 1 {
            newMonth = 12
            newYear -= 1
        } else if newMonth > 12 {
            newMonth = 1
            newYear += 1
        }
        
        currentMonth = newMonth
        currentYear = newYear
        
        loadMonthData()
    }
    
    // 加载月度数据
    private func loadMonthData() {
        monthlyData = practiceManager.getPracticeDataByMonth(year: currentYear, month: currentMonth)
        selectedDay = nil
        
        // 预先计算月度统计
        calculateMonthStats()
    }
    
    // 计算月度统计数据
    private func calculateMonthStats() {
        // 计算有练习记录的天数
        let practiceDays = monthlyData.flatMap { $0 }
            .filter { !$0.isEmpty && !$0.disabled }
            .count
        
        // 计算总练习时间
        let totalMinutes = monthlyData.flatMap { $0 }
            .filter { !$0.disabled }
            .reduce(0) { $0 + $1.duration }
        
        monthlyStatsData = (practiceDays, totalMinutes)
    }
    
    // 根据练习时间获取显示颜色
    private func colorForPracticeTime(minutes: Double, isDisabled: Bool) -> Color {
        if isDisabled {
            return Color.clear
        }
        
        // 无数据使用非常浅的颜色
        if minutes == 0 {
            return theme.primaryColor.opacity(0.1)
        }
        
        // 根据练习时长设置不同深度的颜色
        if minutes < 15 {
            return theme.primaryColor.opacity(0.3)
        } else if minutes < 30 {
            return theme.primaryColor.opacity(0.6)
        } else if minutes < 60 {
            return theme.primaryColor.opacity(0.8)
        
        } else {
            return theme.primaryColor // 超过2小时使用完全不透明的颜色
        }
    }
}
