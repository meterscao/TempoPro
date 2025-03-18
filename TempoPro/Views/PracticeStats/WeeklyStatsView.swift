//
//  WeeklyStatsView.swift
//  TempoPro
//
//  Created by Meters on 7/3/2025.
//
import SwiftUI

// 新增周视图组件
struct WeeklyStatsView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var practiceManager: CoreDataPracticeManager
    
    // 状态变量
    @State private var weeklyData: [PracticeDataPoint] = []
    @State private var selectedWeekdayIndex: Int? = nil
    @State private var currentWeekStartDate: Date = Date()
    
    // 获取格式化的星期几和日期
    private var formattedWeekData: [(weekday: String, date: String, dataPoint: PracticeDataPoint)] {
        let calendar = Calendar.current
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let mondayFirstSymbols = Array(weekdaySymbols[1..<weekdaySymbols.count] + [weekdaySymbols[0]])
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "M月d日"
        
        return weeklyData.enumerated().map { index, dataPoint in
            return (
                weekday: mondayFirstSymbols[index],
                date: dateFormatter.string(from: dataPoint.date),
                dataPoint: dataPoint
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 0){
                HStack {
                Text(getWeekRangeText())
                    .font(.custom("MiSansLatin-Semibold", size: 20))
                    .foregroundColor(theme.primaryColor)
                
                Spacer()
                HStack(spacing: 16) {
                    Button(action: {
                        // 显示上一周
                        moveWeek(byDays: -7)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    Button(action: {
                        // 显示下一周
                        moveWeek(byDays: 7)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            
            
            // 统计信息展示 - 根据选中状态变化
            HStack {
                if let selectedIndex = selectedWeekdayIndex, selectedIndex < formattedWeekData.count {
                    // 显示选中日期的信息
                    let selectedItem = formattedWeekData[selectedIndex]
                    let dataPoint = selectedItem.dataPoint
                    
                    // 显示日期而非星期几
                    Text(selectedItem.date)
                        .font(.custom("MiSansLatin-Regular", size: 12))
                        .foregroundColor(theme.primaryColor)
                    
                    Spacer()
                    
                    // 显示会话数量
                    if dataPoint.sessionCount > 0 {
                        Text("\(dataPoint.sessionCount)次练习")
                            .font(.custom("MiSansLatin-Regular", size: 12))
                            .foregroundColor(theme.primaryColor.opacity(0.8))
                            .padding(.trailing, 8)
                    }
                    
                    // 格式化练习时间
                    if dataPoint.duration > 0 {
                        Text(practiceManager.formatDuration(minutes: dataPoint.duration))
                            .font(.custom("MiSansLatin-Regular", size: 12))
                            .foregroundColor(theme.primaryColor)
                    } else {
                        Text("无练习记录")
                            .font(.custom("MiSansLatin-Regular", size: 12))
                            .foregroundColor(theme.primaryColor.opacity(0.7))
                    }
                } else {
                    // 显示周统计信息
                    // 计算有练习记录的天数
                    let practiceDays = weeklyData.filter { !$0.isEmpty && !$0.disabled }.count
                    // 计算总练习时间
                    let totalMinutes = weeklyData.filter { !$0.disabled }.map { $0.duration }.reduce(0, +)
                    
                    // 显示有练习的天数
                    Text("\(practiceDays)天练习")
                        .font(.custom("MiSansLatin-Regular", size: 12))
                        .foregroundColor(theme.primaryColor.opacity(0.9))
                    
                    Spacer()
                    
                    // 显示总练习时间
                    if totalMinutes > 0 {
                        Text(practiceManager.formatDuration(minutes: totalMinutes))
                            .font(.custom("MiSansLatin-Regular", size: 12))
                            .foregroundColor(theme.primaryColor.opacity(0.9))
                    } else {
                        Text("无练习记录")
                            .font(.custom("MiSansLatin-Regular", size: 12))
                            .foregroundColor(theme.primaryColor.opacity(0.7))
                    }
                }
            }
            }
            // Bar chart - expanding to fill width
            GeometryReader { geometry in
                VStack(spacing: 16) {
                    if weeklyData.isEmpty {
                        Text("本周无练习数据")
                            .foregroundColor(theme.primaryColor.opacity(0.7))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(0..<formattedWeekData.count, id: \.self) { index in
                                let item = formattedWeekData[index]
                                let dataPoint = item.dataPoint
                                let barWidth = (geometry.size.width - CGFloat(formattedWeekData.count - 1) * 8) / CGFloat(formattedWeekData.count)
                                
                                // 计算合理的高度值，使图表更美观
                                let maxHeight: CGFloat = 120
                                let maxMinutes = weeklyData.map { $0.duration }.max() ?? 1
                                let height = max(15, CGFloat(dataPoint.duration) / CGFloat(maxMinutes) * maxHeight)
                                
                                // 根据选中状态和禁用状态设置颜色
                                let isSelected = selectedWeekdayIndex == index
                                let isDisabled = dataPoint.disabled
                                let barColor = isSelected ? theme.primaryColor : (
                                    dataPoint.duration > 0 ? 
                                    (isDisabled ? theme.beatBarColor.opacity(0.3) : theme.beatBarColor) : 
                                    theme.beatBarColor.opacity(0.1)
                                )
                                
                                VStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(barColor)
                                        .frame(width: barWidth, height: height)
                                        // 添加边框标识选中状态
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2)
                                        )
                                    
                                    Text(item.weekday)
                                        .font(.custom("MiSansLatin-Regular", size: 12))
                                        .foregroundColor(isSelected ? theme.primaryColor : 
                                                        (isDisabled ? theme.beatBarColor.opacity(0.5) : theme.beatBarColor))
                                }
                                .onTapGesture {
                                    // 仅当不是禁用状态时才可点击
                                    if !dataPoint.disabled {
                                        if selectedWeekdayIndex == index {
                                            selectedWeekdayIndex = nil
                                        } else {
                                            selectedWeekdayIndex = index
                                        }
                                    }
                                }
                                
                                if index < formattedWeekData.count - 1 {
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        
                        
                    }
                }
                .padding(.top, 20)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 200, alignment: .bottom)
        }
        .padding(20)
        .background(Color("backgroundSecondaryColor"))
        .cornerRadius(16)
        .onAppear {
            // 首先计算当前周的周一日期
            calculateCurrentWeekMonday()
            // 然后加载数据
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
    
    // 获取当前显示周的范围文本 (如: "3月7日-3月13日")
    private func getWeekRangeText() -> String {
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: currentWeekStartDate) else {
            return ""
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "M月d日"
        
        return "\(dateFormatter.string(from: currentWeekStartDate)) - \(dateFormatter.string(from: endDate))"
    }
    
    // 移动周数据显示
    private func moveWeek(byDays days: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: days, to: currentWeekStartDate) {
            currentWeekStartDate = newDate
            loadWeeklyData()
        }
    }
    
    // 加载周视图数据
    private func loadWeeklyData() {
        // 获取当前显示周的结束日期（周日）
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: currentWeekStartDate) else {
            weeklyData = []
            return
        }
        
        // 使用新的数据获取方法获取一周的数据
        weeklyData = practiceManager.getPracticeDataForDateRange(from: currentWeekStartDate, to: endDate)
        
        // 重置选中状态
        selectedWeekdayIndex = nil
    }
}
