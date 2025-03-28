import SwiftUI
import UIKit

struct LibraryListView: View {
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager // 更改类型
    @State private var showingAddAlert = false // 新的状态变量，控制弹窗显示
    @State private var newPlaylistName = ""
    
    
    init(){
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }
    
    var body: some View {
        NavigationStack {
            
            VStack(spacing: 0){
                

                ListView {
                    // 直接在List中使用ForEach，不要嵌套VStack
                    let playlists = playlistManager.fetchPlaylists()
                    if playlists.isEmpty {
                        Text("暂无曲库")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                            .foregroundColor(theme.backgroundColor)
                            .padding(.top, 40)
                            .listRowBackground(Color.clear)
                    } else {
                        SectionView{
                            ForEach(playlists) { playlist in
                                NavigationLink {
                                    SongsListView()
                                } label: {
                                    PlaylistRowCard(playlist: playlist)
                                }.foregroundStyle(Color("textSecondaryColor"))
                            }
                        }
                        
                    }
                    
                    // 添加曲库的 cell
                    Button(action: {
                        showingAddAlert = true
                    }) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color("textPrimaryColor").opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Image("icon-plus-s")
                                    .renderingMode(.template)
                                    .foregroundStyle(Color("textPrimaryColor"))
                            }
                            
                            Text("添加曲库")
                                .font(.custom("MiSansLatin-Semibold", size: 17))
                                .foregroundColor(Color("textPrimaryColor"))
                            
                            Spacer()
                        }
                    }
                    .listRowBackground(Color("backgroundSecondaryColor"))
                }

                .alert("添加曲库", isPresented: $showingAddAlert) {
                    TextField("曲库名称", text: $newPlaylistName)
                    Button("取消", role: .cancel) { 
                        newPlaylistName = ""
                    }
                    Button("添加") {
                        if !newPlaylistName.isEmpty {
                            // 创建新曲库
                            _ = playlistManager.createPlaylist(
                                name: newPlaylistName,
                                color: "#0000FF" // 使用默认蓝色
                            )
                            newPlaylistName = ""
                        }
                    }.disabled(newPlaylistName.isEmpty)
                } message: {
                    Text("请输入新曲库的名称")
                }
                
                
                .background(Color("backgroundPrimaryColor"))
                .scrollContentBackground(.hidden)

                .navigationDestination(for: Playlist.self) { playlist in
                    SongsListView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon-x")
                            .renderingMode(.template)
                            .foregroundColor(Color("textSecondaryColor"))
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
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("backgroundPrimaryColor"))
            .scrollContentBackground(.hidden)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar)
            .navigationDestination(for: Playlist.self) { playlist in
                SongsListView()
            }
            
        }
    }
}

// 重新设计的曲库行卡片
struct PlaylistRowCard: View {
    @Environment(\.metronomeTheme) var theme
    let playlist: Playlist
    
    var body: some View {
            
        HStack(){
            ZStack(){
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color("textPrimaryColor").opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image("icon-gallery-vertical-end-s")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color("textPrimaryColor"))
            }   
            VStack(alignment: .leading, spacing: 0) {
                Text(playlist.name ?? "未命名曲库")
                    .font(.custom("MiSansLatin-Semibold", size: 17))
                    .foregroundColor(Color("textPrimaryColor"))
                
                Text("\(playlist.songs?.count ?? 0) songs")
                    .font(.custom("MiSansLatin-Regular", size: 13))
                    .foregroundColor(Color("textSecondaryColor"))
            }
            Spacer()
            Image("icon-chevron-right")
                .renderingMode(.template)
                .foregroundStyle(Color("textSecondaryColor"))
        }
        
        
        
    }
}







