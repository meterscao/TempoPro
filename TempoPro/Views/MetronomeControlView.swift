//
//  MetronomeControlView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct MetronomeControlView: View {
    
    private let sensitivity: Double = 9.0 // 旋转灵敏度
    
    @Binding var tempo: Double
    @Binding var isPlaying: Bool
    let beatsPerBar: Int
    let wheelSizeRatio:Double = 0.72
    
    @State private var rotation: Double = 0
    @State private var lastAngle: Double = 0
    @State private var totalRotation: Double = 0
    @State private var startTempo: Double = 0
    @State private var isDragging: Bool = false
    
    private func createTicks(wheelSize:Double) -> some View {
        
        
            
            ZStack {
                ForEach(0..<60) { i in
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 1, height: 10)
                        .offset(y: -(wheelSize/2 - 10))
                        .rotationEffect(.degrees(Double(i) * 6))
                }
                ForEach(0..<12) { i in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 2, height: 20)
                        .offset(y: -(wheelSize/2 - 15))
                        .rotationEffect(.degrees(Double(i) * 30))
                }
            }
        
    }
    
    private func calculateAngle(location: CGPoint, in frame: CGRect) -> Double {
        let centerX = frame.width / 2
        let centerY = frame.height / 2
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
            let screenWidth = geometry.size.width
            
            let wheelSize = geometry.size.width * wheelSizeRatio
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                
                ZStack() {
                    Image("bg-knob")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: wheelSize, height: wheelSize)
                        
                    Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                    .offset(x: wheelSize * 0.5 * 0.75, y: 0)
                }
                
                .rotationEffect(.degrees(rotation))
                
                Button(action: {
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.black)
                }

               
                    
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            lastAngle = calculateAngle(
                                location: value.location,
                                in: CGRect(x: 0, y: 0, width: wheelSize, height: wheelSize)
                            )
                            startTempo = tempo
                        }
                        
                        let currentAngle = calculateAngle(
                            location: value.location,
                            in: CGRect(x: 0, y: 0, width: wheelSize, height: wheelSize)
                        )
                        
                        var angleDiff = currentAngle - lastAngle
                        
                        if angleDiff > 180 {
                            angleDiff -= 360
                        } else if angleDiff < -180 {
                            angleDiff += 360
                        }
                        
                        totalRotation += angleDiff
                        rotation += angleDiff
                        
                        let tempoChange = round(totalRotation / sensitivity)
                        let targetTempo = max(30, min(320, startTempo + tempoChange))
                        
                        tempo = targetTempo
                        lastAngle = currentAngle
                    }
                    .onEnded { _ in
                        isDragging = false
                        totalRotation = 0
                    }
            )
            
            
        }
    }
}

#Preview {
    MetronomeControlView(tempo: .constant(120), isPlaying: .constant(false), beatsPerBar: 4)
} 
