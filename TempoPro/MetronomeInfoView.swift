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
    let currentBeat: Int
    let isPlaying: Bool
    @State private var showingTimeSignature = false
    @Binding var beatsPerBarBinding: Int
    @Binding var beatUnitBinding: Int
    
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
            Color.white
            
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
                    // 确保 beatStatuses 数组长度正确
                    let safeStatuses = ensureBeatStatusesLength(beatStatuses, count: beatsPerBar)
                    ForEach(0..<beatsPerBar, id: \.self) { beat in
                        BeatView(
                            status: safeStatuses[beat],
                            onStatusChanged: { newStatus in
                                var updatedStatuses = safeStatuses
                                updatedStatuses[beat] = newStatus
                                beatStatuses = updatedStatuses
                            },
                            isCurrentBeat: beat == currentBeat,
                            isPlaying: isPlaying
                        )
                    }
                }
                .padding(.horizontal)
                
                // 速度和拍号显示
                HStack(spacing: 30) {
                    // 拍号显示 - 添加点击手势
                    HStack(spacing: 2) {
                        Text("\(beatsPerBar)")
                            .font(.system(size: 24, weight: .medium))
                        Text("/")
                            .font(.system(size: 24, weight: .medium))
                        Text("\(beatUnit)")
                            .font(.system(size: 24, weight: .medium))
                    }
                    .onTapGesture {
                        showingTimeSignature = true
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
        .ignoresSafeArea(.all, edges: [.horizontal, .bottom])
        .sheet(isPresented: $showingTimeSignature) {
            TimeSignatureView(
                beatsPerBar: $beatsPerBarBinding,
                beatUnit: $beatUnitBinding
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // 添加一个辅助函数来确保数组长度正确
    private func ensureBeatStatusesLength(_ statuses: [BeatStatus], count: Int) -> [BeatStatus] {
        if statuses.count == count {
            return statuses
        }
        
        var newStatuses = Array(repeating: BeatStatus.normal, count: count)
        // 复制现有的状态
        for i in 0..<min(statuses.count, count) {
            newStatuses[i] = statuses[i]
        }
        // 确保第一拍是强拍
        if newStatuses.count > 0 {
            newStatuses[0] = .strong
        }
        
        DispatchQueue.main.async {
            // 异步更新绑定的数组，避免在视图更新过程中修改状态
            beatStatuses = newStatuses
        }
        
        return newStatuses
    }
}

#Preview {
    MetronomeInfoView(tempo: 120, beatsPerBar: 4, beatUnit: 4, showingKeypad: .constant(false), beatStatuses: .constant([.strong, .normal, .normal, .normal]), currentBeat: 0, isPlaying: false, beatsPerBarBinding: .constant(4), beatUnitBinding: .constant(4))
}
