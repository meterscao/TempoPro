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
    @EnvironmentObject var metronomeViewModel: MyViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    
    let wheelSizeRatio:Double = 0.83
    
    @State private var rotation: Double = 0
    @State private var lastAngle: Double = 0
    @State private var totalRotation: Double = 0
    @State private var startTempo: Int = 0
    @State private var isDragging: Bool = false
    @State private var lastBPMInt: Int = 0 // 记录上一个整数BPM值
    @State private var lastFeedbackTime: Date = Date.distantPast // 记录上次震动的时间

    @State private var playButtonSize: CGFloat = 96


    @AppStorage(AppStorageKeys.Settings.wheelScaleEnabled) private var wheelScaleEnabled = true
    
    // 反馈生成器
    private let feedbackGeneratorHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let feedbackGeneratorLight = UIImpactFeedbackGenerator(style: .light)
    // 最小震动间隔(秒)
    private let minimumFeedbackInterval: TimeInterval = 0.06
    
    @State private var isPlayButtonPressed = false
    
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
            ZStack{
                // 使用一个单独的ZStack容纳整个控制器
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
                           .rotationEffect(.degrees(rotation))

                        Image("bg-knob")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                            .frame(width: wheelSize, height: wheelSize)
                            .rotationEffect(.degrees(rotation))
                            .offset(x:1,y:1)
                            .opacity(0.5)
                    }
                    .frame(width: wheelSize-1, height: wheelSize-1)
                    .clipShape(Circle())
                    
                    ZStack() {
                        // Image("cymbal")
                        //     .resizable()
                        //     .scaledToFit()
                        //     .clipShape(
                        //         .circle
                        //     )
                        //     .frame(width: wheelSize, height: wheelSize)
                        
                        Image("bg-knob")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(theme.backgroundColor)
                            .frame(width: wheelSize, height: wheelSize)
                        Image(metronomeViewModel.isPlaying ? "icon-dot-playing" : "icon-dot-disabled")
                            .offset(x: wheelSize * 0.5 * 0.75, y: 0)
                    }
                    
                    .rotationEffect(.degrees(rotation))
                    
                    // 播放/停止按钮，添加点击效果
                    ZStack{
                        Image(metronomeViewModel.isPlaying ? "icon-pause" : "icon-play")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(theme.backgroundColor)
                            .frame(width: 28, height: 28)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .frame(width: playButtonSize - 2, height: playButtonSize - 2)
                            .offset(x:1,y:1)
                    )
                    .overlay(
                        Circle()
                            .stroke(theme.backgroundColor, lineWidth: 2)
                            .frame(width: playButtonSize-2, height: playButtonSize-2)
                    )
                    .frame(width: playButtonSize, height: playButtonSize)
                    
                    .background(
                        ZStack {
                            // 背景
                            Circle().fill(theme.primaryColor)
                            
                            // 点击效果半透明遮罩
                            Circle().fill(isPlayButtonPressed ? theme.backgroundColor.opacity(0.1) : Color.clear)
                            
                            // 噪点图案
                            Image("bg-noise")
                                .resizable(resizingMode: .tile)
                                .opacity(0.06)
                                .clipShape(Circle())
                                .background(
                                    .clear.shadow(.inner(color:.white,radius: 1,x:1,y: 1))
                                )
                        }
                    )
                    .contentShape(Circle())
                    .clipShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                isPlayButtonPressed = true
                            }
                            .onEnded { _ in
                                isPlayButtonPressed = false
                                metronomeViewModel.togglePlayback()
                            }
                    )
                }
                .frame(width: wheelSize, height: wheelSize)
                .position(x: geometry.size.width/2, y: geometry.size.height/2) // 明确定位在GeometryReader中心
                .ignoresSafeArea()
                .contentShape(Circle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                // 使用GeometryReader的中心点而不是构建新的frame
                                let centerPoint = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                                lastAngle = calculateAngle(location: value.location, in: CGRect(origin: .zero, size: geometry.size))
                                startTempo = metronomeViewModel.tempo
                                lastBPMInt = metronomeViewModel.tempo
                                feedbackGeneratorLight.prepare()
                                feedbackGeneratorHeavy.prepare()
                                print("开始拖动 - 初始位置: \(value.location), 初始角度: \(lastAngle)°, 初始速度: \(startTempo), 中心点: \(centerPoint)")
                            }
                            
                            // 不再构建新frame，直接使用GeometryReader的尺寸
                            let currentAngle = calculateAngle(location: value.location, in: CGRect(origin: .zero, size: geometry.size))
                            
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
                                currentBPMInt % 10 == 0 && wheelScaleEnabled ? feedbackGeneratorHeavy.impactOccurred() : feedbackGeneratorLight.impactOccurred()
                                
                                lastFeedbackTime = now
                            }
                            lastBPMInt = currentBPMInt
                            
                            metronomeViewModel.updateTempo(targetTempo)
                            print("拖动中 - 当前位置: \(value.location), 当前角度: \(currentAngle)°, 角度差: \(angleDiff)°, 总旋转: \(totalRotation)°, 实际旋转: \(rotation)°, 目标速度: \(targetTempo)")
                            lastAngle = currentAngle
                        }
                        .onEnded { _ in
                            isDragging = false
                            print("结束拖动 - 最终旋转: \(rotation)°, 最终速度: \(metronomeViewModel.tempo)")
                            totalRotation = 0
                        }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
    }
}

#Preview {
    MetronomeControlView()
        .environmentObject(MetronomeState())
} 
