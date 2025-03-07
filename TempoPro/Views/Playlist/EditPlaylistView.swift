//
//  EditPlaylistView.swift
//  TempoPro
//
//  Created by Meters on 6/3/2025.
//
import SwiftUI

struct EditPlaylistView: View {
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
                theme.primaryColor.ignoresSafeArea()
                Image("bg-noise")
                    .resizable(resizingMode: .tile)
                    .opacity(0.06)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing:28) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("歌单名称")
                                .font(.custom("MiSansLatin-Semibold", size: 18))
                                .foregroundColor(theme.backgroundColor)
                                .padding(.leading, 4)
                            
                            TextField("输入歌单名称", text: $playlistName)
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .padding()
                                .background(theme.backgroundColor)
                                .cornerRadius(12)
                                .foregroundColor(theme.beatHightColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("选择颜色")
                                .font(.custom("MiSansLatin-Semibold", size: 18))
                                .foregroundColor(theme.backgroundColor)
                                .padding(.leading, 4)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60, maximum: 70))], spacing: 20) {
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            ZStack {
                                                if selectedColor == color {
                                                    Circle()
                                                        .stroke(theme.backgroundColor, lineWidth: 3)
                                                    
                                                    Image(systemName: "checkmark")
                                                        .font(.custom("MiSansLatin-Bold", size: 24))
                                                        .foregroundColor(theme.backgroundColor)
                                                }
                                            }
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                        }
                                }
                            }
                            .padding(8)
                        }
                        
                        Button(action: {
                            if !playlistName.isEmpty {
                                onSave(playlistName, selectedColor)
                                isPresented = false
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle")
                                    .font(.custom("MiSansLatin-Regular", size: 16))
                                    .foregroundColor(theme.backgroundColor)
                                
                                Text("保存修改")
                                    .font(.custom("MiSansLatin-Semibold", size: 16))
                                    .foregroundColor(theme.backgroundColor)
                            }
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(playlistName.isEmpty ? theme.beatHightColor.opacity(0.3) : theme.beatHightColor)
                            .cornerRadius(12)
                        }
                        .disabled(playlistName.isEmpty)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitle("编辑歌单", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.custom("MiSansLatin-Regular", size: 20))
                            .foregroundColor(theme.backgroundColor)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("编辑歌单")
                        .font(.custom("MiSansLatin-Semibold", size: 20))
                        .foregroundColor(theme.backgroundColor)
                }
            }
        }
    }
}
