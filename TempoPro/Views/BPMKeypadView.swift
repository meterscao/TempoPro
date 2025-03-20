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
            ScrollView {
                
        
                VStack(spacing: gridSpacing) {
                    Text(inputValue.isEmpty ? "\(metronomeState.tempo)"  : inputValue)
                        .font(.custom("MiSansLatin-Semibold", size: 36))
                        .frame(maxWidth: .infinity)
                        .frame(height: buttonHeight)
                        .foregroundColor(inputValue.isEmpty ? Color("textSecondaryColor").opacity(0.5)   : Color("textPrimaryColor"))
                        .background(Color("backgroundSecondaryColor"))
                        .cornerRadius(10)
                    
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
                                        }.onTapGesture {
                                            if inputValue.count < 3 {
                                                inputValue += "\(number)"
                                            }
                                        }   
                                        
                                    }
                                } else {
                                    VStack() {
                                        Text("CLEAR")
                                            
                                            .frame(maxWidth: .infinity)
                                            .frame(height: buttonHeight)
                                            .background(Color("textSecondaryColor"))
                                            .foregroundColor(Color("backgroundPrimaryColor"))
                                            .font(.custom("MiSansLatin-Semibold", size: 18))
                                            .cornerRadius(10)
                                    }.onTapGesture {
                                        inputValue = ""
                                    }   
                                    
                                    VStack() {
                                        Text("0")
                                            
                                            .frame(maxWidth: .infinity)
                                            .frame(height: buttonHeight)
                                            .foregroundColor(Color("textPrimaryColor"))
                                            .background(Color("backgroundSecondaryColor"))
                                            .cornerRadius(10)
                                    }.onTapGesture {
                                        
                                        if inputValue.count < 3 {
                                            inputValue += "0"
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
                                    }
                                    .onTapGesture{
                                        if let value = Int(inputValue) {
                                            
                                            let tempo = max(30, min(240, value))
                                            metronomeState.updateTempo(tempo)
                                        }
                                        dismiss()
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
            .background(Color("backgroundPrimaryColor"))
            
    }
}

#Preview {
    BPMKeypadView()
        .environmentObject(MetronomeState())
}
