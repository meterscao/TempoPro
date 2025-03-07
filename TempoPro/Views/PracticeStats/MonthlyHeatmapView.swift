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

// 添加一个内部视图来处理布局计算
private struct HeatmapContentView: View {
    let monthlyData: [[Double]]
    let theme: MetronomeTheme
    let width: CGFloat
    
    var body: some View {
        let spacing: CGFloat = 8
        let cellSize = (width - (spacing * 6)) / 7
        let rowCount = monthlyData.count
        let totalHeight = (cellSize * CGFloat(rowCount)) + (spacing * CGFloat(rowCount - 1))
        
        VStack(spacing: spacing) {
            ForEach(0..<monthlyData.count, id: \.self) { row in
                HeatmapRowView(
                    rowData: row < monthlyData.count ? monthlyData[row] : [],
                    cellSize: cellSize,
                    spacing: spacing,
                    theme: theme
                )
            }
        }
        .frame(height: totalHeight)
        .onAppear {
            debugPrint("Debug: width = \(width), cellSize = \(cellSize)")
            debugPrint("Debug: rowCount = \(rowCount), totalHeight = \(totalHeight)")
        }
    }
}

// 添加这个辅助视图来拆分复杂结构
private struct HeatmapGridView: View {
    let monthlyData: [[Double]]
    let theme: MetronomeTheme
    @State private var calculatedHeight: CGFloat = 100
    
    var body: some View {
        let spacing: CGFloat = 8
        
        Group {
            if monthlyData.isEmpty {
                Text("No data for this month")
                    .foregroundColor(theme.primaryColor.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
            } else {
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let cellSize = (availableWidth - (spacing * 6)) / 7
                    let rowCount = monthlyData.count
                    let totalHeight = (cellSize * CGFloat(rowCount)) + (spacing * CGFloat(rowCount - 1))
                    
                    VStack(spacing: spacing) {
                        ForEach(0..<monthlyData.count, id: \.self) { row in
                            HeatmapRowView(
                                rowData: row < monthlyData.count ? monthlyData[row] : [],
                                cellSize: cellSize,
                                spacing: spacing,
                                theme: theme
                            )
                        }
                    }
                    .frame(height: totalHeight)
                    // 使用preference传递计算出的高度
                    .preference(key: HeatmapHeightPreferenceKey.self, value: totalHeight)
                    .onAppear {
                        debugPrint("Debug: availableWidth = \(availableWidth), cellSize = \(cellSize)")
                        debugPrint("Debug: rowCount = \(rowCount), totalHeight = \(totalHeight)")
                    }
                }
                // 使用计算出的高度
                .frame(height: calculatedHeight)
                // 监听高度变化
                .onPreferenceChange(HeatmapHeightPreferenceKey.self) { height in
                    self.calculatedHeight = height
                }
            }
        }
    }
}

// 再拆分一层，处理每一行
private struct HeatmapRowView: View {
    let rowData: [Double]
    let cellSize: CGFloat
    let spacing: CGFloat
    let theme: MetronomeTheme
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<7, id: \.self) { col in
                if col < rowData.count {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(rowData[col] == 0 ?
                            theme.beatHightColor.opacity(0.1) :
                            theme.beatHightColor.opacity(0.4 + (rowData[col] * 0.6)))
                        .frame(width: cellSize, height: cellSize)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
    }
}

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
            
            // 热力图主体 - 简化嵌套结构
            HeatmapGridView(monthlyData: monthlyData, theme: theme)
                
            
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
        print("Debug: 加载了 \(currentMonth) 的数据，行数: \(monthlyData.count)")
        // 打印每行的数据长度
        for (index, row) in monthlyData.enumerated() {
            print("Debug: 第\(index)行数据长度: \(row.count)")
        }
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
