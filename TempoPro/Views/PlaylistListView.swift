import SwiftUI

struct PlaylistListView: View {
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playlistManager: PlaylistManager
    @State private var showingAddPlaylist = false
    @State private var newPlaylistName = ""
    @State private var selectedPlaylistColor = Color.blue
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部标题
                    HStack {
                        Text("我的歌单")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textColor)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddPlaylist = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                    .padding([.horizontal, .top], 20)
                    .padding(.bottom, 10)
                    
                    // 歌单列表
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(playlistManager.playlists) { playlist in
                                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                    PlaylistRow(playlist: playlist)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.textColor.opacity(0.7))
                }
            )
            .sheet(isPresented: $showingAddPlaylist) {
                AddPlaylistView(
                    isPresented: $showingAddPlaylist,
                    playlistName: $newPlaylistName,
                    selectedColor: $selectedPlaylistColor,
                    onSave: { name, color in
                        let newPlaylist = PlaylistModel(
                            id: UUID(),
                            name: name,
                            songs: [],
                            color: color.toHex() ?? "#0000FF"
                        )
                        playlistManager.addPlaylist(newPlaylist)
                        newPlaylistName = ""
                        selectedPlaylistColor = .blue
                    }
                )
            }
        }
    }
}

struct PlaylistRow: View {
    @Environment(\.metronomeTheme) var theme
    let playlist: PlaylistModel
    
    var body: some View {
        HStack(spacing: 16) {
            // 歌单颜色标识
            RoundedRectangle(cornerRadius: 10)
                .fill(playlist.getColor())
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "music.note.list")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )
                .shadow(color: playlist.getColor().opacity(0.3), radius: 5, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textColor)
                
                Text("\(playlist.songs.count) 首歌曲")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textColor.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(theme.primaryColor.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct AddPlaylistView: View {
    @Environment(\.metronomeTheme) var theme
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

#Preview {
    PlaylistListView()
} 
