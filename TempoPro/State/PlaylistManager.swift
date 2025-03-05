import Foundation
import SwiftUI
import Combine

class PlaylistManager: ObservableObject {
    // 存储键
    private enum Keys {
        static let playlists = "playlists_data"
    }
    
    @Published var playlists: [PlaylistModel] = []
    @Published var selectedPlaylist: PlaylistModel?
    @Published var showPlaylistsSheet = false
    
    private let defaults = UserDefaults.standard
    
    init() {
        loadPlaylists()
        
        // 如果没有任何歌单，创建一些示例歌单
        if playlists.isEmpty {
            createSamplePlaylists()
        }
    }
    
    // 加载歌单数据
    private func loadPlaylists() {
        if let data = defaults.data(forKey: Keys.playlists) {
            do {
                let decodedPlaylists = try JSONDecoder().decode([PlaylistModel].self, from: data)
                self.playlists = decodedPlaylists
                print("已成功加载\(decodedPlaylists.count)个歌单")
            } catch {
                print("加载歌单失败: \(error.localizedDescription)")
                self.playlists = []
            }
        }
    }
    
    // 保存歌单数据
    private func savePlaylists() {
        do {
            let data = try JSONEncoder().encode(playlists)
            defaults.set(data, forKey: Keys.playlists)
            print("已成功保存\(playlists.count)个歌单")
        } catch {
            print("保存歌单失败: \(error.localizedDescription)")
        }
    }
    
    // 添加歌单
    func addPlaylist(_ playlist: PlaylistModel) {
        playlists.append(playlist)
        savePlaylists()
    }
    
    // 更新歌单
    func updatePlaylist(_ playlist: PlaylistModel) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = playlist
            savePlaylists()
        }
    }
    
    // 删除歌单
    func deletePlaylist(_ playlist: PlaylistModel) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
        
        // 如果删除的是当前选中的歌单，清除选中
        if selectedPlaylist?.id == playlist.id {
            selectedPlaylist = nil
        }
    }
    
    // 添加歌曲到歌单
    func addSong(_ song: SongModel, toPlaylist playlistId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].songs.append(song)
            savePlaylists()
        }
    }
    
    // 从歌单中删除歌曲
    func removeSong(_ song: SongModel, fromPlaylist playlistId: UUID) {
        if let playlistIndex = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[playlistIndex].songs.removeAll { $0.id == song.id }
            savePlaylists()
        }
    }
    
    // 创建示例歌单
    private func createSamplePlaylists() {
        let classicalPlaylist = PlaylistModel(
            id: UUID(),
            name: "古典乐集",
            songs: [
                SongModel(name: "贝多芬第五交响曲", bpm: 108, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2]),
                SongModel(name: "莫扎特小夜曲", bpm: 70, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2]),
                SongModel(name: "巴赫平均律", bpm: 72, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 2, 2])
            ],
            color: "#8B4513"
        )
        
        let rockPlaylist = PlaylistModel(
            id: UUID(),
            name: "摇滚精选",
            songs: [
                SongModel(name: "皇后乐队 - We Will Rock You", bpm: 81, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 0, 2]),
                SongModel(name: "AC/DC - Back in Black", bpm: 96, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2]),
                SongModel(name: "Led Zeppelin - Stairway to Heaven", bpm: 82, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
            ],
            color: "#B22222"
        )
        
        let jazzPlaylist = PlaylistModel(
            id: UUID(),
            name: "爵士鼓点",
            songs: [
                SongModel(name: "Take Five", bpm: 172, beatsPerBar: 5, beatUnit: 4, beatStatuses: [0, 2, 1, 2, 1]),
                SongModel(name: "So What", bpm: 136, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2]),
                SongModel(name: "Autumn Leaves", bpm: 100, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
            ],
            color: "#191970"
        )
        
        playlists = [classicalPlaylist, rockPlaylist, jazzPlaylist]
        savePlaylists()
    }
    
    // 打开歌单列表
    func openPlaylistsSheet() {
        showPlaylistsSheet = true
    }
    
    // 关闭歌单列表
    func closePlaylistsSheet() {
        showPlaylistsSheet = false
    }
} 
