//
//  MonthlyHeatmapView.swift
//  TempoPro
//
//  Created by Meters on 7/3/2025.
//
import SwiftUI

// 提取出来的月度热力图组件
struct MonthlyHeatmapView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var practiceManager: CoreDataPracticeManager
    @State private var monthlyData: [[Double]] = []
    @State private var currentMonth = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // 获取当前月份名称
                let monthName = monthFormatter.string(from: currentMonth)
                let year = Calendar.current.component(.year, from: currentMonth)
                
                Text("\(monthName.uppercased()) \(year)")
                    .font(.custom("MiSansLatin-Semibold", size: 20))
                    .foregroundColor(theme.primaryColor)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        goToPreviousMonth()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    Button(action: {
                        goToNextMonth()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            .padding(.bottom, 8)
            
            // 星期标签
            HStack {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.custom("MiSansLatin-Regular", size: 12))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(theme.beatHightColor)
                }
            }
            
            // 热力图主体
            VStack {
                GeometryReader { geometry in
                    if monthlyData.isEmpty {
                        Text("No data for this month")
                            .foregroundColor(theme.primaryColor.opacity(0.7))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // 计算每个单元格的尺寸，确保宽高相等
                        let spacing: CGFloat = 8 // 设置固定间距为8
                        
                        // 修正计算单元格大小的方式
                        // 一行有7个单元格，它们之间有6个间距，总共需要空间是 7*cellSize + 6*spacing
                        let availableWidth = geometry.size.width
                        let cellSize = (availableWidth - (spacing * 6)) / 7
                        
                        // 计算整个热力图需要的高度
                        let rowCount = monthlyData.count
                        let totalHeight = (cellSize * CGFloat(rowCount)) + (spacing * CGFloat(rowCount - 1))
                        
                        // 使容器固定在计算出的高度
                        VStack(spacing: 0) {
                            // 热力图内容
                            VStack(spacing: spacing) {
                                ForEach(0..<monthlyData.count, id: \.self) { row in
                                    HStack(spacing: spacing) {
                                        ForEach(0..<7, id: \.self) { col in
                                            if col < monthlyData[row].count {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(monthlyData[row][col] == 0 ?
                                                        theme.beatHightColor.opacity(0.2) :
                                                        theme.beatHightColor.opacity(0.4 + (monthlyData[row][col] * 0.6)))
                                                    .frame(width: cellSize, height: cellSize)
                                            } else {
                                                // 如果没有数据，显示空白区域保持布局
                                                Rectangle()
                                                    .fill(Color.clear)
                                                    .frame(width: cellSize, height: cellSize)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: totalHeight)
                            Spacer(minLength: 0) // 让热力图保持在顶部
                        }
                    }
                }
                .frame(height: nil) // 移除任何固定高度约束
                .fixedSize(horizontal: false, vertical: true) // 让视图采用其自然高度
            }
            
            // 图例
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
        .onAppear {
            loadMonthData()
        }
    }
    
    // 月份格式化器
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }
    
    // 加载特定月份的数据
    private func loadMonthData() {
        monthlyData = practiceManager.getMonthlyHeatmapData(for: currentMonth)
    }
    
    // 前往上一个月
    private func goToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
            loadMonthData()
        }
    }
    
    // 前往下一个月
    private func goToNextMonth() {
        // 只允许浏览到当前月份
        let now = Date()
        if currentMonth < now, 
           let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth),
           Calendar.current.compare(newDate, to: now, toGranularity: .month) != .orderedDescending {
            currentMonth = newDate
            loadMonthData()
        }
    }
}
