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

// 处理每一行的视图
private struct HeatmapRowView: View {
    let rowData: [Double]
    let dateCells: [DateCellInfo]  // 该行的日期信息
    let cellSize: CGFloat
    let spacing: CGFloat
    let theme: MetronomeTheme
    let monthlyData: [[Double]]  // 添加完整的月度数据
    let currentMonth: Date  // 添加当前月份
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<dateCells.count, id: \.self) { col in
                if dateCells[col].isVisible {
                    ZStack {
                        // 获取该日期对应的实际数据
                        let practiceValue = getValueForDay(dateCells[col].day)
                        
                        // 背景方块
                        RoundedRectangle(cornerRadius: 8)
                            .fill(practiceValue == 0 ?
                                  theme.beatHightColor.opacity(0.1) :
                                  theme.beatHightColor.opacity(0.4 + (practiceValue * 0.6)))
                            .frame(width: cellSize, height: cellSize)
                        
                        // 日期数字
                        Text("\(dateCells[col].day)")
                            .font(.system(size: max(10, cellSize * 0.25)))
                            .foregroundColor(theme.primaryColor.opacity(0.7))
                            .position(x: cellSize * 0.25, y: cellSize * 0.25) // 放置在左上角
                            .hidden()
                    }
                } else {
                    // 不可见的日期显示透明方块
                    Color.clear
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
    }
    
    // 根据日期获取对应的数据值
    private func getValueForDay(_ day: Int) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfMonth = calendar.date(from: components),
              // 创建这一天的日期
              let currentDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else {
            return 0
        }
        
        // 获取该日期在一周中的位置（0-6，周一为0）
        let weekday = calendar.component(.weekday, from: currentDate)
        let adjustedWeekday = (weekday + 5) % 7  // 调整为周一=0
        
        // 获取该日期是当月第几周
        let weekOfMonth = calendar.component(.weekOfMonth, from: currentDate) - 1
        
        // 添加调试日志
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        print("Debug: 日期 \(dateFormatter.string(from: currentDate)) (日期\(day)) => 第\(weekOfMonth)周, 星期\(adjustedWeekday)")
        
        // 确保索引有效
        if weekOfMonth < monthlyData.count && adjustedWeekday < monthlyData[weekOfMonth].count {
            let value = monthlyData[weekOfMonth][adjustedWeekday]
            print("Debug: 日期\(day)取值: monthlyData[\(weekOfMonth)][\(adjustedWeekday)] = \(value)")
            return value
        }
        
        print("Debug: 日期\(day)索引无效: weekOfMonth=\(weekOfMonth), adjustedWeekday=\(adjustedWeekday)")
        return 0
    }
}

// 热力图主视图
private struct HeatmapGridView: View {
    let monthlyData: [[Double]]
    let theme: MetronomeTheme
    let currentMonth: Date
    @State private var calculatedHeight: CGFloat = 100
    @State private var monthDays: [[DateCellInfo]] = []
    
    // 生成当月日期信息
    private func generateMonthDays() -> [[DateCellInfo]] {
        let calendar = Calendar.current
        
        // 创建一个以周一为第一天的日历
        var mondayFirstCalendar = Calendar.current
        mondayFirstCalendar.firstWeekday = 2  // 2 表示周一
        
        // 获取当前月的第一天和天数
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfMonth = calendar.date(from: components),
              let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count else { 
            return [] 
        }
        
        // 确定第一天是星期几（以周一为基准）
        let firstWeekday = mondayFirstCalendar.component(.weekday, from: firstDayOfMonth)
        // 调整为以周一为0的索引
        let adjustedFirstWeekday = (firstWeekday + 5) % 7 // 周一=0, 周二=1, ..., 周日=6
        
        // 按周整理日期
        var result: [[DateCellInfo]] = []
        
        // 默认每个位置都是不可见的
        for _ in 0..<6 { // 最多6周
            result.append(Array(repeating: DateCellInfo(day: 0, isVisible: false), count: 7))
        }
        
        // 填充当月的日期
        var currentDay = 1
        for day in 1...daysInMonth {
            // 计算这一天在哪一行哪一列
            let rowIndex = (adjustedFirstWeekday + day - 1) / 7
            let colIndex = (adjustedFirstWeekday + day - 1) % 7
            
            // 填充这一天
            if rowIndex < result.count {
                result[rowIndex][colIndex] = DateCellInfo(day: day, isVisible: true)
            }
        }
        
        // 移除空行
        result = result.filter { row in
            row.contains { $0.isVisible }
        }
        
        // 在返回结果前添加调试信息
        print("Debug: 生成的月份日期表:")
        for (rowIdx, row) in result.enumerated() {
            var rowDebug = "行\(rowIdx): "
            for (colIdx, cell) in row.enumerated() {
                rowDebug += cell.isVisible ? "\(cell.day) " : "- "
            }
            print(rowDebug)
        }
        
        return result
    }
    
