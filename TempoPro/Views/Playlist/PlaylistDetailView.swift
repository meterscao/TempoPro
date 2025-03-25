import SwiftUI

struct PlaylistDetailView: View {
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager
    @EnvironmentObject var metronomeState: MetronomeState
    
    @ObservedObject var playlist: Playlist
    
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
    
    var body: some View {
        NavigationStack {
            List {
                // 歌曲列表
                let songs = playlist.songs?.allObjects as? [Song] ?? []
                
                    if songs.isEmpty {
                        VStack(alignment: .center, spacing: 20) {
                            Image(systemName: "music.note")
                                .font(.custom("MiSansLatin-Regular", size: 50))
                                .foregroundColor(Color("textSecondaryColor"))
                            
                            Text("暂无歌曲")
                                .font(.custom("MiSansLatin-Regular", size: 16))
                                .foregroundColor(Color("textPrimaryColor"))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(songs, id: \.id) { song in
                            SongRowCard(song: song, onEdit: {
                                prepareEditSong(song)
                            }, onDelete: {
                                songToDelete = song
                                showingDeleteAlert = true
                            }, onPlay: {
                                playSong(song)
                            })
                            .listRowBackground(Color("backgroundSecondaryColor"))
                        }
                    }
                
            }
            .navigationTitle(playlist.name ?? "未命名曲库")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("backgroundPrimaryColor"))
            .scrollContentBackground(.hidden)
            .toolbarBackground(Color("backgroundPrimaryColor"), for: .navigationBar) 
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            resetSongForm()
                            isEditMode = false
                            showingSongForm = true
                        }) {
                            Label {
                                Text("添加歌曲")
                                    .foregroundColor(Color("textPrimaryColor"))
                            } icon: {
                                Image("icon-plus-s")
                                    .renderingMode(.template)
                                    .foregroundColor(Color("textPrimaryColor"))
                            }
                        }
                        
                        Button(action: {
                            editPlaylistName = playlist.name ?? ""
                            showingEditPlaylist = true
                        }) {
                            Label {
                                Text("编辑曲库")
                                    .foregroundColor(Color("textPrimaryColor"))
                            } icon: {
                                Image("icon-pencil-s")
                                    .renderingMode(.template)
                                    .foregroundColor(Color("textPrimaryColor"))
                            }
                        }
                        
                        Button(role: .destructive, action: {
                            playlistManager.deletePlaylist(playlist)
                            dismiss()
                        }) {
                            Label {
                                Text("删除曲库")
                                    .foregroundColor(Color("textPrimaryColor"))
                            } icon: {
                                Image("icon-trash-2-s")
                                    .renderingMode(.template)
                                    .foregroundColor(Color("textPrimaryColor"))
                            }
                        }
                    } label: {
                        Image("icon-ellipsis")
                            .renderingMode(.template)
                            .foregroundColor(Color("textPrimaryColor"))
                    }
                }
            }
        }
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
                        // 更新现有歌曲
                        playlistManager.updateSong(
                            song,
                            name: name,
                            bpm: tempo,
                            beatsPerBar: beatsPerBar,
                            beatUnit: beatUnit,
                            beatStatuses: statusInts
                        )
                    } else {
                        // 添加新歌曲
                        _ = playlistManager.addSong(
                            to: playlist,
                            name: name,
                            bpm: tempo,
                            beatsPerBar: beatsPerBar,
                            beatUnit: beatUnit,
                            beatStatuses: statusInts
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
                editPlaylistName = playlist.name ?? ""
            }
            Button("保存") {
                if !editPlaylistName.isEmpty {
                    // 更新曲库
                    playlistManager.updatePlaylist(
                        playlist,
                        name: editPlaylistName,
                        color: playlist.color ?? "#0000FF" // 保持原来的颜色
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
                    // 删除歌曲
                    playlistManager.deleteSong(song)
                }
            }
        }, message: {
            Text("确定要删除这首歌曲吗？此操作不可撤销。")
        })
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

// 修改歌曲卡片组件样式以匹配
struct SongRowCard: View {
    @Environment(\.metronomeTheme) var theme
    let song: Song
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPlay: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(song.name ?? "未命名歌曲")
                    .font(.custom("MiSansLatin-Semibold", size: 17))
                    .foregroundColor(Color("textPrimaryColor"))
                
                HStack(){
                    Text("\(Int(song.bpm)) BPM · \(Int(song.beatsPerBar))/\(Int(song.beatUnit))")
                        .font(.custom("MiSansLatin-Regular", size: 13))
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



