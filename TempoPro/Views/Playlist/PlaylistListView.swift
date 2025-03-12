import SwiftUI


struct PlaylistListView: View {
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager // 更改类型
    @State private var showingAddPlaylist = false
    @State private var newPlaylistName = ""
    @State private var selectedPlaylistColor = Color.blue
    
    var body: some View {
        NavigationStack {
            List {
                    // 歌单列表 - 改为使用 CoreData 并采用卡片式设计
                    let playlists = playlistManager.fetchPlaylists()
                    VStack(spacing: 16) {
                        if playlists.isEmpty {
                            Text("暂无歌单")
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .foregroundColor(theme.backgroundColor)
                                .padding(.top, 40)
                        } else {
                            ForEach(playlists) { playlist in
                                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                    PlaylistRowCard(playlist: playlist)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
            }
                
            // 使用Sheet展示添加歌单视图
            .sheet(isPresented: $showingAddPlaylist) {
                AddPlaylistView(
                    isPresented: $showingAddPlaylist,
                    playlistName: $newPlaylistName,
                    selectedColor: $selectedPlaylistColor,
                    onSave: { name, color in
                        // 使用 CoreDataPlaylistManager 创建歌单
                        _ = playlistManager.createPlaylist(
                            name: name,
                            color: color.toHex() ?? "#0000FF"
                        )
                        
                        newPlaylistName = ""
                        selectedPlaylistColor = .blue
                    }
                )
            }

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(InsetGroupedListStyle())
            .background(theme.backgroundColor)
            .scrollContentBackground(.hidden)
            .toolbarBackground(theme.backgroundColor, for: .navigationBar) 
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
        }
    }
}

// 重新设计的歌单行卡片
struct PlaylistRowCard: View {
    @Environment(\.metronomeTheme) var theme
    let playlist: Playlist
    
    var body: some View {
            
        VStack(alignment: .leading, spacing: 6) {
            Text(playlist.name ?? "未命名歌单")
                .font(.custom("MiSansLatin-Semibold", size: 18))
                .foregroundColor(theme.primaryColor)
            
            Text("\(playlist.songs?.count ?? 0) 首歌曲")
                .font(.custom("MiSansLatin-Regular", size: 14))
                .foregroundColor(theme.primaryColor.opacity(0.8))
        }
        
    }
}







