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
            ZStack {
                // 使用与PracticeStatsView相同的背景
                theme.primaryColor.ignoresSafeArea()
                // 添加噪声背景
                Image("bg-noise")
                    .resizable(resizingMode: .tile)
                    .opacity(0.06)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "arrow.left")
                                    .font(.custom("MiSansLatin-Regular", size: 20))
                                    .foregroundColor(theme.backgroundColor)
                            }
                            
                            Spacer()
                            
                            Text("我的歌单")
                                .font(.custom("MiSansLatin-Semibold", size: 24))
                                .foregroundColor(theme.backgroundColor)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddPlaylist = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.custom("MiSansLatin-Regular", size: 20))
                                    .foregroundColor(theme.backgroundColor)
                            }
                        }
                        
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
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
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
            }
            .navigationBarHidden(true)
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
        HStack(spacing: 16) {
            // 移除了图标部分
            
            VStack(alignment: .leading, spacing: 6) {
                Text(playlist.name ?? "未命名歌单")
                    .font(.custom("MiSansLatin-Semibold", size: 18))
                    .foregroundColor(theme.beatHightColor)
                
                Text("\(playlist.songs?.count ?? 0) 首歌曲")
                    .font(.custom("MiSansLatin-Regular", size: 14))
                    .foregroundColor(theme.primaryColor)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.custom("MiSansLatin-Regular", size: 16))
                .foregroundColor(theme.beatHightColor)
        }
        .padding(16)
        .background(theme.backgroundColor) // 去掉透明度
        .cornerRadius(16)
    }
}







