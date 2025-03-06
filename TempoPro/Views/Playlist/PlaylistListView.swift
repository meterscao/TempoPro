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
                    
                    // 歌单列表 - 改为使用 CoreData
                    let playlists = playlistManager.fetchPlaylists()
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(playlists) { playlist in
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
    }
}







