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
    @State private var weeklyData: [(String, Double)] = []
    @State private var weeklyDates: [String] = []  // 新增：存储对应的日期字符串
    @State private var selectedWeekdayIndex: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("THIS WEEK")
                    .font(.custom("MiSansLatin-Semibold", size: 20))
                    .foregroundColor(theme.primaryColor)
                
                Spacer()
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            .padding(.bottom, 8)
            
            // Bar chart - expanding to fill width
            GeometryReader { geometry in
                VStack(spacing: 16) {
                    if weeklyData.isEmpty {
                        Text("No practice data for this week")
                            .foregroundColor(theme.primaryColor.opacity(0.7))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(0..<weeklyData.count, id: \.self) { index in
                                let day = weeklyData[index]
                                let barWidth = (geometry.size.width - CGFloat(weeklyData.count - 1) * 8) / CGFloat(weeklyData.count)
                                
                                // 计算合理的高度值，使图表更美观
                                let maxHeight: CGFloat = 120
                                let maxMinutes = weeklyData.map { $0.1 }.max() ?? 1
                                let height = max(15, CGFloat(day.1) / CGFloat(maxMinutes) * maxHeight)
                                
                                // 根据选中状态设置颜色
                                let isSelected = selectedWeekdayIndex == index
                                let barColor = isSelected ? theme.primaryColor : (
                                    day.1 > 0 ? 
                                    theme.beatBarColor : 
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
                                    
                                    Text(day.0)
                                        .font(.custom("MiSansLatin-Regular", size: 12))
                                        .foregroundColor(isSelected ? theme.primaryColor : theme.beatBarColor)
                                }
                                .onTapGesture {
                                    // 点击处理逻辑
                                    if selectedWeekdayIndex == index {
                                        // 再次点击取消选择
                                        selectedWeekdayIndex = nil
                                    } else {
                                        // 选中当前日期
                                        selectedWeekdayIndex = index
                                    }
                                }
                                
                                if index < weeklyData.count - 1 {
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        
                        // 统计信息展示 - 根据选中状态变化
                        HStack {
                            if let selectedIndex = selectedWeekdayIndex, selectedIndex < weeklyData.count {
                                // 显示选中日期的信息
                                let selectedDay = weeklyData[selectedIndex]
                                
                                // 显示日期而非星期几
                                Text(weeklyDates[selectedIndex])
                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                    .foregroundColor(theme.primaryColor)
                                
                                Spacer()
                                
                                // 格式化练习时间
                                if selectedDay.1 > 0 {
                                    Text(practiceManager.formatDuration(minutes: selectedDay.1))
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
                                let practiceDays = weeklyData.filter { $0.1 > 0 }.count
                                // 计算总练习时间
                                let totalMinutes = weeklyData.map { $0.1 }.reduce(0, +)
                                
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
                }
                .padding(.top, 20)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 200, alignment: .bottom)
        }
        .padding(20)
        .background(theme.backgroundColor)
        .cornerRadius(16)
        .onAppear {
            // 加载周视图数据
            loadWeeklyData()
        }
    }
    
    // 加载周视图数据
    private func loadWeeklyData() {
        // 获取本周数据
        weeklyData = practiceManager.getCurrentWeekPracticeData()
        
        // 获取对应的日期字符串 (如: "3月7日"，"3月8日"等)
        weeklyDates = getFormattedDates()
        
        // 重置选中状态
        selectedWeekdayIndex = nil
    }
    
    // 获取格式化的日期字符串
    private func getFormattedDates() -> [String] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1 // 从周日开始算
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
            return Array(repeating: "", count: 7)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "M月d日"
        
        var dates: [String] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(dateFormatter.string(from: date))
            } else {
                dates.append("")
            }
        }
        
        return dates
    }
}
