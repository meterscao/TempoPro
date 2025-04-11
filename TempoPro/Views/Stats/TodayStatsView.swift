//
//  TodayStatsView.swift
//  TempoPro
//
//  Created by XiaoFeng on 2025/4/11.
//


import SwiftUI

struct TodayStatsView: View {
    
    @EnvironmentObject var practiceManager: CoreDataPracticeManager
    @State private var todayPracticeMinutes: Double = 0
    
    // 定义常用的目标时间选项
    private let goalOptions = [15, 30, 45, 60, 90, 120]
    private let mySettingsService = MySettingsService()
    
    @AppStorage(AppStorageKeys.Stats.dailyGoalMinutes) private var dailyGoalMinutes: Int = 45
    
    var progress: Double {
        min(todayPracticeMinutes / Double(dailyGoalMinutes), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Daily Goal")
                    .font(.custom("MiSansLatin-Semibold", size: 20))
                    .foregroundColor(Color("textPrimaryColor"))
                
                Spacer()
                
                Menu {
                    ForEach(goalOptions, id: \.self) { minutes in
                        Button(action: {
                            dailyGoalMinutes = minutes
                        }) {
                            HStack {
                                Text("\(minutes) min")
                                if dailyGoalMinutes == minutes {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                } label: {
                  
                       Image("icon-ellipsis")
                           .renderingMode(.template)
                           .foregroundColor(Color("textSecondaryColor"))
                  
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Int(todayPracticeMinutes))/\(dailyGoalMinutes) min")
                        .font(.custom("MiSansLatin-Regular", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                    
                    Spacer()
                    
                    // // 添加完成百分比
                    // Text("\(Int(progress * 100))%")
                    //     .font(.custom("MiSansLatin-Regular", size: 14))
                    //     .foregroundColor(Color("textSecondaryColor"))
                }
                
                HStack(spacing: 8) {
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color("AccentColor").opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color("AccentColor"))
                                .frame(width: geometry.size.width * progress, height: 8)
                        }
                        .frame(height: 8)
                        .padding(.vertical, 7) // 调整垂直居中
                    }
                    
                    // 完成状态圆形指示器
                    ZStack {
                        Circle()
                            .fill(progress >= 1.0 ? Color("AccentColor") : Color("AccentColor").opacity(0.2))
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(progress >= 1.0 ? .white : Color("AccentColor").opacity(0.5))
                    }
                    .frame(width: 22, height: 22)
                }
                .frame(height: 22) // 与圆形指示器保持一致的高度
            }
        }
        .padding(20)
        .background(Color("backgroundSecondaryColor"))
        .cornerRadius(16)
        .onAppear {
            updateTodayProgress()
        }
    }
    
    private func updateTodayProgress() {
        // 从practiceManager获取今天的练习时长
        todayPracticeMinutes = practiceManager.getTodayPracticeMinutes()
    }
}

struct TodayStatsView_Previews: PreviewProvider {
    static var previews: some View {
        TodayStatsView()
    }
}
