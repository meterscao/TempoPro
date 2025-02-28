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
    @State private var inputValue: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(inputValue.isEmpty ? "0" : inputValue)
                    .font(.system(size: 48, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
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
                                            .font(.title2)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                }
                            } else {
                                Button(action: {
                                    inputValue = ""
                                }) {
                                    Text("CLEAR")
                                        .font(.title2)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    if inputValue.count < 3 {
                                        inputValue += "0"
                                    }
                                }) {
                                    Text("0")
                                        .font(.title2)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    if let value = Double(inputValue) {
                                        tempo = max(30, min(240, value))
                                    }
                                    isPresented = false
                                }) {
                                    Text("SET")
                                        .font(.title2)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    BPMKeypadView(isPresented: .constant(false), tempo: .constant(120))
} 