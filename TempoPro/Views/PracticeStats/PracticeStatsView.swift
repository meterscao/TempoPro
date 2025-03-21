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
    
    init(){
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Summary - 替换为新的组件
                    StatsSummaryView()
                    
                    // Weekly Streak
                    WeeklyStatsView()
                    
                    // Monthly Heatmap
                    MonthlyHeatmapView()
                    
                    // Performance Insights
                    PerformanceInsightsView()
                }
                .padding(.top,20)
                .padding(.horizontal, 20)
            }
            .foregroundStyle(Color("textPrimaryColor"))
            .navigationBarTitleDisplayMode(.inline)
            
            .background(Color("backgroundPrimaryColor"))
            
            .toolbar {
                ToolbarItem(placement: .principal) {
                        Text("Stats")
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon-x") 
                            .renderingMode(.template)
                            .foregroundColor(Color.textPrimary)
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .contentShape(Rectangle())
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("backgroundPrimaryColor"))
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
            
        }
    }
}

// 统计摘要视图组件
struct StatsSummaryView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var practiceManager: CoreDataPracticeManager
    
    // 状态变量
    @State private var dayStreak = 0
    @State private var daysThisMonth = 0
    @State private var totalHours = 0.0
    
    var body: some View {
        HStack(spacing: 10) {
            StatsSummaryCard(value: "\(dayStreak)", label: "STREAK DAYS")
            StatsSummaryCard(value: "\(daysThisMonth)", label: "TOTAL DAYS")
            StatsSummaryCard(value: String(format: "%.1f", totalHours), label: "TOTAL HOURS")
        }
        .onAppear {
            loadSummaryData()
        }
    }
    
    // 加载统计摘要数据
    private func loadSummaryData() {
        // 连续练习天数
        dayStreak = practiceManager.getCurrentStreak()
        
        // 当月练习天数
        daysThisMonth = practiceManager.getPracticeDaysInCurrentMonth()
        
        // 总练习时间
        totalHours = practiceManager.getTotalPracticeHours()
    }
}

// 绩效洞察视图组件
struct PerformanceInsightsView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var practiceManager: CoreDataPracticeManager
    
    // 状态变量
    @State private var mostPracticedTempo = ""
    @State private var longestSession = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("INSIGHTS")
                .font(.custom("MiSansLatin-Semibold", size: 20))
                .foregroundColor(Color("textPrimaryColor"))
            
            VStack(spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MOST PRACTICED TEMPO")
                            .font(.custom("MiSansLatin-Regular", size: 12))
                            .foregroundColor(Color("textSecondaryColor"))
                        
                        Text(mostPracticedTempo)
                            .font(.custom("MiSansLatin-Semibold", size: 18))
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(theme.primaryColor.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image("icon-circle-gauge-s")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16,height: 16)
                            .foregroundColor(Color("backgroundSecondaryColor")) 
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LONGEST SESSION")
                            .font(.custom("MiSansLatin-Regular", size: 12))
                            .foregroundColor(Color("textSecondaryColor"))
                        
                        Text(longestSession)
                            .font(.custom("MiSansLatin-Semibold", size: 18))
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(theme.primaryColor.opacity(0.1))
                            
                            .frame(width: 32, height: 32)
                        
                        Image("icon-clock-s")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16,height: 16)
                            .foregroundColor(Color("backgroundSecondaryColor")) 
                    }
                }
            }
        }
        .padding(20)
        .background(Color("backgroundSecondaryColor"))
        .cornerRadius(16)
        .onAppear {
            loadInsightsData()
        }
    }
    
    // 加载洞察数据
    private func loadInsightsData() {
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
        VStack(spacing: 5) {
            Text(value)
                .font(.custom("MiSansLatin-Semibold", size: 28))
                .foregroundColor(theme.primaryColor)
            
            Text(label)
                .font(.custom("MiSansLatin-Regular", size: 12))
                .foregroundColor(Color("textSecondaryColor"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical,15)
        .background(Color("backgroundSecondaryColor"))
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
