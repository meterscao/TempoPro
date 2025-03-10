import SwiftUI

struct PlaylistDetailView: View {
    @Environment(\.metronomeTheme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager // 更改类型
    @EnvironmentObject var metronomeState: MetronomeState
    
    // 修改为使用 CoreData Playlist 实体
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
                        
                        Text(playlist.name ?? "未命名歌单")
                            .font(.custom("MiSansLatin-Semibold", size: 24))
                            .foregroundColor(theme.backgroundColor)
                        
                        Spacer()
                        
                        Menu {
                            Button(action: {
                                resetSongForm()
                                isEditMode = false
                                showingSongForm = true
                                
                            }) {
                                Label("添加歌曲", systemImage: "plus.circle")
                            }
                            Button(action: {
                                // 准备编辑信息
                                editPlaylistName = playlist.name ?? ""
                                editPlaylistColor = Color(hex: playlist.color ?? "#0000FF") ?? .blue
                                showingEditPlaylist = true
                            }) {
                                Label("编辑歌单", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                // 删除整个歌单
                                playlistManager.deletePlaylist(playlist)
                                dismiss()
                            }) {
                                Label("删除歌单", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.custom("MiSansLatin-Regular", size: 20))
                                .foregroundColor(theme.backgroundColor)
                        }
                    }
                    
                    // 歌曲列表
                    let songs = playlist.songs?.allObjects as? [Song] ?? []
                    VStack(spacing: 16) {
                        if songs.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "music.note")
                                    .font(.custom("MiSansLatin-Regular", size: 50))
                                    .foregroundColor(theme.backgroundColor.opacity(0.7))
                                
                                Text("暂无歌曲")
                                    .font(.custom("MiSansLatin-Regular", size: 16))
                                    .foregroundColor(theme.backgroundColor)
                            }
                            .padding(.top, 40)
                        } else {
                            VStack(spacing: 16) {
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
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationBarHidden(true)
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
        .sheet(isPresented: $showingEditPlaylist) {
            EditPlaylistView(
                isPresented: $showingEditPlaylist,
                playlistName: $editPlaylistName,
                selectedColor: $editPlaylistColor,
                onSave: { name, color in
                    // 更新歌单
                    playlistManager.updatePlaylist(
                        playlist,
                        name: name,
                        color: color.toHex() ?? "#0000FF"
                    )
                }
            )
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
        metronomeState.togglePlayback()
        dismiss()
    }
}

// 新的歌曲卡片组件
struct SongRowCard: View {
    @Environment(\.metronomeTheme) var theme
    let song: Song
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPlay: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(song.name ?? "未命名歌曲")
                    .font(.custom("MiSansLatin-Semibold", size: 18))
                    .foregroundColor(theme.beatBarColor)
                
                Text("\(Int(song.bpm)) BPM · \(Int(song.beatsPerBar))/\(Int(song.beatUnit))")
                    .font(.custom("MiSansLatin-Regular", size: 14))
                    .foregroundColor(theme.primaryColor)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(theme.beatBarColor)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(theme.beatBarColor)
                }
            }
        }
        .padding(16)
        .background(theme.backgroundColor)
        .cornerRadius(16)
        .onTapGesture {
            onPlay()
        }
    }
}



