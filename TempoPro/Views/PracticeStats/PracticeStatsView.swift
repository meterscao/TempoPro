//
//  StatsView.swift
//  TempoPro
//
//  Created by Meters on 6/3/2025.
//

import SwiftUI

struct PracticeStatsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var practiceManager: CoreDataPracticeManager
    
    // 状态变量用于保存统计数据
    @State private var dayStreak = 0
    @State private var daysThisMonth = 0
    @State private var totalHours = 0.0
    @State private var weeklyData: [(String, Double)] = []
    @State private var monthlyData: [[Double]] = []
    @State private var mostPracticedTempo = ""
    @State private var longestSession = ""
    
    // 添加选中的周视图日期索引
    @State private var selectedWeekdayIndex: Int? = nil
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.custom("MiSansLatin-Regular", size: 20))
                                .foregroundColor(theme.backgroundColor)
                        }
                        
                        Spacer()
                        
                        Text("PRACTICE STATS")
                            .font(.custom("MiSansLatin-Semibold", size: 24))
                            .foregroundColor(theme.backgroundColor)
                        
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.custom("MiSansLatin-Regular", size: 20))
                                .foregroundColor(theme.backgroundColor)
                        }
                    }
                    
                    // Stats Summary
                    HStack(spacing: 10) {
                        StatsSummaryCard(value: "\(dayStreak)", label: "STREAK DAYS")
                        StatsSummaryCard(value: "\(daysThisMonth)", label: "DAYS THIS MONTH")
                        StatsSummaryCard(value: String(format: "%.1f", totalHours), label: "TOTAL HOURS")
                    }
                    
                    // Weekly Streak - 替换为新的组件
                    WeeklyStatsView()
                    
                    // Monthly Heatmap
                    MonthlyHeatmapView()
                    
                    // Performance Insights
                    VStack(alignment: .leading, spacing: 18) {
                        Text("INSIGHTS")
                            .font(.custom("MiSansLatin-Semibold", size: 20))
                            .foregroundColor(theme.primaryColor)
                        
                        VStack(spacing: 22) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("MOST PRACTICED TEMPO")
                                        .font(.custom("MiSansLatin-Regular", size: 12))
                                        .foregroundColor(theme.primaryColor.opacity(0.8))
                                    
                                    Text(mostPracticedTempo)
                                        .font(.custom("MiSansLatin-Semibold", size: 18))
                                        .foregroundColor(theme.beatHightColor)
                                }
                                
                                Spacer()
                                
                                ZStack {
                                    Circle()
                                        .fill(theme.primaryColor.opacity(0.6))
                                        .frame(width: 48, height: 48)
                                    
                                    Image(systemName: "waveform.path")
                                        .font(.custom("MiSansLatin-Regular", size: 16))
                                        .foregroundColor(theme.backgroundColor)
                                }
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("LONGEST SESSION")
                                        .font(.custom("MiSansLatin-Regular", size: 12))
                                        .foregroundColor(theme.primaryColor.opacity(0.8))
                                    
                                    Text(longestSession)
                                        .font(.custom("MiSansLatin-Semibold", size: 18))
                                        .foregroundColor(theme.beatHightColor)
                                }
                                
                                Spacer()
                                
                                ZStack {
                                    Circle()
                                        .fill(theme.primaryColor.opacity(0.6))
                                        .frame(width: 48, height: 48)
                                    
                                    Image(systemName: "timer")
                                        .font(.custom("MiSansLatin-Regular", size: 16))
                                        .foregroundColor(theme.backgroundColor)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(theme.backgroundColor)
                    .cornerRadius(16)
                    
                    // Share Stats Button
                    Button(action: {}) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .foregroundColor(theme.backgroundColor)
                            
                            Text("SHARE PROGRESS")
                                .font(.custom("MiSansLatin-Semibold", size: 16))
                                .foregroundColor(theme.backgroundColor)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(theme.primaryColor.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                Image("bg-noise")
                    .resizable(resizingMode: .tile)
                    .opacity(0.06)
                    .ignoresSafeArea()
            )
            .background(theme.primaryColor.ignoresSafeArea())
            .onAppear {
                // 加载数据
                loadPracticeData()
            }
        }
    }
    
    // 加载练习数据
    private func loadPracticeData() {
        // 连续练习天数
        dayStreak = practiceManager.getCurrentStreak()
        
        // 当月练习天数
        daysThisMonth = practiceManager.getPracticeDaysInCurrentMonth()
        
        // 总练习时间
        totalHours = practiceManager.getTotalPracticeHours()
        
        // 最常练习的速度
        mostPracticedTempo = practiceManager.getMostPracticedTempo()
        
        // 最长练习会话
        let longestSessionInfo = practiceManager.getLongestSession()
        longestSession = longestSessionInfo.date
    }
}

// 新增周视图组件
struct WeeklyStatsView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var practiceManager: CoreDataPracticeManager
    
    // 状态变量
    @State private var weeklyData: [(String, Double)] = []
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
                                let barColor = day.1 > 0 ? 
                                    (isSelected ? theme.primaryColor : theme.beatHightColor) : 
                                    (isSelected ? theme.primaryColor.opacity(0.2) : theme.beatHightColor.opacity(0.1))
                                
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
                                        .foregroundColor(isSelected ? theme.primaryColor : theme.beatHightColor)
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
                                
                                // 显示星期几
                                Text(selectedDay.0)
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
                                // 找出最小和最大的非零值
                                let nonZeroValues = weeklyData.map { $0.1 }.filter { $0 > 0 }
                                let minVal = nonZeroValues.min() ?? 0
                                let maxVal = nonZeroValues.max() ?? 0
                                
                                if minVal > 0 {
                                    Text("\(Int(minVal))分钟")
                                        .font(.custom("MiSansLatin-Regular", size: 12))
                                        .foregroundColor(theme.primaryColor.opacity(0.9))
                                } else {
                                    Text("0分钟")
                                        .font(.custom("MiSansLatin-Regular", size: 12))
                                        .foregroundColor(theme.primaryColor.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                if maxVal > 0 {
                                    // 使用Manager格式化时间
                                    Text(practiceManager.formatDuration(minutes: maxVal))
                                        .font(.custom("MiSansLatin-Regular", size: 12))
                                        .foregroundColor(theme.primaryColor.opacity(0.9))
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
        // 重置选中状态
        selectedWeekdayIndex = nil
    }
}

struct StatsSummaryCard: View {
    @Environment(\.metronomeTheme) var theme
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.custom("MiSansLatin-Semibold", size: 32))
                .foregroundColor(theme.beatHightColor)
            
            Text(label)
                .font(.custom("MiSansLatin-Regular", size: 11))
                .foregroundColor(theme.primaryColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.backgroundColor)
        .cornerRadius(12)
    }
}

struct NavigationButton: View {
    @Environment(\.metronomeTheme) var theme
    let icon: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? theme.primaryColor.opacity(0.8) : theme.primaryColor.opacity(0.2))
                .frame(width: 48, height: 48)
            
            Image(systemName: icon)
                .foregroundColor(isActive ? theme.backgroundColor : theme.backgroundColor.opacity(0.8))
        }
    }
}

struct PracticeStatsView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeStatsView()
    }
}
