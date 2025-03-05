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
            theme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 歌单标题
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color(hex: playlist.color ?? "#0000FF") ?? .blue)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color(hex: playlist.color ?? "#0000FF")?.opacity(0.3) ?? .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(playlist.name ?? "未命名歌单")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textColor)
                        
                        let songCount = playlist.songs?.count ?? 0
                        Text("\(songCount) 首歌曲")
                            .font(.system(size: 16))
                            .foregroundColor(theme.textColor.opacity(0.6))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .background(theme.textColor.opacity(0.1))
                    .padding(.horizontal, 20)
                
                // 歌曲列表 - 使用 CoreData 获取歌曲
                let songs = playlist.songs?.allObjects as? [Song] ?? []
                if songs.isEmpty {
                    // 显示空状态...
                    VStack {
                        Spacer()
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(theme.textColor.opacity(0.2))
                            .padding(.bottom, 20)
                        
                        Text("暂无歌曲")
                            .font(.system(size: 18, design: .rounded))
                            .foregroundColor(theme.textColor.opacity(0.5))
                        
                        Button(action: {
                            resetSongForm()
                            isEditMode = false
                            showingSongForm = true
                        }) {
                            Text("添加歌曲")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(theme.primaryColor))
                                .shadow(color: theme.primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(songs, id: \.id) { song in
                            SongRow(song: song)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .listRowBackground(Color.clear)
                            .contentShape(Rectangle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    prepareEditSong(song)
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.blue)
                                
                                Button(role: .destructive) {
                                    songToDelete = song
                                    showingDeleteAlert = true
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                    .padding(.top, 8)
                }
                
                Spacer()
                
                // 底部操作栏
                HStack {
                    Spacer()
                    
                    Button(action: {
                        resetSongForm()
                        isEditMode = false
                        showingSongForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("添加歌曲")
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(theme.primaryColor))
                        .shadow(color: theme.primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(trailing:
            Menu {
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
                    .font(.system(size: 22))
                    .foregroundColor(theme.primaryColor)
            }
        )
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
    
    // 准备编辑歌曲
    private func prepareEditSong(_ song: Song) {
        songToEdit = song
        songName = song.name ?? ""
        tempo = Int(song.bpm)
        beatsPerBar = Int(song.beatsPerBar)
        beatUnit = Int(song.beatUnit)
        
        // 转换 beatStatuses
        if let statusArray = song.beatStatuses as? [Int] {
            beatStatuses = statusArray.map { statusInt -> BeatStatus in
                switch statusInt {
                case 0: return .strong
                case 1: return .medium
                case 2: return .normal
                case 3: return .muted
                default: return .normal
                }
            }
        } else {
            // 默认状态
            beatStatuses = Array(repeating: .normal, count: beatsPerBar)
            if beatStatuses.count > 0 {
                beatStatuses[0] = .strong
            }
        }
        
        isEditMode = true
        showingSongForm = true
    }
    
    // 应用歌曲设置到节拍器
    private func applySongSettings(_ song: Song) {
        metronomeState.updateTempo(Int(song.bpm))
        metronomeState.updateBeatsPerBar(Int(song.beatsPerBar))
        metronomeState.updateBeatUnit(Int(song.beatUnit))
        
        // 转换 beatStatuses
        if let statusArray = song.beatStatuses as? [Int] {
            let statuses = statusArray.map { statusInt -> BeatStatus in
                switch statusInt {
                case 0: return .strong
                case 1: return .medium
                case 2: return .normal
                case 3: return .muted
                default: return .normal
                }
            }
            metronomeState.updateBeatStatuses(statuses)
        }
        
        // 如果节拍器还没有启动，则启动它
        if !metronomeState.isPlaying {
            metronomeState.togglePlayback()
        }
    }
    
    // 重置添加歌曲表单
    private func resetSongForm() {
        songName = ""
        tempo = 120
        beatsPerBar = 4
        beatUnit = 4
        beatStatuses = Array(repeating: .normal, count: 4)
        beatStatuses[0] = .strong
        songToEdit = nil
    }
}

// 更新 SongRow 以使用 CoreData Song 实体
struct SongRow: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var metronomeState: MetronomeState
    let song: Song
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(song.name ?? "未命名歌曲")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textColor)
                
                HStack(spacing: 12) {
                    Label("\(song.bpm) BPM", systemImage: "metronome")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor.opacity(0.7))
                    
                    Text("\(song.beatsPerBar)/\(song.beatUnit)")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor.opacity(0.7))
                }
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            Button(action: {
                applySongSettings(song)
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(theme.primaryColor)
                    .padding(.trailing, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
    
    // 应用歌曲设置到节拍器
    private func applySongSettings(_ song: Song) {
        metronomeState.updateTempo(Int(song.bpm))
        metronomeState.updateBeatsPerBar(Int(song.beatsPerBar))
        metronomeState.updateBeatUnit(Int(song.beatUnit))
        
        // 转换 beatStatuses
        if let statusArray = song.beatStatuses as? [Int] {
            let statuses = statusArray.map { statusInt -> BeatStatus in
                switch statusInt {
                case 0: return .strong
                case 1: return .medium
                case 2: return .normal
                case 3: return .muted
                default: return .normal
                }
            }
            metronomeState.updateBeatStatuses(statuses)
        }
        
        // 如果节拍器还没有启动，则启动它
        if !metronomeState.isPlaying {
            metronomeState.togglePlayback()
        }
    }
}

struct EditSongView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var playlistManager: CoreDataPlaylistManager
    @Binding var isPresented: Bool
    @Binding var songName: String
    @Binding var tempo: Int
    @Binding var beatsPerBar: Int
    @Binding var beatUnit: Int
    @Binding var beatStatuses: [BeatStatus]
    var isEditMode: Bool = false
    
    var onSave: (String, Int, Int, Int, [BeatStatus]) -> Void
    
    let beatUnits = [2, 4, 8, 16]
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 歌曲名称
                        VStack(alignment: .leading, spacing: 8) {
                            Text("歌曲名称")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textColor)
                            
                            TextField("输入歌曲名称", text: $songName)
                                .font(.system(size: 17))
                                .padding()
                                .background(theme.cardBackgroundColor)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                        }
                        
                        // BPM设置
                        VStack(alignment: .leading, spacing: 8) {
                            Text("节拍速度 (BPM)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textColor)
                            
                            HStack {
                                Button(action: {
                                    if tempo > 30 {
                                        tempo -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(theme.primaryColor)
                                }
                                
                                Slider(value: Binding(
                                    get: { Double(tempo) },
                                    set: { tempo = Int($0) }
                                ), in: 30...240, step: 1)
                                .accentColor(theme.primaryColor)
                                
                                Button(action: {
                                    if tempo < 240 {
                                        tempo += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(theme.primaryColor)
                                }
                            }
                            
                            Text("\(tempo) BPM")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(theme.primaryColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        // 拍号设置
                        VStack(alignment: .leading, spacing: 8) {
                            Text("拍号设置")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textColor)
                            
                            HStack(spacing: 20) {
                                // 分子
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("节拍数")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.textColor.opacity(0.7))
                                    
                                    HStack {
                                        Button(action: {
                                            if beatsPerBar > 1 {
                                                beatsPerBar -= 1
                                                updateBeatStatuses(count: beatsPerBar)
                                            }
                                        }) {
                                            Image(systemName: "minus.circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(theme.primaryColor)
                                        }
                                        
                                        Text("\(beatsPerBar)")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(theme.textColor)
                                            .frame(width: 40, alignment: .center)
                                        
                                        Button(action: {
                                            if beatsPerBar < 12 {
                                                beatsPerBar += 1
                                                updateBeatStatuses(count: beatsPerBar)
                                            }
                                        }) {
                                            Image(systemName: "plus.circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(theme.primaryColor)
                                        }
                                    }
                                }
                                
                                Divider()
                                    .frame(height: 40)
                                
                                // 分母
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("音符单位")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.textColor.opacity(0.7))
                                    
                                    HStack {
                                        ForEach(beatUnits, id: \.self) { unit in
                                            Button(action: {
                                                beatUnit = unit
                                            }) {
                                                Text("\(unit)")
                                                    .font(.system(size: 20, weight: unit == beatUnit ? .bold : .regular))
                                                    .foregroundColor(unit == beatUnit ? theme.primaryColor : theme.textColor.opacity(0.7))
                                                    .frame(width: 40, height: 40)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(unit == beatUnit ? theme.primaryColor : theme.textColor.opacity(0.3), lineWidth: unit == beatUnit ? 2 : 1)
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 节拍强弱设置
                        VStack(alignment: .leading, spacing: 10) {
                            Text("节拍强弱设置")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textColor)
                            
                            HStack(spacing: 8) {
                                ForEach(0..<beatsPerBar, id: \.self) { index in
                                    Button(action: {
                                        var newStatuses = beatStatuses
                                        newStatuses[index] = newStatuses[index].next()
                                        beatStatuses = newStatuses
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(getBeatStatusColor(beatStatuses[index]))
                                                .frame(width: 40, height: 40)
                                                .shadow(color: getBeatStatusColor(beatStatuses[index]).opacity(0.3), radius: 3, x: 0, y: 2)
                                            
                                            Text("\(index + 1)")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 6)
                            
                            // 强弱图例
                            HStack(spacing: 10) {
                                ForEach([BeatStatus.strong, BeatStatus.medium, BeatStatus.normal, BeatStatus.muted], id: \.self) { status in
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(getBeatStatusColor(status))
                                            .frame(width: 12, height: 12)
                                        
                                        Text(getBeatStatusName(status))
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.textColor.opacity(0.7))
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitle(isEditMode ? "编辑歌曲" : "添加歌曲", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    if !songName.isEmpty {
                        onSave(songName, tempo, beatsPerBar, beatUnit, beatStatuses)
                        isPresented = false
                    }
                }
                .disabled(songName.isEmpty)
            )
        }
    }
    
    private func updateBeatStatuses(count: Int) {
        var newStatuses = Array(repeating: BeatStatus.normal, count: count)
        
        for i in 0..<min(count, beatStatuses.count) {
            newStatuses[i] = beatStatuses[i]
        }
        
        if count > 0 && count > beatStatuses.count {
            newStatuses[0] = .strong
        }
        
        beatStatuses = newStatuses
    }
    
    private func getBeatStatusColor(_ status: BeatStatus) -> Color {
        switch status {
        case .strong:
            return .red
        case .medium:
            return .orange
        case .normal:
            return .blue
        case .muted:
            return .gray
        }
    }
    
    private func getBeatStatusName(_ status: BeatStatus) -> String {
        switch status {
        case .strong:
            return "强拍"
        case .medium:
            return "次强拍"
        case .normal:
            return "普通拍"
        case .muted:
            return "静音"
        }
    }
}
