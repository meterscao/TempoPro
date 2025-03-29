//
//  CoreDataPracticeManager.swift
//  TempoPro
//
//  Created by Meters on 5/3/2025.
//

import Foundation
import CoreData
import SwiftUI
import Combine

// 将结构体定义移到类的外部
public struct PracticeDataPoint {
    let date: Date
    let dateString: String
    let duration: Double // 以分钟为单位
    let sessionCount: Int
    let maxSessionDuration: Double // 最长单次练习时长（分钟）
    let isEmpty: Bool // 标识是否为无数据的填充项
    let disabled: Bool // 标识是否在有效日期范围外（灰显）
    
    // 添加一个初始化方法，便于创建实例
    init(date: Date, dateString: String, duration: Double, sessionCount: Int, maxSessionDuration: Double, isEmpty: Bool, disabled: Bool = false) {
        self.date = date
        self.dateString = dateString
        self.duration = duration
        self.sessionCount = sessionCount
        self.maxSessionDuration = maxSessionDuration
        self.isEmpty = isEmpty
        self.disabled = disabled
    }
}

class CoreDataPracticeManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    // 当前练习会话
    @Published var currentSession: PracticeSession?
    @Published var sessionStartTime: Date?
    
    // 生成测试数据标志
    private let testDataGeneratedKey = "TempoPro.testDataGenerated"
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // 开始新的练习会话
    func startPracticeSession(bpm: Int) {
        // 结束任何已存在的会话
        if currentSession != nil {
            endPracticeSession()
        }
        
        sessionStartTime = Date()
        
        // 创建新的会话（但暂不保存到CoreData）
        let newSession = PracticeSession(context: viewContext)
        newSession.id = UUID()
        newSession.dateString = getCurrentDateString()
        newSession.tempo = Int16(bpm)
        // 暂时存储节拍模式
//        newSession.setValue(beatPattern, forKey: "metronomePattern")
        newSession.startTimeOfDay = getTimeOfDayInHours(from: sessionStartTime!)
        
        currentSession = newSession
    }
    
    // 结束当前练习会话并保存
    func endPracticeSession() {
        guard let session = currentSession, let startTime = sessionStartTime else { return }
        
        // 计算持续时间（秒）
        let duration = Int32(Date().timeIntervalSince(startTime))
        session.duration = duration

        print("session.duration: \(session.duration)")
        
        // 如果持续时间大于30秒，则更新或创建当日练习摘要
        if session.duration > 30 {
            // 更新或创建当日练习摘要
            updateDailyPracticeSummary(for: session)
            // 保存上下文
            saveContext()
        }
        
        // 重置当前会话
        currentSession = nil
        sessionStartTime = nil
    }
    
    // 更新当日练习摘要
    private func updateDailyPracticeSummary(for session: PracticeSession) {
        let dateString = session.dateString ?? getCurrentDateString()
        
        // 尝试查找当日摘要
        let request = NSFetchRequest<DailyPractice>(entityName: "DailyPractice")
        request.predicate = NSPredicate(format: "dateString == %@", dateString)
        
        do {
            let results = try viewContext.fetch(request)
            let dailyPractice: DailyPractice
            
            if let existing = results.first {
                // 更新现有记录
                dailyPractice = existing
                dailyPractice.sessionCount += 1
                dailyPractice.totalDuration += session.duration
                
                // 更新最长会话时长
                if session.duration > dailyPractice.maxSessionDuration {
                    dailyPractice.maxSessionDuration = session.duration
                }
            } else {
                // 创建新记录
                dailyPractice = DailyPractice(context: viewContext)
                dailyPractice.id = UUID()
                dailyPractice.dateString = dateString
                dailyPractice.sessionCount = 1
                dailyPractice.totalDuration = session.duration
                dailyPractice.maxSessionDuration = session.duration
            }
            
            dailyPractice.lastUpdated = Date()
            
            // 建立关系
            dailyPractice.addToPracticeSessions(session)
            
        } catch {
            print("获取当日练习摘要失败: \(error.localizedDescription)")
        }
    }
    
    
    // 获取当前日期字符串 YYYY-MM-DD
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // 获取一天中的时间点（小时，如14.5表示14:30）
    private func getTimeOfDayInHours(from date: Date) -> Double {
        let calendar = Calendar.current
        let hour = Double(calendar.component(.hour, from: date))
        let minute = Double(calendar.component(.minute, from: date))
        return hour + (minute / 60.0)
    }
    
    // 保存上下文
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("保存练习数据失败: \(error.localizedDescription)")
        }
    }
    
    // 添加到CoreDataPracticeManager类中

    // 获取连续练习天数
    func getCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = Date()
        var streakDays = 0
        
        let request = NSFetchRequest<DailyPractice>(entityName: "DailyPractice")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyPractice.dateString, ascending: false)]
        
        do {
            let practices = try viewContext.fetch(request)
            guard !practices.isEmpty else { return 0 }
            
            // 检查是否包含今天
            let todayString = formatDate(today)
            let hasPracticedToday = practices.contains { $0.dateString == todayString }
            
            var currentDate = today
            if !hasPracticedToday {
                // 如果今天没有练习，从昨天开始检查
                currentDate = calendar.date(byAdding: .day, value: -1, to: today)!
            }
            
            // 向前检查每一天
            while true {
                let dateString = formatDate(currentDate)
                let hasPractice = practices.contains { $0.dateString == dateString }
                
                if hasPractice {
                    streakDays += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                } else {
                    break
                }
            }
            
            return streakDays
        } catch {
            print("获取练习记录失败: \(error.localizedDescription)")
            return 0
        }
    }

    // 获取当月练习天数
    func getPracticeDaysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        // 获取当月的开始日期
        let components = calendar.dateComponents([.year, .month], from: today)
        guard let startOfMonth = calendar.date(from: components) else { return 0 }
        
        // 获取下月的开始日期
        guard let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return 0 }
        
        // 查询当月的所有练习记录
        let request = NSFetchRequest<DailyPractice>(entityName: "DailyPractice")
        let startDateString = formatDate(startOfMonth)
        let endDateString = formatDate(startOfNextMonth)
        
        request.predicate = NSPredicate(format: "dateString >= %@ AND dateString < %@", startDateString, endDateString)
        
        do {
            let practices = try viewContext.fetch(request)
            return practices.count
        } catch {
            print("获取当月练习记录失败: \(error.localizedDescription)")
            return 0
        }
    }

    // 获取总练习时间（小时）
    func getTotalPracticeHours() -> Double {
        let request = NSFetchRequest<DailyPractice>(entityName: "DailyPractice")
        
        do {
            let practices = try viewContext.fetch(request)
            let totalSeconds = practices.reduce(0) { $0 + $1.totalDuration }
            return Double(totalSeconds) / 3600.0 // 转换为小时
        } catch {
            print("获取总练习时间失败: \(error.localizedDescription)")
            return 0
        }
    }


    

    // 辅助方法：将Date格式化为YYYY-MM-DD
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // 获取最常练习的BPM范围
    func getMostPracticedTempo() -> String {
        let request = NSFetchRequest<PracticeSession>(entityName: "PracticeSession")
        
        do {
            let sessions = try viewContext.fetch(request)
            guard !sessions.isEmpty else { return "未知" }
            
            // 将BPM分组到20BPM范围内
            var tempoRanges: [String: Int] = [:]
            
            for session in sessions {
                let tempo = Int(session.tempo)
                let lowerBound = (tempo / 20) * 20
                let upperBound = lowerBound + 20
                let range = "\(lowerBound)-\(upperBound)"
                
                tempoRanges[range, default: 0] += 1
            }
            
            // 找出最常见的范围
            if let mostCommon = tempoRanges.max(by: { $0.value < $1.value }) {
                return "\(mostCommon.key) BPM"
            } else {
                return "未知"
            }
        } catch {
            print("获取练习会话失败: \(error.localizedDescription)")
            return "未知"
        }
    }

    // 获取最长练习会话
    func getLongestSession() -> (duration: Double, date: String) {
        let request = NSFetchRequest<PracticeSession>(entityName: "PracticeSession")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PracticeSession.duration, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let sessions = try viewContext.fetch(request)
            if let longest = sessions.first {
                let minutes = Double(longest.duration) / 60.0
                let formattedMinutes = String(format: "%.0f", minutes)
                
                // 获取月和日
                if let dateString = longest.dateString, dateString.count >= 10 {
                    let monthDay = String(dateString.suffix(5))
                    return (minutes, "\(formattedMinutes)分钟 (\(monthDay))")
                }
                
                return (minutes, "\(formattedMinutes)分钟")
            }
            return (0, "无记录")
        } catch {
            print("获取最长会话失败: \(error.localizedDescription)")
            return (0, "无记录")
        }
    }

    // 生成半年随机练习数据
    func generateRandomHistoricalData() {
        // 检查是否已经生成过测试数据
        if UserDefaults.standard.bool(forKey: testDataGeneratedKey) {
            print("已经生成过测试数据，跳过")
            return
        }
        
        print("开始生成随机历史练习数据...")
        let calendar = Calendar.current
        let today = Date()
        
        // 计算半年前的日期
        guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: today) else {
            return
        }
        
        // 常用练习速度
        let commonTempos = [60, 70, 80, 90, 100, 120, 140, 160]
        
        // 设置随机种子
        var dateIterator = sixMonthsAgo
        var practiceCount = 0
        
        // 生成规律性练习模式
        // - 周一、周三、周五晚上固定练习
        // - 周末早上或下午可能练习
        // - 随机跳过一些天
        
        while dateIterator <= today {
            // 获取星期几
            let weekday = calendar.component(.weekday, from: dateIterator)
            let hour = calendar.component(.hour, from: dateIterator)
            
            // 决定今天是否有练习
            var shouldPractice = false
            var practiceCount = 1 // 当天练习次数
            
            // 工作日模式：周一、周三、周五晚上练习
            if (weekday == 2 || weekday == 4 || weekday == 6) && hour >= 18 {
                shouldPractice = true
                // 80%概率练习
                shouldPractice = Double.random(in: 0...1) < 0.8
            }
            
            // 周末模式：周六、周日白天可能练习
            if (weekday == 7 || weekday == 1) && hour >= 10 && hour <= 18 {
                shouldPractice = Double.random(in: 0...1) < 0.6
                // 周末可能多练几次
                if shouldPractice {
                    practiceCount = Int.random(in: 1...3)
                }
            }
            
            // 添加一些随机性
            if !shouldPractice && Double.random(in: 0...1) < 0.15 {
                shouldPractice = true
            }
            
            // 生成练习数据
            if shouldPractice {
                // 记录当前日期字符串
                let dateString = formatDate(dateIterator)
                
                for _ in 1...practiceCount {
                    // 生成一个随机练习会话
                    let session = PracticeSession(context: viewContext)
                    session.id = UUID()
                    session.dateString = dateString
                    
                    // 随机挑选一个常用速度，偶尔有变化
                    let tempoIndex = Int.random(in: 0..<commonTempos.count)
                    let baseTempo = commonTempos[tempoIndex]
                    let finalTempo = Double.random(in: 0...1) < 0.8 ? 
                        baseTempo : 
                        baseTempo + Int.random(in: -5...5)
                    
                    session.tempo = Int16(finalTempo)
                    
                    // 生成合理的练习时长 (10分钟到1小时)
                    let durationMinutes = Double.random(in: 0...30)
                    session.duration = Int32(durationMinutes * 60)
                    
                    // 设置一天内的开始时间
                    let startHour = Double.random(in: 9...21)
                    let startMinute = Double.random(in: 0...59) / 60.0
                    session.startTimeOfDay = startHour + startMinute
                    
                    // 更新或创建当日练习摘要
                    updateDailyPracticeSummary(for: session)
                    
                    practiceCount += 1
                }
            }
            
            // 移动到下一个时段（最小粒度为3小时）
            dateIterator = calendar.date(byAdding: .hour, value: 3, to: dateIterator) ?? today
        }
        
        // 保存生成的数据
        saveContext()
        print("随机历史数据生成完成，共生成 \(practiceCount) 条练习记录")
        
        // 标记已生成
        UserDefaults.standard.set(true, forKey: testDataGeneratedKey)
    }

    // 重置测试数据（如需重新生成）
    func resetTestData() {
        UserDefaults.standard.removeObject(forKey: testDataGeneratedKey)
        
        // 删除所有已有练习记录
        let practiceSessionRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PracticeSession")
        let dailyPracticeRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DailyPractice")
        
        let practiceSessionDeleteRequest = NSBatchDeleteRequest(fetchRequest: practiceSessionRequest)
        let dailyPracticeDeleteRequest = NSBatchDeleteRequest(fetchRequest: dailyPracticeRequest)
        
        do {
            try viewContext.execute(practiceSessionDeleteRequest)
            try viewContext.execute(dailyPracticeDeleteRequest)
            try viewContext.save()
            print("所有测试数据已重置")
        } catch {
            print("重置测试数据失败: \(error.localizedDescription)")
        }
    }


    

    // 格式化时长（分钟转为小时分钟）
    func formatDuration(minutes: Double) -> String {
        if minutes < 60 {
            return String(format: "%.0f 分钟", minutes)
        } else {
            let hours = Int(minutes) / 60
            let mins = Int(minutes) % 60
            return "\(hours) 小时 \(mins) 分钟"
        }
    }

    // 实现 funA 函数，获取指定日期范围的练习数据
    func getPracticeDataForDateRange(from startDate: Date, to endDate: Date) -> [PracticeDataPoint] {
        // 1. 确保日期范围有效
        guard startDate <= endDate else {
            print("无效的日期范围：开始日期不能晚于结束日期")
            return []
        }
        
        // 2. 创建日期格式化器用于日期转字符串
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 3. 获取起始日期和结束日期的字符串表示
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // 4. 准备查询条件
        let request = NSFetchRequest<DailyPractice>(entityName: "DailyPractice")
        request.predicate = NSPredicate(format: "dateString >= %@ AND dateString <= %@", startDateString, endDateString)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyPractice.dateString, ascending: true)]
        
        // 5. 准备结果数组
        var practiceData: [PracticeDataPoint] = []
        
        // 6. 查询数据库
        do {
            // 获取查询结果
            let practices = try viewContext.fetch(request)
            
            // 将结果转换为字典，方便按日期查找
            var practiceByDate: [String: DailyPractice] = [:]
            for practice in practices {
                if let dateString = practice.dateString {
                    practiceByDate[dateString] = practice
                }
            }
            
            // 7. 生成连续日期，并填充数据
            let calendar = Calendar.current
            var currentDate = startDate
            
            // 为每一天创建数据点
            while currentDate <= endDate {
                let dateString = dateFormatter.string(from: currentDate)
                
                if let practice = practiceByDate[dateString] {
                    // 有数据的日期
                    let dataPoint = PracticeDataPoint(
                        date: currentDate,
                        dateString: dateString,
                        duration: Double(practice.totalDuration) / 60.0, // 转换为分钟
                        sessionCount: Int(practice.sessionCount),
                        maxSessionDuration: Double(practice.maxSessionDuration) / 60.0, // 转换为分钟
                        isEmpty: false,
                        disabled: false
                    )
                    practiceData.append(dataPoint)
                } else {
                    // 无数据的日期，填充空值
                    let emptyDataPoint = PracticeDataPoint(
                        date: currentDate,
                        dateString: dateString,
                        duration: 0,
                        sessionCount: 0,
                        maxSessionDuration: 0,
                        isEmpty: true,
                        disabled: false
                    )
                    practiceData.append(emptyDataPoint)
                }
                
                // 移动到下一天
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextDate
            }
            
        } catch {
            print("获取日期范围数据失败: \(error.localizedDescription)")
        }
        
        return practiceData
    }

    /// 获取指定日期范围内的练习数据，并按周分割
    /// - Parameters:
    ///   - startDate: 开始日期（包含）
    ///   - endDate: 结束日期（包含）
    /// - Returns: 二维数组，每个子数组代表一周（从周一到周日）
    func getPracticeDataByWeeks(from startDate: Date, to endDate: Date) -> [[PracticeDataPoint]] {
        // 1. 确保日期范围有效
        guard startDate <= endDate else {
            print("无效的日期范围：开始日期不能晚于结束日期")
            return []
        }
        
        // 2. 设置日历，确保周一为每周第一天
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 设置周一为每周第一天
        
        // 3. 计算开始日期所在周的周一
        let startDateWeekday = calendar.component(.weekday, from: startDate)
        let daysToSubtractForStartMonday = (startDateWeekday + 5) % 7 // 转换为周一为第一天的偏移量
        guard let startWeekMonday = calendar.date(byAdding: .day, value: -daysToSubtractForStartMonday, to: startDate) else {
            return []
        }
        
        // 4. 计算结束日期所在周的周日
        let endDateWeekday = calendar.component(.weekday, from: endDate)
        let daysToAddForEndSunday = (7 - endDateWeekday + 1) % 7 // 转换为周日为最后一天的偏移量
        guard let endWeekSunday = calendar.date(byAdding: .day, value: daysToAddForEndSunday, to: endDate) else {
            return []
        }
        
        // 5. 获取整个扩展日期范围内的所有数据
        let allData = getPracticeDataForDateRange(from: startWeekMonday, to: endWeekSunday)
        
        // 6. 创建日期格式化器
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 7. 按周分组数据
        var weeklyData: [[PracticeDataPoint]] = []
        var currentWeekData: [PracticeDataPoint] = []
        var dayCount = 0
        
        // 8. 重新遍历每一天，判断是否在有效范围内
        for var dataPoint in allData {
            // 创建一个可变副本，因为结构体是不可变的
            let isBeforeStartDate = dataPoint.date < startDate
            let isAfterEndDate = dataPoint.date > endDate
            
            // 根据日期是否在有效范围内设置disabled属性
            let updatedDataPoint = PracticeDataPoint(
                date: dataPoint.date,
                dateString: dataPoint.dateString,
                duration: dataPoint.duration,
                sessionCount: dataPoint.sessionCount,
                maxSessionDuration: dataPoint.maxSessionDuration,
                isEmpty: dataPoint.isEmpty,
                disabled: isBeforeStartDate || isAfterEndDate // 在有效范围外的日期标记为disabled
            )
            
            // 添加到当前周
            currentWeekData.append(updatedDataPoint)
            dayCount += 1
            
            // 如果已经有7天数据或者是最后一个数据点，当前周完成
            if dayCount == 7 || updatedDataPoint.date == endWeekSunday {
                // 确保每周都是7天（周一到周日），如果不足则用空数据填充
                while currentWeekData.count < 7 {
                    // 这种情况通常不会发生，因为我们已经计算了完整的周期
                    // 但为了健壮性添加此处理
                    guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentWeekData.last!.date) else {
                        break
                    }
                    
                    let emptyPoint = PracticeDataPoint(
                        date: nextDate,
                        dateString: dateFormatter.string(from: nextDate),
                        duration: 0,
                        sessionCount: 0,
                        maxSessionDuration: 0,
                        isEmpty: true,
                        disabled: true
                    )
                    currentWeekData.append(emptyPoint)
                }
                
                weeklyData.append(currentWeekData)
                currentWeekData = []
                dayCount = 0
            }
        }
        
        return weeklyData
    }

    /// 获取指定月份的练习数据，按周分组
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份（1-12）
    /// - Returns: 二维数组，每个子数组代表一周（从周一到周日）
    func getPracticeDataByMonth(year: Int, month: Int) -> [[PracticeDataPoint]] {
        // 1. 验证月份参数
        guard month >= 1 && month <= 12 else {
            print("无效的月份参数：月份必须在1-12之间")
            return []
        }
        
        // 2. 创建日历
        let calendar = Calendar.current
        
        // 3. 计算月份的第一天
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month
        startComponents.day = 1
        
        guard let startOfMonth = calendar.date(from: startComponents) else {
            print("无效的日期参数")
            return []
        }
        
        // 4. 计算月份的最后一天
        var endComponents = DateComponents()
        // 如果是12月，则下一个月是下一年的1月
        if month == 12 {
            endComponents.year = year + 1
            endComponents.month = 1
        } else {
            endComponents.year = year
            endComponents.month = month + 1
        }
        endComponents.day = 1
        
        guard let startOfNextMonth = calendar.date(from: endComponents),
              let endOfMonth = calendar.date(byAdding: .day, value: -1, to: startOfNextMonth) else {
            print("计算月份结束日期失败")
            return []
        }
        
        // 5. 使用 getPracticeDataByWeeks 获取按周分组的数据
        return getPracticeDataByWeeks(from: startOfMonth, to: endOfMonth)
    }
}

