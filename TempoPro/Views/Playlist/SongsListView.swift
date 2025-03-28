import SwiftUI

struct SongsListView: View {
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager
    @EnvironmentObject var metronomeState: MetronomeState
    
    
    @State private var currentPlaylist: Playlist?
    @State private var showingSongForm = false
    @State private var isEditMode = false
    @State private var showingEditPlaylist = false
    @State private var editPlaylistName = ""
    @State private var editPlaylistColor = Color.blue
    @State private var songName = ""
    @State private var tempo = 120
    @State private var beatsPerBar = 4
    @State private var beatUnit = 4
    @State private var beatStatuses: [BeatStatus] = Array(repeating: .normal, count: 4)
    @State private var showingDeleteAlert = false
    @State private var songToDelete: Song?
    @State private var songToEdit: Song?
    @State private var isShowLibraryList: Bool = false
    
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(){
                ScrollView(.horizontal, showsIndicators: false) {
                    let playlists = playlistManager.fetchPlaylists()
                    HStack(spacing: 10){
                        ForEach(playlists) { playlist in
                                Button(action: {
                                    currentPlaylist = playlist
                                }) {
                                    HStack(spacing: 5){
                                        Image("icon-gallery-vertical-end")
                                            .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                    Text(playlist.name ?? "未命名曲库")
                                        .font(.custom("MiSansLatin-Regular", size: 14))
                                        
                                }
                                .foregroundColor(currentPlaylist == playlist ? Color("backgroundPrimaryColor") : Color("textPrimaryColor"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(currentPlaylist == playlist ? Color("textPrimaryColor") : Color("backgroundSecondaryColor"))
                                .cornerRadius(6)
                            }
                        }
                    }.padding(.vertical, 20)
                }
                .frame(maxWidth: .infinity)
                

                HStack(){
                    Button(action: {
                             resetSongForm()
                             isEditMode = false
                             showingSongForm = true
                    }) {
                        Text("保存")
                            .font(.custom("MiSansLatin-Semibold", size: 16))
                            .foregroundColor(Color("textPrimaryColor"))
                    }
                    Button(action: {
                        isShowLibraryList.toggle()
                    }) {
                        Text("编辑")
                            .font(.custom("MiSansLatin-Semibold", size: 16))
                            .foregroundColor(Color("textPrimaryColor"))
                    }
                }
            }
            .padding(.horizontal, 20)
            
            ListView {
                // 曲目列表
                let songs = currentPlaylist?.songs?.allObjects as? [Song] ?? []
                    if songs.isEmpty {
                        VStack(alignment: .center, spacing: 10) {
                            Image("icon-disc-3-xl")
                                .renderingMode(.template)
                                .foregroundColor(Color("textSecondaryColor"))
                            
                            Button(action: {
                                showingSongForm = true
                            }) {
                                HStack(spacing: 5) {    
                                    Text("添加曲目")
                                        .font(.custom("MiSansLatin-Regular", size: 16))
                                        .foregroundColor(Color("textPrimaryColor"))
                                }
                            }   
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color("backgroundSecondaryColor"))

                    } else {
                        SectionView {
                            
                                ForEach(songs, id: \.id) { song in
                                    SongRowCard(song: song, onEdit: {
                                        prepareEditSong(song)
                                    }, onDelete: {
                                        songToDelete = song
                                        showingDeleteAlert = true
                                    }, onPlay: {
                                        playSong(song)
                                    })
                                }
                            
                                
                            
                        }
                        
                    }
                
            }
            .contentInset(.top, 0)
            
            
        //     .toolbar {
        //         ToolbarItem(placement: .navigationBarTrailing) {
        //             Menu {
        //                 Section{
        //                     Button(action: {
        //                         resetSongForm()
        //                         isEditMode = false
        //                         showingSongForm = true
        //                     }) {
                                
        //                             Text("添加曲目")
        //                                 .foregroundColor(Color("textPrimaryColor"))
                                
        //                     }
        //                 }
                        
        //                 Section {
        //                     Button(action: {
        //                         editPlaylistName = playlist.name ?? ""
        //                         showingEditPlaylist = true
        //                     }) {
        //                             Text("编辑曲库")
        //                                 .foregroundColor(Color("textPrimaryColor"))
                                
        //                     }
                            
        //                     Button(role: .destructive, action: {
        //                         playlistManager.deletePlaylist(playlist)
        //                         dismiss()
        //                     }) {
                                
        //                             Text("删除曲库")
        //                                 .foregroundColor(Color("textPrimaryColor"))
                            
        //                     }
        //                 }
        //             } label: {
        //                 Image("icon-ellipsis")
        //                     .renderingMode(.template)
        //                     .foregroundColor(Color("textPrimaryColor"))
        //             }
        //         }
        //     }
        }
        .fullScreenCover(isPresented: $isShowLibraryList, content: {
            LibraryListView()
        })
        .background(Color("backgroundPrimaryColor"))
        .sheet(isPresented: $showingSongForm) {
            EditSongView(
                isPresented: $showingSongForm,
                songName: $songName,
                tempo: $tempo,
                beatsPerBar: $beatsPerBar,
                beatUnit: $beatUnit,
                beatStatuses: $beatStatuses,
                isEditMode: isEditMode,
                onSave: { name, tempo, beatsPerBar, beatUnit, statuses in
                    let statusInts = statuses.map { status -> Int in
                        switch status {
                        case .strong: return 0
                        case .medium: return 1
                        case .normal: return 2
                        case .muted: return 3
                        }
                    }
                    
                    if isEditMode, let song = songToEdit {
                        // 更新现有曲目
                        playlistManager.updateSong(
                            song,
                            name: name,
                            bpm: tempo,
                            beatsPerBar: beatsPerBar,
                            beatUnit: beatUnit,
                            beatStatuses: statusInts,
                            subdivisionPattern: "quarter_whole"
                        )
                    } else {
                        // 添加新曲目
                        _ = playlistManager.addSong(
                            to: currentPlaylist!,
                            name: name,
                            bpm: tempo,
                            beatsPerBar: beatsPerBar,
                            beatUnit: beatUnit,
                            beatStatuses: statusInts,
                            subdivisionPattern: "quarter_whole"
                        )
                    }
                    
                    // 重置表单
                    resetSongForm()
                }
            )
        }
        .alert("编辑曲库", isPresented: $showingEditPlaylist) {
            TextField("曲库名称", text: $editPlaylistName)
            Button("取消", role: .cancel) { 
                editPlaylistName = currentPlaylist?.name ?? ""
            }
            Button("保存") {
                if !editPlaylistName.isEmpty {
                    // 更新曲库
                    playlistManager.updatePlaylist(
                        currentPlaylist!,
                        name: editPlaylistName,
                        color: currentPlaylist!.color ?? "#0000FF" // 保持原来的颜色
                    )
                }
            }.disabled(editPlaylistName.isEmpty)
        } message: {
            Text("请输入曲库的新名称")
        }
        
        .alert("确认删除", isPresented: $showingDeleteAlert, actions: {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let song = songToDelete {
                    // 删除曲目
                    playlistManager.deleteSong(song)
                }
            }
        }, message: {
            Text("确定要删除这首曲目吗？此操作不可撤销。")
        })
        .onAppear {
            currentPlaylist = playlistManager.fetchPlaylists().first
        }
    }
    
    private func resetSongForm() {
        songName = ""
        tempo = 120
        beatsPerBar = 4
        beatUnit = 4
        beatStatuses = Array(repeating: .normal, count: 4)
        beatStatuses[0] = .strong
        songToEdit = nil
    }
    
    private func prepareEditSong(_ song: Song) {
        // 填充表单数据
        songName = song.name ?? ""
        tempo = Int(song.bpm)
        beatsPerBar = Int(song.beatsPerBar)
        beatUnit = Int(song.beatUnit)
        
        // 转换节拍状态
        let statusInts = (song.beatStatuses as? [Int]) ?? Array(repeating: 2, count: beatsPerBar)
        beatStatuses = statusInts.map { intValue -> BeatStatus in
            switch intValue {
            case 0: return .strong
            case 1: return .medium
            case 3: return .muted
            default: return .normal
            }
        }
        
        songToEdit = song
        isEditMode = true
        showingSongForm = true
    }
    
    private func playSong(_ song: Song) {
        // 设置节拍器状态
        metronomeState.updateTempo(Int(song.bpm))
        metronomeState.updateBeatsPerBar(Int(song.beatsPerBar))
        metronomeState.updateBeatUnit(Int(song.beatUnit))
        metronomeState.updateSubdivisionPattern(SubdivisionManager.getSubdivisionPattern(byName: song.subdivisionPattern ?? "quarter_whole")!)
        
        // 转换节拍状态
        let statusInts = (song.beatStatuses as? [Int]) ?? Array(repeating: 2, count: Int(song.beatsPerBar))
        let statuses = statusInts.map { intValue -> BeatStatus in
            switch intValue {
            case 0: return .strong
            case 1: return .medium
            case 3: return .muted
            default: return .normal
            }
        }
        metronomeState.updateBeatStatuses(statuses)
        
        // 返回主界面并启动节拍器
        metronomeState.play()
        // dismiss()
    }
}

// 修改曲目卡片组件样式以匹配
struct SongRowCard: View {
    @Environment(\.metronomeTheme) var theme
    let song: Song
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPlay: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(song.name ?? "未命名曲目")
                    .font(.custom("MiSansLatin-Semibold", size: 16))
                    .foregroundColor(Color("textPrimaryColor"))
                
                HStack(spacing: 0){
                    Text("\(Int(song.bpm)) BPM · \(Int(song.beatsPerBar))/\(Int(song.beatUnit)) · ")
                        .font(.custom("MiSansLatin-Regular", size: 14))
                        .foregroundColor(Color("textSecondaryColor"))
                    Image(song.subdivisionPattern ?? "quarter_whole")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 22, height: 22)
                        .foregroundColor(Color("textSecondaryColor"))
                }
                
            }
            
            Spacer()
            
            // 播放按钮
            Button(action: onPlay) {
                Image("icon-play")
                    .renderingMode(.template)   
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color("textPrimaryColor"))
            }
        }
        .contentShape(Rectangle()) // 确保整个区域可点击
        .onTapGesture {
            onPlay()
        }
        
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
            
            Button(action: onEdit) {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}



