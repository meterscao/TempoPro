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
    
    // Mock data
    let dayStreak = 12
    let daysThisMonth = 23
    let hoursTotal = 18.5
    
    // Weekly practice data (in minutes)
    let weeklyData = [
        ("MON", 70),
        ("TUE", 100),
        ("WED", 40),
        ("THU", 80),
        ("FRI", 60),
        ("SUN", 120),
        ("SAT", 50)
    ]
    
    // Monthly heatmap data (opacity values)
    let monthlyData: [[Double]] = [
        [0.3, 0.5, 0.6, 0.4, 0.7, 0.8, 0.3],
        [0.4, 0.0, 0.5, 0.7, 0.9, 1.0, 0.4],
        [0.6, 0.7, 0.8, 0.7, 0.9, 1.0, 0.6],
        [0.7, 0.8, 0.7, 0.9, 1.0, 0.9, 0.8]
    ]
    
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
                        StatsSummaryCard(value: "\(hoursTotal)", label: "TOTAL HOURS")
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
                                HStack(alignment: .bottom, spacing: 0) {
                                    ForEach(0..<weeklyData.count, id: \.self) { index in
                                        let day = weeklyData[index]
                                        let barWidth = (geometry.size.width - CGFloat(weeklyData.count - 1) * 8) / CGFloat(weeklyData.count)
                                        
                                        VStack(spacing: 8) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(theme.beatHightColor)
                                                .frame(width: barWidth, height: CGFloat(day.1))
                                            
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
                                    Text("45 MIN")
                                        .font(.custom("MiSansLatin-Regular", size: 12))
                                        .foregroundColor(theme.primaryColor.opacity(0.9))
                                    Spacer()
                                    Text("2H 15M")
                                        .font(.custom("MiSansLatin-Regular", size: 12))
                                        .foregroundColor(theme.primaryColor.opacity(0.9))
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
                            Text("MARCH 2025")
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
                            ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                                Text(day)
                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(theme.beatHightColor)
                            }
                        }
                        
                        // 只让热力图在GeometryReader中
                        GeometryReader { geometry in
                            // Calendar grid
                            let cellWidth = (geometry.size.width - 24) / 7 // Accounting for spacing
                            VStack(spacing: 8) {
                                ForEach(0..<4, id: \.self) { row in
                                    HStack(spacing: 4) {
                                        ForEach(0..<7, id: \.self) { col in
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
                                    
                                    Text("120-140 BPM")
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
                                    
                                    Text("1H 45M (MAR 15)")
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
            
        }
            
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
