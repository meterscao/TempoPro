import SwiftUI
import UIKit


struct PlaylistListView: View {
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager // 更改类型
    @State private var showingAddPlaylist = false
    @State private var newPlaylistName = ""
    @State private var selectedPlaylistColor = Color.blue
    
    init(){
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 直接在List中使用ForEach，不要嵌套VStack
                let playlists = playlistManager.fetchPlaylists()
                if playlists.isEmpty {
                    Text("暂无曲库")
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(theme.backgroundColor)
                        .padding(.top, 40)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(playlists) { playlist in
                        NavigationLink {
                            PlaylistDetailView(playlist: playlist)
                        } label: {
                            PlaylistRowCard(playlist: playlist)
                        }
                    }
                    .listRowBackground(Color("backgroundSecondaryColor"))
                }
            }
                
            // 使用Sheet展示添加曲库视图
            .sheet(isPresented: $showingAddPlaylist) {
                AddPlaylistView(
                    isPresented: $showingAddPlaylist,
                    playlistName: $newPlaylistName,
                    selectedColor: $selectedPlaylistColor,
                    onSave: { name, color in
                        // 使用 CoreDataPlaylistManager 创建曲库
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
                ToolbarItem(placement: .topBarLeading  ) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon-x")
                            .renderingMode(.template)
                            .foregroundColor(Color("textPrimaryColor"))
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .contentShape(Rectangle())
                }
                ToolbarItem(placement: .principal) {
                        Text("Libraries")
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action:{
                        showingAddPlaylist = true
                    }){
                        Text("Add Library")
                            .foregroundStyle(Color("textPrimaryColor"))
                    }
                    .background(Color("backgroundSecondaryColor"))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("backgroundPrimaryColor"))
            .scrollContentBackground(.hidden)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
        }
    }
}

// 重新设计的曲库行卡片
struct PlaylistRowCard: View {
    @Environment(\.metronomeTheme) var theme
    let playlist: Playlist
    
    var body: some View {
            
        VStack(alignment: .leading, spacing: 3) {
            Text(playlist.name ?? "未命名曲库")
                .font(.custom("MiSansLatin-Semibold", size: 17))
                .foregroundColor(Color("textPrimaryColor"))
            
            Text("\(playlist.songs?.count ?? 0) 首歌曲")
                .font(.custom("MiSansLatin-Regular", size: 14))
                .foregroundColor(Color("textSecondaryColor"))
        }
        
        
    }
}