    var body: some View {
        Group {
            if monthlyData.isEmpty {
                Text("无该月数据")
                    .foregroundColor(theme.primaryColor.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
            } else {
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let spacing: CGFloat = 8
                    let cellSize = (availableWidth - (spacing * 6)) / 7
                    
                    // 计算实际需要显示的行数
                    let rowCount = monthDays.count
                    let totalHeight = (cellSize * CGFloat(rowCount)) + (spacing * CGFloat(rowCount - 1))
                    
                    VStack(spacing: spacing) {
                        ForEach(0..<monthDays.count, id: \.self) { row in
                            // 传递完整数据集和当前月份
                            HeatmapRowView(
                                rowData: row < monthlyData.count ? monthlyData[row] : Array(repeating: 0, count: 7),
                                dateCells: monthDays[row],
                                cellSize: cellSize,
                                spacing: spacing,
                                theme: theme,
                                monthlyData: monthlyData,
                                currentMonth: currentMonth
                            )
                        }
                    }
                    .frame(height: totalHeight)
                    .preference(key: HeatmapHeightPreferenceKey.self, value: totalHeight)
                }
                .frame(height: calculatedHeight)
                .onPreferenceChange(HeatmapHeightPreferenceKey.self) { height in
                    self.calculatedHeight = height
                }
                .onAppear {
                    self.monthDays = generateMonthDays()
                    // 打印月份天数分布
                    debugPrint("月份天数分布: \(monthDays.map { row in row.filter { $0.isVisible }.count })")
                    
                    // 添加数据数组调试
                    print("Debug: 月度数据数组内容:")
                    for (rowIdx, row) in monthlyData.enumerated() {
                        var rowValues = "行\(rowIdx): "
                        for (colIdx, value) in row.enumerated() {
                            rowValues += "\(value) "
                        }
                        print(rowValues)
                    }
                }
            }
        }
        .background(Color.red.opacity(0.0))  // 移除红色背景，只在调试时需要
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
            
            // 星期标签 - 调整为周一至周日
            HStack {
                // 重新排序周标签，使周一为第一天
                let weekdaySymbols = Array(Calendar.current.shortWeekdaySymbols[1...6]) + [Calendar.current.shortWeekdaySymbols[0]]
                
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.custom("MiSansLatin-Regular", size: 12))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(theme.beatHightColor)
                }
            }
            
            // 热力图主体 - 传递当前月份信息
            HeatmapGridView(monthlyData: monthlyData, theme: theme, currentMonth: currentMonth)
                
            
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
        // 打印当前月份信息
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        print("========== 开始数据源调试 ==========")
        print("当前选择月份: \(dateFormatter.string(from: currentMonth))")
        
        // 尝试获取该月份的第一天和最后一天
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        if let firstDayOfMonth = calendar.date(from: components),
           let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth),
           let lastDayOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: firstDayOfMonth) {
            
            print("月份范围: \(dateFormatter.string(from: firstDayOfMonth)) 至 \(dateFormatter.string(from: lastDayOfMonth))")
            
            
        }
        
        // 保存原始数据用于调试
        let rawData = practiceManager.getMonthlyHeatmapData(for: currentMonth)
        print("\n原始热力图数据源:")
        for (weekIndex, week) in rawData.enumerated() {
            var weekData = "第\(weekIndex)周: "
            for (dayIndex, value) in week.enumerated() {
                weekData += "[\(dayIndex)]:\(value) "
            }
            print(weekData)
        }
        
        // 将原始数据与日历日期对应显示
        print("\n数据与日期映射关系:")
        if let firstDayOfMonth = calendar.date(from: components) {
            // 获取月初是星期几
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
            // 调整为以周一为0的索引 (ISO日历)
            let adjustedFirstWeekday = (firstWeekday + 5) % 7 // 周一=0, 周日=6
            
            for week in 0..<rawData.count {
                var weekMapping = "第\(week)周: "
                for day in 0..<7 {
                    // 计算日期
                    let dayOffset = week * 7 + day - adjustedFirstWeekday
                    if dayOffset >= 0 && dayOffset < 31 { // 假设最多31天
                        if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
                            let dayValue = (week < rawData.count && day < rawData[week].count) ? rawData[week][day] : 0
                            let dayNumber = calendar.component(.day, from: date)
                            weekMapping += "\(dayNumber):\(dayValue) "
                        }
                    } else {
                        weekMapping += "x:x "
                    }
                }
                print(weekMapping)
            }
        }
        
        // 检查数据加载实现
        print("\n检查practiceManager.getMonthlyHeatmapData实现:")
        print("请查看CoreDataPracticeManager中getMonthlyHeatmapData方法的实现，确认数据是如何按周组织的")
        print("========== 结束数据源调试 ==========\n")
        
        // 常规代码
        monthlyData = rawData
        
        // 常规日志
        print("Debug: 加载了 \(dateFormatter.string(from: currentMonth)) 的数据，行数: \(monthlyData.count)")
        for (index, row) in monthlyData.enumerated() {
            var rowValues = "第\(index)行数据: "
            for (colIdx, value) in row.enumerated() {
                rowValues += "\(value) "
            }
            print(rowValues)
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
