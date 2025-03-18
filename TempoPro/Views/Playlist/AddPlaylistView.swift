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
    
    
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.primaryColor.ignoresSafeArea()
                Image("bg-noise")
                    .resizable(resizingMode: .tile)
                    .opacity(0.06)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("曲库名称")
                                .font(.custom("MiSansLatin-Semibold", size: 18))
                                .foregroundColor(theme.backgroundColor)
                                .padding(.leading, 4)
                            
                            TextField("输入曲库名称", text: $playlistName)
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .padding()
                                .background(theme.backgroundColor)
                                .cornerRadius(12)
                                .foregroundColor(theme.beatBarColor)
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
                                
                                Text("保存曲库")
                                    .font(.custom("MiSansLatin-Semibold", size: 16))
                                    .foregroundColor(theme.backgroundColor)
                            }
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(playlistName.isEmpty ? theme.beatBarColor.opacity(0.3) : theme.beatBarColor)
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
            .navigationBarTitle("新建曲库", displayMode: .inline)
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
                    Text("新建曲库")
                        .font(.custom("MiSansLatin-Semibold", size: 20))
                        .foregroundColor(theme.backgroundColor)
                }
            }
        }
    }
}
