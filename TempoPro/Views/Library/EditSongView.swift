//
//  EditSongView.swift
//  TempoPro
//
//  Created by Meters on 6/3/2025.
//
import SwiftUI

struct EditSongView: View {
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager
    @Binding var isPresented: Bool
    @Binding var songName: String
    @Binding var tempo: Int
    @Binding var beatsPerBar: Int
    @Binding var beatUnit: Int
    @Binding var beatStatuses: [BeatStatus]
    var isEditMode: Bool = false
    
    var onSave: (String, Int, Int, Int, [BeatStatus]) -> Void
    
    let beatUnits = [1, 2, 4, 8]
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                // 曲目名称部分
                Section {
                    
                    TextField("输入曲目名称", text: $songName)
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                        .placeholder(when: songName.isEmpty) {
                            Text("输入曲目名称")
                                .foregroundColor(Color("textSecondaryColor"))
                                .font(.custom("MiSansLatin-Regular", size: 16))
                        }
                        .focused($isNameFieldFocused)
                        
                } header: {
                    Text("曲目名称")
                        .font(.custom("MiSansLatin-Semibold", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                // BPM设置部分
                Section {
                    HStack(){
                        Text("BPM")
                            .font(.custom("MiSansLatin-Semibold", size: 14))
                            .foregroundColor(Color("textSecondaryColor"))   
                        Spacer()
                        HStack(spacing: 12) {
                                Button(action: {
                                if tempo > 30 {
                                    tempo -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color("textSecondaryColor"))
                            }
                            .buttonStyle(PlainButtonStyle())
                                
                            Text("\(tempo)")
                                .font(.custom("MiSansLatin-Semibold", size: 20))
                                .foregroundColor(Color("textPrimaryColor"))
                                .frame(width: 40, alignment: .center)
                                
                            Button(action: {
                                if tempo < 240 {
                                    tempo += 1
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color("textSecondaryColor"))
                            }
                            .buttonStyle(PlainButtonStyle())  
                            }   
                    }
                    VStack(){
                         Slider(value: Binding(
                                get: { Double(tempo) },
                                set: { tempo = Int($0) }
                            ), in: 30...240, step: 1)
                            
                    }
                    
                } header: {
                    Text("节拍速度")
                        .font(.custom("MiSansLatin-Semibold", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                // 拍号设置部分
                Section {
                    
                        // 拍子数
                        HStack {
                            Text("节拍数")
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .foregroundColor(Color("textPrimaryColor"))
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    if beatsPerBar > 1 {
                                        beatsPerBar -= 1
                                        updateBeatStatuses(count: beatsPerBar)
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color("textSecondaryColor"))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text("\(beatsPerBar)")
                                    .font(.custom("MiSansLatin-Semibold", size: 20))
                                    .foregroundColor(Color("textPrimaryColor"))
                                    .frame(width: 40, alignment: .center)
                                
                                Button(action: {
                                    if beatsPerBar < 16 {
                                        beatsPerBar += 1
                                        updateBeatStatuses(count: beatsPerBar)
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color("textSecondaryColor"))
                                }
                                .buttonStyle(PlainButtonStyle())    
                            }
                        }
                        
                        
                        
                        // 音符单位 - 修改为与拍子数相同的加减号交互
                        HStack {
                            Text("音符单位")
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .foregroundColor(Color("textPrimaryColor"))
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    if let index = beatUnits.firstIndex(of: beatUnit), index > 0 {
                                        beatUnit = beatUnits[index - 1]
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color("textSecondaryColor"))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text("\(beatUnit)")
                                    .font(.custom("MiSansLatin-Semibold", size: 20))
                                    .foregroundColor(Color("textPrimaryColor"))
                                    .frame(width: 40, alignment: .center)
                                
                                Button(action: {
                                    if let index = beatUnits.firstIndex(of: beatUnit), index < beatUnits.count - 1 {
                                        beatUnit = beatUnits[index + 1]
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color("textSecondaryColor"))
                                }
                                .buttonStyle(PlainButtonStyle())    
                            }
                        }
                    
                    
                } header: {
                    Text("拍号设置")
                    .font(.custom("MiSansLatin-Semibold", size: 14))
                    .foregroundColor(Color("textSecondaryColor"))
                }
                .listRowBackground(Color("backgroundSecondaryColor"))
                
                // 节拍强弱设置部分
                Section {
                        // 节拍按钮
                        VStack(alignment: .center, spacing: 8) {
                            FlowLayout(spacing: 8, maxCountPerRow: 8) {
                                ForEach(0..<beatsPerBar, id: \.self) { index in
                                    Button(action: {
                                        var newStatuses = beatStatuses
                                        // 修改循环顺序为: mute -> normal -> medium -> strong -> mute
                                        newStatuses[index] = nextBeatStatus(current: newStatuses[index])
                                        beatStatuses = newStatuses
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(getBeatStatusColor(beatStatuses[index]))
                                                .frame(width: 40, height: 40)
                                            
                                            Text("\(index + 1)")
                                                .font(.custom("MiSansLatin-Regular", size: 14))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())    
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                } header: {
                    Text("节拍强弱设置")
                        .font(.custom("MiSansLatin-Semibold", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                } footer: {
                    // 图例
                    HStack(spacing: 15) {
                        ForEach([BeatStatus.strong, BeatStatus.medium, BeatStatus.normal, BeatStatus.muted], id: \.self) { status in
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(getBeatStatusColor(status))
                                    .frame(width: 8, height: 8)
                                
                                Text(getBeatStatusName(status))
                                    .font(.custom("MiSansLatin-Regular", size: 12))
                                    .foregroundColor(Color("textSecondaryColor"))
                            }
                        }
                        
                        Spacer()
                    }
                }

                .listRowBackground(Color("backgroundSecondaryColor"))
            }
            .background(Color("backgroundPrimaryColor"))
            .scrollContentBackground(.hidden)
            .navigationTitle(isEditMode ? "编辑曲目" : "添加曲目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon-x")
                            .renderingMode(.template)
                            .foregroundColor(Color("textSecondaryColor"))
                    }
                    .buttonStyle(PlainButtonStyle())    
                    .padding(5)
                    .contentShape(Rectangle())
                }
                
                ToolbarItem(placement: .principal) {
                    Text(isEditMode ? "编辑曲目" : "添加曲目")
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if !songName.isEmpty {
                            onSave(songName, tempo, beatsPerBar, beatUnit, beatStatuses)
                            isPresented = false
                        }
                    }) {
                        Text(isEditMode ? "保存" : "添加")
                            .font(.custom("MiSansLatin-Semibold", size: 16))
                            .foregroundColor(songName.isEmpty ? Color("textSecondaryColor").opacity(0.5) : Color("AccentColor"))
                    }
                    .buttonStyle(PlainButtonStyle())    
                    .disabled(songName.isEmpty)
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
    
    private func updateBeatStatuses(count: Int) {
        var newStatuses = Array(repeating: BeatStatus.normal, count: count)
        
        for i in 0..<min(count, beatStatuses.count) {
            newStatuses[i] = beatStatuses[i]
        }
        
        if count > 0 && count > beatStatuses.count {
            newStatuses[0] = .strong
        }
        
        beatStatuses = newStatuses
    }
    
    // 自定义循环顺序: mute -> normal -> medium -> strong -> mute
    private func nextBeatStatus(current: BeatStatus) -> BeatStatus {
        switch current {
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
    
    private func getBeatStatusColor(_ status: BeatStatus) -> Color {
        switch status {
        case .strong:
            return .red
        case .medium:
            return .orange
        case .normal:
            return .gray
        case .muted:
            return .gray.opacity(0.2)
        }
    }
    
    private func getBeatStatusName(_ status: BeatStatus) -> String {
        switch status {
        case .strong:
            return "强拍"
        case .medium:
            return "次强拍"
        case .normal:
            return "弱拍"
        case .muted:
            return "静音"
        }
    }
}

// 为TextField添加placeholder样式
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// FlowLayout布局组件，用于按钮的自动换行
struct FlowLayout: Layout {
    var spacing: CGFloat
    var maxCountPerRow: Int
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let itemWidth: CGFloat = 40 // 按钮宽度
        let itemSpacing: CGFloat = spacing
        
        let rows = ceil(Double(subviews.count) / Double(maxCountPerRow))
        let height = rows * (itemWidth + itemSpacing) - itemSpacing
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        
        let itemWidth: CGFloat = 40 // 按钮宽度
        let itemSpacing: CGFloat = spacing
        
        var currentX: CGFloat = bounds.minX + (bounds.width - CGFloat(min(maxCountPerRow, subviews.count)) * (itemWidth + itemSpacing) + itemSpacing) / 2
        var currentY: CGFloat = bounds.minY
        var currentRow = 0
        
        for (index, subview) in subviews.enumerated() {
            let rowPosition = index % maxCountPerRow
            let row = index / maxCountPerRow
            
            if row != currentRow {
                currentRow = row
                currentY += itemWidth + itemSpacing
                currentX = bounds.minX + (bounds.width - CGFloat(min(maxCountPerRow, subviews.count - row * maxCountPerRow)) * (itemWidth + itemSpacing) + itemSpacing) / 2
            }
            
            if rowPosition == 0 && row > 0 {
                // 开始新的一行
            } else if rowPosition > 0 {
                currentX += itemWidth + itemSpacing
            }
            
            let point = CGPoint(x: currentX, y: currentY)
            subview.place(at: point, anchor: .topLeading, proposal: ProposedViewSize(width: itemWidth, height: itemWidth))
        }
    }
}
