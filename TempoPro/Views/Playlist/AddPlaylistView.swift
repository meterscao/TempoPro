//
//  AddPlaylistView.swift
//  TempoPro
//
//  Created by Meters on 6/3/2025.
//
import SwiftUI

struct AddPlaylistView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager
    @Binding var isPresented: Bool
    @Binding var playlistName: String
    @Binding var selectedColor: Color
    var onSave: (String, Color) -> Void
    
    let colors: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink,
        Color(hex: "#1E90FF") ?? .blue,
        Color(hex: "#8B4513") ?? .brown,
        Color(hex: "#2E8B57") ?? .green,
        Color(hex: "#9932CC") ?? .purple,
        Color(hex: "#FF6347") ?? .red,
        Color(hex: "#4682B4") ?? .blue
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    TextField("歌单名称", text: $playlistName)
                        .font(.system(size: 18, design: .rounded))
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择颜色")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textColor)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitle("新建歌单", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    if !playlistName.isEmpty {
                        onSave(playlistName, selectedColor)
                        isPresented = false
                    }
                }
                .disabled(playlistName.isEmpty)
            )
        }
    }
}
