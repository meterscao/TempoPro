//
//  BPMKeypadView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct BPMKeypadView: View {
    @EnvironmentObject var metronomeState: MetronomeState
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State private var inputValue: String = ""
    private let buttonHeight: CGFloat = 60
    private let gridSpacing: CGFloat = 10    
    
    var body: some View {
            ZStack {
                theme.backgroundColor
        
                VStack(spacing: gridSpacing) {
                    Text(inputValue.isEmpty ? "0" : inputValue)
                        .font(.custom("MiSansLatin-Semibold", size: 36))
                        .frame(maxWidth: .infinity)
                        .frame(height: buttonHeight)
                        .foregroundColor(theme.backgroundColor)
                        .background(theme.primaryColor)
                        .cornerRadius(10)
                    
                    VStack(spacing: gridSpacing) {
                        ForEach(0..<4) { row in
                            HStack(spacing: gridSpacing) {
                                if row < 3 {
                                    ForEach(1...3, id: \.self) { col in
                                        let number = row * 3 + col
                                        Button(action: {
                                            if inputValue.count < 3 {
                                                inputValue += "\(number)"
                                            }
                                        }) {
                                            Text("\(number)")
                                                
                                                .frame(maxWidth: .infinity)
                                                .frame(height: buttonHeight)
                                                .foregroundColor(theme.backgroundColor)
                                                .background(theme.primaryColor)
                                                .cornerRadius(10)
                                        }
                                        
                                    }
                                } else {
                                    Button(action: {
                                        inputValue = ""
                                    }) {
                                        Text("CLEAR")
                                            
                                            .frame(maxWidth: .infinity)
                                            .frame(height: buttonHeight)
                                            .foregroundColor(theme.backgroundColor)
                                            .background(theme.primaryColor)
                                            .font(.custom("MiSansLatin-Semibold", size: 18))
                                            .cornerRadius(10)
                                    }
                                    
                                    Button(action: {
                                        if inputValue.count < 3 {
                                            inputValue += "0"
                                        }
                                    }) {
                                        Text("0")
                                            
                                            .frame(maxWidth: .infinity)
                                            .frame(height: buttonHeight)
                                            .foregroundColor(theme.backgroundColor)
                                            .background(theme.primaryColor)
                                            .cornerRadius(10)
                                    }
                                    
                                    Button(action: {
                                        if let value = Int(inputValue) {
                                            
                                            let tempo = max(30, min(240, value))
                                            metronomeState.updateTempo(tempo)
                                        }
                                        dismiss()
                                    }) {
                                        Text("SET")
                                            
                                            .frame(maxWidth: .infinity)
                                            .frame(height: buttonHeight)
                                            .font(.custom("MiSansLatin-Semibold", size: 18))
                                            .background(theme.primaryColor)
                                            .foregroundColor(theme.backgroundColor)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                }
            .ignoresSafeArea()
            .font(.custom("MiSansLatin-Regular", size: 22))
            .padding(20)
            }
            
    }
}

#Preview {
    BPMKeypadView()
        .environmentObject(MetronomeState())
}
