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
                    
                    // Weekly Streak
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("THIS WEEK")
                                .font(.custom("MiSansLatin-Semibold", size: 20))
                                .foregroundColor(theme.primaryColor)
                            
                            Spacer()
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
                                            let height = day.1 > 0 ? max(20, CGFloat(day.1) / CGFloat(maxMinutes) * maxHeight) : 0
                                            
                                            VStack(spacing: 8) {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(theme.beatHightColor)
                                                    .frame(width: barWidth, height: height)
                                                
                                                Text(day.0)
                                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                                    .foregroundColor(theme.beatHightColor)
                                            }
                                            
                                            if index < weeklyData.count - 1 {
                                                Spacer()
                                            }
                                        }
                                    }
                                    .frame(height: 120, alignment: .bottom)
                                    
                                    HStack {
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
                                            let hours = Int(maxVal) / 60
                                            let minutes = Int(maxVal) % 60
                                            
                                            if hours > 0 {
                                                Text("\(hours)小时\(minutes)分钟")
                                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                                    .foregroundColor(theme.primaryColor.opacity(0.9))
                                            } else {
                                                Text("\(minutes)分钟")
                                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                                    .foregroundColor(theme.primaryColor.opacity(0.9))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 160)
                    }
                    .padding(20)
                    .background(theme.backgroundColor)
                    .cornerRadius(16)
                    
                    // Monthly Heatmap
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            // 获取当前月份名称
                            let monthName = DateFormatter().monthSymbols[Calendar.current.component(.month, from: Date()) - 1]
                            let year = Calendar.current.component(.year, from: Date())
                            
                            Text("\(monthName.uppercased()) \(year)")
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
                        
                        // 将日期标签移出GeometryReader
                        HStack {
                            ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                                Text(day)
                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(theme.beatHightColor)
                            }
                        }
                        
                        // 只让热力图在GeometryReader中
                        GeometryReader { geometry in
                            if monthlyData.isEmpty {
                                Text("No data for this month")
                                    .foregroundColor(theme.primaryColor.opacity(0.7))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                // Calendar grid
                                let cellWidth = (geometry.size.width - 24) / 7 // Accounting for spacing
                                VStack(spacing: 8) {
                                    ForEach(0..<monthlyData.count, id: \.self) { row in
                                        if row < monthlyData.count {
                                            HStack(spacing: 4) {
                                                ForEach(0..<7, id: \.self) { col in
                                                    if col < monthlyData[row].count {
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(monthlyData[row][col] == 0 ?
                                                                  theme.beatHightColor.opacity(0.2) :
                                                                  theme.beatHightColor.opacity(0.4 + (monthlyData[row][col] * 0.6)))
                                                            .frame(width: cellWidth, height: cellWidth)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 170) // 调整为仅容纳热力图的高度
                        
                        // 将图例移到GeometryReader外部
                        HStack {
                            Text("LESS")
                                .font(.custom("MiSansLatin-Regular", size: 12))
                                .foregroundColor(theme.beatHightColor.opacity(0.9))
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                ForEach([0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { opacity in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(theme.beatHightColor.opacity(opacity))
                                        .frame(width: 12, height: 12)
                                }
                            }
                            
                            Spacer()
                            
                            Text("MORE")
                                .font(.custom("MiSansLatin-Regular", size: 12))
                                .foregroundColor(theme.beatHightColor.opacity(0.9))
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(theme.backgroundColor)
                    .cornerRadius(16)
                    
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
        
        // 本周数据
        weeklyData = practiceManager.getWeeklyPracticeData()
        
        // 月度热图数据
        monthlyData = practiceManager.getMonthlyHeatmapData()
        
        // 最常练习的速度
        mostPracticedTempo = practiceManager.getMostPracticedTempo()
        
        // 最长练习会话
        let longestSessionInfo = practiceManager.getLongestSession()
        longestSession = longestSessionInfo.date
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
