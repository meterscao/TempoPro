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
                                .foregroundColor(currentPlaylist == playlist ? Color("backgroundSecondaryColor") : Color("textSecondaryColor"))
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
                        isShowLibraryList.toggle()
                    }) {
                        Text("编辑")
                            .font(.custom("MiSansLatin-Semibold", size: 16))
                            .foregroundColor(Color("textPrimaryColor"))
                    }
                }
            }
            .padding(.horizontal, 20)
            
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
                                .foregroundColor(Color("textSecondaryColor"))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 40)
            }
            else {
                ListView {
                    SectionView {
                        ForEach(songs, id: \.id) { song in
                            SongRowCard(song: song, onEdit: {}, onDelete: {}, onPlay: {
                                playSong(song)
                            })
                        }
                    }
                }
                .contentInset(.top, 0)
            }
                
            

            VStack(spacing: 0){
                Button(action: {
                    resetSongForm()
                    isEditMode = false
                    showingSongForm = true
                }) {
                    HStack(){
                        Image("icon-plus-s")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("添加曲目")
                            .font(.custom("MiSansLatin-Regular", size: 16))
                        PremiumLabelView()
                        
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.accent)
                    .background(Color("backgroundSecondaryColor"))
                    .cornerRadius(12)
                }
                
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
        
        .fullScreenCover(isPresented: $isShowLibraryList, content: {
            LibraryListView()
                .environmentObject(playlistManager)
                .environmentObject(metronomeState)
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



