//
//  BPMKeypadView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct BPMKeypadView: View {
    @EnvironmentObject var metronomeState: MetronomeState
    @EnvironmentObject var metronomeViewModel: MyViewModel
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State private var inputValue: String = ""
    @State private var pressedButton: Int? = nil // 用于跟踪当前按下的按钮
    @State private var isClearPressed = false // 用于清除按钮
    @State private var isZeroPressed = false // 用于0按钮
    @State private var isSetPressed = false // 用于设置按钮
    
    private let buttonHeight: CGFloat = 60
    private let gridSpacing: CGFloat = 10    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
        
                VStack(spacing: gridSpacing) {
                    ZStack(alignment: .trailing) {
                        Text(inputValue.isEmpty ? "\(metronomeViewModel.tempo)"  : inputValue)
                        .font(.custom("MiSansLatin-Semibold", size: 36))
                        .frame(maxWidth: .infinity)
                        .frame(height: buttonHeight)
                        .foregroundColor(inputValue.isEmpty ? Color("textSecondaryColor").opacity(0.5)   : Color("textPrimaryColor"))
                        .background(Color("backgroundSecondaryColor"))
                        .cornerRadius(10)

                        if !inputValue.isEmpty {
                            Button(action: {

                                if !inputValue.isEmpty {
                                    inputValue.removeLast()
                                    // 添加触觉反馈
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()


                                }
                            }) {
                                Image("icon-delete")
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Color("textSecondaryColor"))
                            }
                            .padding(.trailing, 20)
                        }
                    }
                    
                    
                    VStack(spacing: gridSpacing) {
                        ForEach(0..<4) { row in
                            HStack(spacing: gridSpacing) {
                                if row < 3 {
                                    ForEach(1...3, id: \.self) { col in
                                        let number = row * 3 + col
                                        VStack() {
                                            Text("\(number)")
                                                
                                                .frame(maxWidth: .infinity)
                                                .frame(height: buttonHeight)
                                                .foregroundColor(Color("textPrimaryColor"))
                                                .background(Color("backgroundSecondaryColor"))
                                                .cornerRadius(10)
                                                .opacity(pressedButton == number ? 0.6 : 1.0)
                                        }
                                        .onTapGesture {
                                            if inputValue.count < 3 {
                                                // 设置按下状态
                                                pressedButton = number
                                                
                                                // 添加触觉反馈
                                                let generator = UIImpactFeedbackGenerator(style: .light)
                                                generator.impactOccurred()
                                                
                                                // 延迟恢复状态
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    pressedButton = nil
                                                    inputValue += "\(number)"
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    VStack() {
                                        Text("TAP")
                                            .frame(maxWidth: .infinity)
                                            .frame(height: buttonHeight)
                                            .background(Color("textSecondaryColor"))
                                            .foregroundColor(Color("backgroundPrimaryColor"))
                                            .font(.custom("MiSansLatin-Semibold", size: 18))
                                            .cornerRadius(10)
                                            .opacity(isClearPressed ? 0.6 : 1.0)
                                    }
                                    .onTapGesture {
                                        // 设置按下状态
                                        isClearPressed = true
                                        
                                        // 添加触觉反馈
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        
                                        
                                    }
                                    
                                    VStack() {
                                        Text("0")
                                            
                                            .frame(maxWidth: .infinity)
                                            .frame(height: buttonHeight)
                                            .foregroundColor(Color("textPrimaryColor"))
                                            .background(Color("backgroundSecondaryColor"))
                                            .cornerRadius(10)
                                            .opacity(isZeroPressed ? 0.6 : 1.0)
                                    }
                                    .onTapGesture {
                                        if inputValue.count < 3 {
                                            // 设置按下状态
                                            isZeroPressed = true
                                            
                                            // 添加触觉反馈
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                            
                                            // 延迟恢复状态
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                isZeroPressed = false
                                                inputValue += "0"
                                            }
                                        }
                                    }

                                    
                                    VStack() {
                                        Text("SET")
                                            
                                            .frame(maxWidth: .infinity)
                                            .frame(height: buttonHeight)
                                            .font(.custom("MiSansLatin-Semibold", size: 18))
                                            .background(Color("textSecondaryColor"))
                                            .foregroundColor(Color("backgroundPrimaryColor"))
                                            .cornerRadius(10)
                                            .opacity(isSetPressed ? 0.6 : 1.0)
                                    }
                                    .onTapGesture{
                                        // 设置按下状态
                                        isSetPressed = true
                                        
                                        // 添加触觉反馈
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        
                                        // 延迟恢复状态
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            isSetPressed = false
                                            
                                            if let value = Int(inputValue) {
                                                let tempo = max(30, min(240, value))
                                                metronomeViewModel.updateTempo(tempo)
                                            }
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .background(Color("backgroundPrimaryColor"))
                .font(.custom("MiSansLatin-Regular", size: 22))
                .padding(20)
            }
            .foregroundColor(Color("textPrimaryColor"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("BPM")
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon-x")
                            .renderingMode(.template)
                            .foregroundColor(Color("textSecondaryColor"))
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .contentShape(Rectangle())
                }
            }
            .background(Color("backgroundPrimaryColor"))
            .scrollContentBackground(.hidden)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    BPMKeypadView()
        .environmentObject(MetronomeState())
}
