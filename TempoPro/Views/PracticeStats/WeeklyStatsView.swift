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
