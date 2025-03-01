//
//  BPMKeypadView.swift
//  TempoPro
//
//  Created by Meters on 26/2/2025.
//

import SwiftUI

struct BPMKeypadView: View {
    @Binding var isPresented: Bool
    @Binding var tempo: Double
    @Environment(\.metronomeTheme) var theme
    @State private var inputValue: String = ""
    private let buttonHeight: CGFloat = 60
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(inputValue.isEmpty ? "0" : inputValue)
                        
                        .font(.custom("MiSansLatin-Semibold", size: 36))
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(theme.backgroundColor.opacity(0.2))
                    .cornerRadius(10)
                
                VStack(spacing: 15) {
                    ForEach(0..<4) { row in
                        HStack(spacing: 15) {
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
                                            .background(theme.backgroundColor.opacity(0.3))
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
                                        .background(theme.backgroundColor.opacity(0.3))
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
                                        .background(theme.backgroundColor.opacity(0.3))
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    if let value = Double(inputValue) {
                                        tempo = max(30, min(240, value))
                                    }
                                    isPresented = false
                                }) {
                                    Text("SET")
                                        
                                        .frame(maxWidth: .infinity)
                                        .frame(height: buttonHeight)
                                        .background(theme.backgroundColor)
                                        .foregroundColor(theme.primaryColor)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
            }
            .font(.custom("MiSansLatin-Semibold", size: 22))
            .padding()
            .padding(.bottom, 20)
            .background(theme.backgroundColor.opacity(0.1))
            .background(theme.primaryColor)
        }
    }
}

#Preview {
    BPMKeypadView(isPresented: .constant(false), tempo: .constant(120))
} 