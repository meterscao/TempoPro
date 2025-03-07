//
//  MetronomeControlView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI
import UIKit // 导入UIKit以使用震动反馈功能

struct MetronomeControlView: View {
    
    private let sensitivity: Double = 12.0 // 旋转灵敏度
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var metronomeState: MetronomeState
    
    
    let wheelSizeRatio:Double = 0.72
    
    @State private var rotation: Double = 0
    @State private var lastAngle: Double = 0
    @State private var totalRotation: Double = 0
    @State private var startTempo: Int = 0
    @State private var isDragging: Bool = false
    @State private var lastBPMInt: Int = 0 // 记录上一个整数BPM值
    @State private var lastFeedbackTime: Date = Date.distantPast // 记录上次震动的时间
    
    // 反馈生成器
    private let feedbackGeneratorHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let feedbackGeneratorLight = UIImpactFeedbackGenerator(style: .light)
    // 最小震动间隔(秒)
    private let minimumFeedbackInterval: TimeInterval = 0.06
    

    
    private func calculateAngle(location: CGPoint, in frame: CGRect) -> Double {
        let centerX = frame.midX
        let centerY = frame.midY
        let deltaX = location.x - centerX
        let deltaY = location.y - centerY
        
        var angle = atan2(deltaY, deltaX) * (180 / .pi)
        if angle < 0 {
            angle += 360
        }
        return angle
    }
    
    var body: some View {
        GeometryReader { geometry in
            let wheelSize = geometry.size.width * wheelSizeRatio
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                
                ZStack() {
                    Image("bg-noise")
                        .resizable(resizingMode: .tile)
                        .opacity(0.06)
                        .clipShape(
                            .circle
                        )
                        .frame(width: wheelSize, height: wheelSize)
                        .background(Circle().fill(theme.primaryColor).frame(width: wheelSize,height: wheelSize))
                    Image("bg-knob")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(theme.backgroundColor)
                        .frame(width: wheelSize, height: wheelSize)
                    Image(metronomeState.isPlaying ? "icon-dot-playing" : "icon-dot-disabled")
                    .offset(x: wheelSize * 0.5 * 0.75, y: 0)
                }
                
                .rotationEffect(.degrees(rotation))
                
                Button(action: {
                    metronomeState.togglePlayback()
                }) {
                    Image(systemName: metronomeState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(theme.backgroundColor)
                        
                        .frame(width: 80, height: 80)
                        
                }

               
                    
            }
            
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            let frame = CGRect(
                                x: (geometry.size.width - wheelSize) / 2,
                                y: (geometry.size.height - wheelSize) / 2,
                                width: wheelSize,
                                height: wheelSize
                            )
                            lastAngle = calculateAngle(location: value.location, in: frame)
                            startTempo = metronomeState.tempo
                            lastBPMInt = metronomeState.tempo // 初始化上一个BPM值
                            feedbackGeneratorLight.prepare() // 准备反馈生成器
                            feedbackGeneratorHeavy.prepare()
                            print("开始拖动 - 初始角度: \(lastAngle)°, 初始速度: \(startTempo)")
                        }
                        
                        let frame = CGRect(
                            x: (geometry.size.width - wheelSize) / 2,
                            y: (geometry.size.height - wheelSize) / 2,
                            width: wheelSize,
                            height: wheelSize
                        )
                        let currentAngle = calculateAngle(location: value.location, in: frame)
                        
                        var angleDiff = currentAngle - lastAngle
                        
                        if angleDiff > 180 {
                            angleDiff -= 360
                        } else if angleDiff < -180 {
                            angleDiff += 360
                        }
                        
                        totalRotation += angleDiff
                        rotation += angleDiff
                        
                        let tempoChange = Int(round(totalRotation / sensitivity))
                        let targetTempo = max(30, min(320, startTempo + tempoChange))
                        
                        // 检查BPM是否变化了整数单位，并提供震动反馈
                        let currentBPMInt = targetTempo
                        let now = Date()
                        if currentBPMInt != lastBPMInt && 
                           now.timeIntervalSince(lastFeedbackTime) >= minimumFeedbackInterval {
                            currentBPMInt % 10 == 0 ? feedbackGeneratorHeavy.impactOccurred() : feedbackGeneratorLight.impactOccurred()
                            
                            lastFeedbackTime = now
                        }
                        lastBPMInt = currentBPMInt
                        
                        metronomeState.updateTempo(targetTempo)
                        print("拖动中 - 当前角度: \(currentAngle)°, 角度差: \(angleDiff)°, 总旋转: \(totalRotation)°, 实际旋转: \(rotation)°, 目标速度: \(targetTempo)")
                        lastAngle = currentAngle
                    }
                    .onEnded { _ in
                        isDragging = false
                        print("结束拖动 - 最终旋转: \(rotation)°, 最终速度: \(metronomeState.tempo)")
                        totalRotation = 0
                    }
            )
            
            
        }
    }
}

#Preview {
    MetronomeControlView()
        .environmentObject(MetronomeState())
} 
