//
//  MetronomeInfoView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

// 添加节拍状态枚举
enum BeatStatus {
    case strong    // 最强
    case medium    // 次强
    case normal    // 普通
    case muted     // 静音
}

// 为 BeatStatus 添加循环切换方法
extension BeatStatus {
    func next() -> BeatStatus {
        switch self {
        case .muted:
            return .normal
        case .normal:
            return .medium
        case .medium:
            return .strong
        case .strong:
            return .muted
        }
    }
}

// 更新 BeatView 组件
struct BeatView: View {
    @State var status: BeatStatus
    var onStatusChanged: (BeatStatus) -> Void
    var isCurrentBeat: Bool
    var isPlaying: Bool  // 添加 isPlaying 参数
    
    private func barColors() -> [Color] {
        let colors: [Color] = switch status {
        case .strong:
            [Color.blue, Color.blue, Color.blue]
        case .medium:
            [Color.gray.opacity(0.2), Color.blue, Color.blue]
        case .normal:
            [Color.gray.opacity(0.2), Color.gray.opacity(0.2), Color.blue]
        case .muted:
            [Color.gray.opacity(0.2), Color.gray.opacity(0.2), Color.gray.opacity(0.2)]
        }
        
        // 只在播放状态下显示红色高亮
        return (isPlaying && isCurrentBeat) ? [Color.red, Color.red, Color.red] : colors
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(barColors()[index])
                    .frame(maxHeight: .infinity)
                    .cornerRadius(2)
            }
        }
        .onTapGesture {
            status = status.next()
            onStatusChanged(status)
        }
    }
}

struct MetronomeInfoView: View {
    let tempo: Double
    let beatsPerBar: Int
    let beatUnit: Int
    @Binding var showingKeypad: Bool
    @Binding var beatStatuses: [BeatStatus]
    let currentBeat: Int  // 添加当前拍子
    let isPlaying: Bool  // 添加 isPlaying 参数
    
    // 添加速度术语判断函数
    private func getTempoTerm(_ bpm: Double) -> String {
        switch bpm {
        case 0..<40:
            return "Grave"
        case 40..<45:
            return "Larghissimo"
        case 45..<50:
            return "Largo"
        case 50..<55:
            return "Lento"
        case 55..<65:
            return "Adagio"
        case 65..<75:
            return "Adagietto"
        case 75..<85:
            return "Andantino"
        case 85..<95:
            return "Andante"
        case 95..<108:
            return "Andante Moderato"
        case 108..<120:
            return "Moderato"
        case 120..<140:
            return "Allegretto"
        case 140..<160:
            return "Allegro"
        case 160..<176:
            return "Vivace"
        case 176..<200:
            return "Presto"
        case 200...:
            return "Prestissimo"
        default:
            return "Moderato"
        }
    }
    
    var body: some View {
        ZStack {
            Color.white  // 底色设为白色
            
            VStack(spacing: 20) {
                // 顶部工具栏
                HStack {
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                    }
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "timer")
                    }
                }

                
                // 节拍显示区域
                
                    HStack(spacing: 4) {
                        ForEach(0..<beatsPerBar, id: \.self) { beat in
                            BeatView(
                                status: beatStatuses[beat],
                                onStatusChanged: { newStatus in
                                    beatStatuses[beat] = newStatus
                                },
                                isCurrentBeat: beat == currentBeat,
                                isPlaying: isPlaying  // 传递 isPlaying 状态
                            )
                        }
                    }
                
                
                .padding(.horizontal)
                
                
                // 速度和拍号显示
                HStack(spacing: 30) {
                    // 拍号显示
                    HStack(spacing: 2) {
                        Text("\(beatsPerBar)")
                            .font(.system(size: 24, weight: .medium))
                        Text("/")
                            .font(.system(size: 24, weight: .medium))
                        Text("\(beatUnit)")
                            .font(.system(size: 24, weight: .medium))
                    }
                    
                    Spacer()
                    
                    // BPM 显示
                    VStack {
                        Text("\(Int(tempo))")
                            .font(.system(size: 42, weight: .medium))
                            .onTapGesture {
                                showingKeypad = true
                            }
                        Text(getTempoTerm(tempo))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    Text("切分")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.yellow)
            .padding(.horizontal, 10)
            .padding(.top, 10)
        }
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
        .ignoresSafeArea(.all, edges: [.horizontal, .bottom])  // 只忽略水平和底部安全区域
    }
}

#Preview {
    MetronomeInfoView(tempo: 120, beatsPerBar: 4, beatUnit: 4, showingKeypad: .constant(false), beatStatuses: .constant([.strong, .normal, .normal, .normal]), currentBeat: 0, isPlaying: false)
}
