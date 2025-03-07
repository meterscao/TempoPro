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
    let selectedDay: Int?   // 添加选中的日期
    let onDateSelected: (Int) -> Void  // 添加日期选择回调
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<dateCells.count, id: \.self) { col in
                if dateCells[col].isVisible {
                    ZStack {
                        // 获取该日期对应的实际数据
                        let practiceValue = getValueForDay(dateCells[col].day)
                        let isSelected = selectedDay == dateCells[col].day
                        
                        // 背景方块
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                isSelected ?
                                  theme.primaryColor:
                                  (
                                    practiceValue == 0 ?
                                  theme.beatBarColor.opacity(0.1) :
                                  theme.beatBarColor.opacity(0.4 + (practiceValue * 0.6))
                                  ))
                            .frame(width: cellSize, height: cellSize)
                        
                        // 选中边框
                        // if isSelected {
                        //     RoundedRectangle(cornerRadius: 8)
                        //         .stroke(theme.primaryColor, lineWidth: 2)
                        //         .frame(width: cellSize, height: cellSize)
                        // }
                        
                        // 日期数字
                        Text("\(dateCells[col].day)")
                            .font(.system(size: max(10, cellSize * 0.25)))
                            .foregroundColor(theme.primaryColor.opacity(0.7))
                            .position(x: cellSize * 0.25, y: cellSize * 0.25) // 放置在左上角
                            .hidden()
                    }
                    .contentShape(Rectangle())  // 确保整个区域可点击
                    .onTapGesture {
                        onDateSelected(dateCells[col].day)  // 点击时触发回调
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
    let selectedDay: Int?  // 添加选中的日期
    let onDateSelected: (Int) -> Void  // 添加日期选择回调
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
                            // 传递完整数据集、当前月份和选中的日期
                            HeatmapRowView(
                                rowData: row < monthlyData.count ? monthlyData[row] : Array(repeating: 0, count: 7),
                                dateCells: monthDays[row],
                                cellSize: cellSize,
                                spacing: spacing,
                                theme: theme,
                                monthlyData: monthlyData,
                                currentMonth: currentMonth,
                                selectedDay: selectedDay,  // 传递选中的日期
                                onDateSelected: onDateSelected
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
            // 月份导航栏
            HStack {
                Text("\(currentYear) \(monthNames[currentMonth-1])")
                    .font(.custom("MiSansLatin-Semibold", size: 20))
                    .foregroundColor(theme.primaryColor)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        // 切换到上一个月
                        moveMonth(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    Button(action: {
                        // 切换到下一个月
                        moveMonth(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            .padding(.bottom, 8)
            
            // 星期几标题
            HStack(spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.custom("MiSansLatin-Regular", size: 12))
                        .foregroundColor(theme.primaryColor.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
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
                                    .cornerRadius(4)
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
                                RoundedRectangle(cornerRadius: 4)
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
            
            // 统计信息展示 - 使用预计算的信息
            VStack(alignment: .leading, spacing: 8) {
                if selectedDay != nil {
                    // 使用预先计算的信息
                    let info = selectedDayInfo
                    
                    HStack {
                        Text(info.dateString)
                            .font(.custom("MiSansLatin-Regular", size: 14))
                            .foregroundColor(theme.primaryColor)
                        
                        Spacer()
                        
                        if info.hasPractice {
                            Text("\(info.sessionCount)次练习")
                                .font(.custom("MiSansLatin-Regular", size: 14))
                                .foregroundColor(theme.primaryColor.opacity(0.8))
                                .padding(.trailing, 8)
                            
                            Text(info.durationText)
                                .font(.custom("MiSansLatin-Regular", size: 14))
                                .foregroundColor(theme.primaryColor)
                        } else {
                            Text("无练习记录")
                                .font(.custom("MiSansLatin-Regular", size: 14))
                                .foregroundColor(theme.primaryColor.opacity(0.7))
                        }
                    }
                } else {
                    // 显示月度统计信息 - 使用预计算的数据
                    HStack {
                        Text("本月共练习")
                            .font(.custom("MiSansLatin-Regular", size: 14))
                            .foregroundColor(theme.primaryColor)
                        
                        Text("\(monthlyStatsData.days)天")
                            .font(.custom("MiSansLatin-Semibold", size: 14))
                            .foregroundColor(theme.primaryColor)
                        
                        Spacer()
                        
                        Text(practiceManager.formatDuration(minutes: monthlyStatsData.totalMinutes))
                            .font(.custom("MiSansLatin-Regular", size: 14))
                            .foregroundColor(theme.primaryColor)
                    }
                }
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
            return Color.gray.opacity(0.1) // 超出月份范围的日期使用浅灰色
        }
        
        // 无数据使用非常浅的颜色
        if minutes == 0 {
            return theme.beatBarColor.opacity(0.1)
        }
        
        // 根据练习时长设置不同深度的颜色
        if minutes < 15 {
            return theme.beatBarColor.opacity(0.3)
        } else if minutes < 30 {
            return theme.beatBarColor.opacity(0.5)
        } else if minutes < 60 {
            return theme.beatBarColor.opacity(0.7)
        } else if minutes < 120 {
            return theme.beatBarColor.opacity(0.85)
        } else {
            return theme.beatBarColor // 超过2小时使用完全不透明的颜色
        }
    }
}
