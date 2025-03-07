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

class CoreDataPracticeManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    // 当前练习会话
    @Published var currentSession: PracticeSession?
    @Published var sessionStartTime: Date?
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // 开始新的练习会话
    func startPracticeSession(bpm: Int, beatPattern: String) {
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
        
        // 更新或创建当日练习摘要
        updateDailyPracticeSummary(for: session)
        
        // 保存上下文
        saveContext()
        
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
    
    // 获取所有练习日期摘要
    func fetchDailyPracticeSummaries() -> [DailyPractice] {
        let request = NSFetchRequest<DailyPractice>(entityName: "DailyPractice")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyPractice.dateString, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("获取练习摘要失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // 获取特定日期的练习会话
    func fetchPracticeSessions(for dateString: String) -> [PracticeSession] {
        let request = NSFetchRequest<PracticeSession>(entityName: "PracticeSession")
        request.predicate = NSPredicate(format: "dateString == %@", dateString)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PracticeSession.startTimeOfDay, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("获取练习会话失败: \(error.localizedDescription)")
            return []
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

    // 优化后的获取过去7天数据的方法
    func getWeeklyPracticeData() -> [(String, Double)] {
        let calendar = Calendar.current
        let today = Date()
        
        // 计算7天前的日期
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else {
            return []
        }
        
        // 获取星期几的简称顺序
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let weekdayIndex = calendar.component(.weekday, from: today) - 1
        
        // 重新排列，并转换为普通数组
        let reorderedSymbols = Array(weekdaySymbols[weekdayIndex...] + weekdaySymbols[..<weekdayIndex])
        
        // 一次性查询过去7天的数据
        let request = NSFetchRequest<DailyPractice>(entityName: "DailyPractice")
        let startDateString = formatDate(sevenDaysAgo)
        let endDateString = formatDate(calendar.date(byAdding: .day, value: 1, to: today)!)
        request.predicate = NSPredicate(format: "dateString >= %@ AND dateString <= %@", startDateString, endDateString)
        
        var practiceDictionary: [String: Double] = [:]
        
        do {
            let practices = try viewContext.fetch(request)
            for practice in practices {
                if let dateString = practice.dateString {
                    practiceDictionary[dateString] = Double(practice.totalDuration) / 60.0
                }
            }
        } catch {
            print("获取周练习数据失败: \(error.localizedDescription)")
        }
        
        // 构建结果数组
        var result: [(String, Double)] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateString = formatDate(date)
                let minutes = practiceDictionary[dateString] ?? 0
                // 使用6-i来反向获取符号
                result.append((reorderedSymbols[6-i], minutes))
            }
        }
        
        return result  // 不需要再reversed()，因为已经通过索引调整了顺序
    }

    // 优化后的获取月热图数据的方法  
    func getMonthlyHeatmapData(for date: Date) -> [[Double]] {
        let calendar = Calendar.current
        
        // 获取指定月份的第一天和最后一天
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDayOfMonth = calendar.date(from: components),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth) else {
            return Array(repeating: Array(repeating: 0.0, count: 7), count: 6)
        }
        
        // 获取当月的天数
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
        let numberOfDaysInMonth = range.count
        
        // 当月第一天是星期几
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // 调整为以周一为第一天（0-6，周一为0，周日为6）
        let adjustedFirstWeekday = (firstDayWeekday + 5) % 7
        
        // 一次性查询整个月的数据
        let request = NSFetchRequest<DailyPractice>(entityName: "DailyPractice")
        let startDateString = formatDate(firstDayOfMonth)
        let endDateString = formatDate(nextMonth)
        request.predicate = NSPredicate(format: "dateString >= %@ AND dateString < %@", startDateString, endDateString)
        
        var practiceDictionary: [String: Double] = [:]
        
        do {
            let practices = try viewContext.fetch(request)
            for practice in practices {
                if let dateString = practice.dateString {
                    let totalMinutes = Double(practice.totalDuration) / 60.0
                    let heatValue = min(1.0, totalMinutes / 120.0) // 假设2小时是100%热度
                    practiceDictionary[dateString] = heatValue
                }
            }
        } catch {
            print("获取月练习数据失败: \(error.localizedDescription)")
        }
        
        // 创建热图数据
        var heatmapData = Array(repeating: Array(repeating: 0.0, count: 7), count: 6)
        
        // 填充数据
        for day in 1...numberOfDaysInMonth {
            let dayComponents = DateComponents(year: components.year, month: components.month, day: day)
            if let dayDate = calendar.date(from: dayComponents) {
                let dateString = formatDate(dayDate)
                
                // 计算行列
                let row = (day - 1 + adjustedFirstWeekday) / 7
                let col = (day - 1 + adjustedFirstWeekday) % 7
                
                // 从字典获取对应日期的热度值
                heatmapData[row][col] = practiceDictionary[dateString] ?? 0.0
            }
        }
        
        return heatmapData
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

    // 优化后的获取当前星期数据的方法
    func getCurrentWeekPracticeData() -> [(String, Double)] {
        // 创建以周一为第一天的日历
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2  // 设置周一为一周的第一天
        
        let today = Date()
        
        // 计算本周的周一日期
        let weekdayComponents = calendar.dateComponents([.weekday], from: today)
        let weekdayOrdinal = weekdayComponents.weekday!
        let daysToSubtract = weekdayOrdinal - calendar.firstWeekday
        guard let monday = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
            return []
        }
        
        // 获取星期几的本地化短名称，以周一为第一天
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let mondayFirstSymbols = Array(weekdaySymbols[calendar.firstWeekday-1..<weekdaySymbols.count] + weekdaySymbols[0..<calendar.firstWeekday-1])
        
        // 计算一周的结束日期（周日）
        guard let endDate = calendar.date(byAdding: .day, value: 7, to: monday) else {
            return []
        }
        
        // 一次性查询整周的数据
        let request = NSFetchRequest<DailyPractice>(entityName: "DailyPractice")
        let startDateString = formatDate(monday)
        let endDateString = formatDate(endDate)
        request.predicate = NSPredicate(format: "dateString >= %@ AND dateString < %@", startDateString, endDateString)
        
        var practiceDictionary: [String: Double] = [:]
        
        do {
            let practices = try viewContext.fetch(request)
            
            // 将查询结果存入字典，便于快速查找
            for practice in practices {
                if let dateString = practice.dateString {
                    practiceDictionary[dateString] = Double(practice.totalDuration) / 60.0
                }
            }
        } catch {
            print("获取周练习数据失败: \(error.localizedDescription)")
        }
        
        // 构建结果数组
        var result: [(String, Double)] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: monday) {
                // 检查是否超过今天
                if date > today {
                    result.append((mondayFirstSymbols[i], 0))
                } else {
                    let dateString = formatDate(date)
                    let minutes = practiceDictionary[dateString] ?? 0
                    result.append((mondayFirstSymbols[i], minutes))
                }
            }
        }
        
        return result
    }
}

