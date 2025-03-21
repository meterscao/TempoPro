//
//  TimeSignatureView.swift
//  TempoPro
//
//  Created by Meters on 27/2/2025.
//

import SwiftUI

struct TimeSignatureView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var metronomeState: MetronomeState
    @Environment(\.metronomeTheme) var theme
    
    // 可选的拍号单位
    private let availableBeatUnits = [1, 2, 4, 8]
    
    init(){
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView() {
                VStack(spacing:20){
                    // 拍号设置
                    VStack() {
                        // 使用非交互的 Section 内容包装器，让按钮可以正常工作
                        ZStack {
                            HStack(spacing: 0) {
                                // 每小节拍数
                                VStack(alignment: .center, spacing: 5) {
                                    Text("Beats")
                                        .font(.custom("MiSansLatin-Semibold", size: 14))
                                        .foregroundColor(Color("textSecondaryColor"))
                                    
                                    HStack(spacing: 20) {
                                        // 使用明确的 buttonStyle 和足够大的点击区域
                                        Button {
                                            if metronomeState.beatsPerBar > 1 {
                                                metronomeState.updateBeatsPerBar(metronomeState.beatsPerBar - 1)
                                            }
                                        } label: {
                                            Image("icon-minus")
                                                .renderingMode(.template)
                                                .foregroundStyle(Color("textSecondaryColor"))
                                                .frame(width: 44, height: 44) // 增大点击区域
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Text("\(metronomeState.beatsPerBar)")
                                            .font(.custom("MiSansLatin-Semibold", size: 32))
                                        
                                        Button {
                                            if metronomeState.beatsPerBar < 12 {
                                                metronomeState.updateBeatsPerBar(metronomeState.beatsPerBar + 1)
                                            }
                                        } label: {
                                            Image("icon-plus")
                                                .renderingMode(.template)
                                                .foregroundStyle(Color("textSecondaryColor"))
                                                .frame(width: 44, height: 44) // 增大点击区域
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .background(theme.primaryColor.opacity(0.3))
                                    .frame(maxHeight:.infinity)
                                    .padding(.horizontal, 8)
                                
                                // 拍号单位
                                VStack(alignment: .center, spacing: 5) {
                                    Text("Time Signature")
                                        .font(.custom("MiSansLatin-Semibold", size: 14))
                                        .foregroundColor(Color("textSecondaryColor"))
                                    
                                    HStack(spacing: 20) {
                                        Button {
                                            if let index = availableBeatUnits.firstIndex(of: metronomeState.beatUnit),
                                               index > 0 {
                                                metronomeState.updateBeatUnit(availableBeatUnits[index - 1])
                                            }
                                        } label: {
                                            Image("icon-minus")
                                                .renderingMode(.template)
                                                .foregroundStyle(Color("textSecondaryColor"))
                                                
                                                .frame(width: 44, height: 44) // 增大点击区域
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Text("\(metronomeState.beatUnit)")
                                            .font(.custom("MiSansLatin-Semibold", size: 32))
                                        
                                        Button {
                                            if let index = availableBeatUnits.firstIndex(of: metronomeState.beatUnit),
                                               index < availableBeatUnits.count - 1 {
                                                metronomeState.updateBeatUnit(availableBeatUnits[index + 1])
                                            }
                                        } label: {
                                            Image("icon-plus")
                                                .renderingMode(.template)
                                                .foregroundStyle(Color("textSecondaryColor"))
                                                .frame(width: 44, height: 44) // 增大点击区域
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(15)
                        .background(Color("backgroundSecondaryColor"))
                        .cornerRadius(15)
                        
                    }
                    
                    
                    // 切分音符部分
                    VStack() {
                        let patterns = SubdivisionManager.getSubdivisionPatterns(forBeatUnit: metronomeState.beatUnit)
                        
                        if patterns.isEmpty {
                            Text("当前拍号单位没有预设的切分音符")
                                .font(.custom("MiSansLatin-Regular", size: 14))
                                .foregroundColor(theme.primaryColor.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 10)
                        } else {
                            VStack(spacing: 0) {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(),spacing:2),
                                    GridItem(.flexible(),spacing:2),
                                    GridItem(.flexible(),spacing:2),
                                    GridItem(.flexible(),spacing:2),
                                    GridItem(.flexible(),spacing:2),
                                ], spacing: 2) {
                                    ForEach(patterns, id: \.name) { pattern in
                                        Button {
                                            metronomeState.updateSubdivisionPattern(pattern)
                                        } label: {
                                            Image(pattern.name)
                                                .resizable()
                                                .renderingMode(.template)
                                                .scaledToFit()
                                                .padding(6)
                                                .frame(height: 60)
                                                .foregroundStyle(metronomeState.subdivisionPattern?.name == pattern.name ?
                                                                 Color("backgroundSecondaryColor") : Color("textSecondaryColor") )
                                        }
                                        .frame(maxWidth:.infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(metronomeState.subdivisionPattern?.name == pattern.name ?
                                                      Color("textPrimaryColor") : Color("backgroundSecondaryColor")
                                                     )
                                        )
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            
                        }
                    }
                }
                .padding(.horizontal,20)
                .padding(.top,5)
                
                
            }
            .foregroundColor(Color("textPrimaryColor"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Time Signature")
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon-x")
                            .renderingMode(.template)
                            .foregroundColor(Color("textPrimaryColor"))
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .contentShape(Rectangle())
                }
            }
            .background(Color("backgroundPrimaryColor"))
            .scrollContentBackground(.hidden)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            
        }
    }
}

#Preview {
    TimeSignatureView()
        .environmentObject(MetronomeState())
}
