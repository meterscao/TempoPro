//
//  CoreDataPlaylistManager.swift
//  TempoPro
//
//  Created by Meters on 5/3/2025.
//


import Foundation
import SwiftUI
import CoreData
import Combine

class CoreDataPlaylistManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    @Published var showPlaylistsSheet = false
    @Published var selectedPlaylist: Playlist?
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // 获取所有歌单
    func fetchPlaylists() -> [Playlist] {
        let request = NSFetchRequest<Playlist>(entityName: "Playlist")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Playlist.createdDate, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("获取歌单失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // 创建新歌单
    func createPlaylist(name: String, color: String) -> Playlist {
        let newPlaylist = Playlist(context: viewContext)
        newPlaylist.id = UUID()
        newPlaylist.name = name
        newPlaylist.color = color
        newPlaylist.createdDate = Date()
        
        saveContext()
        return newPlaylist
    }
    
    // 添加歌曲到歌单
    func addSong(to playlist: Playlist, name: String, bpm: Int, beatsPerBar: Int, beatUnit: Int, beatStatuses: [Int]) -> Song {
        let newSong = Song(context: viewContext)
        newSong.id = UUID()
        newSong.name = name
        newSong.bpm = Int16(bpm)
        newSong.beatsPerBar = Int16(beatsPerBar)
        newSong.beatUnit = Int16(beatUnit)
        newSong.beatStatuses = beatStatuses as NSArray
        newSong.createdDate = Date()
        newSong.playlist = playlist
        
        saveContext()
        return newSong
    }
    
    // 更新歌单
    func updatePlaylist(_ playlist: Playlist, name: String, color: String) {
        playlist.name = name
        playlist.color = color
        saveContext()
    }
    
    // 更新歌曲
    func updateSong(_ song: Song, name: String, bpm: Int, beatsPerBar: Int, beatUnit: Int, beatStatuses: [Int]) {
        song.name = name
        song.bpm = Int16(bpm)
        song.beatsPerBar = Int16(beatsPerBar)
        song.beatUnit = Int16(beatUnit)
        song.beatStatuses = beatStatuses as NSArray
        saveContext()
    }
    
    // 删除歌单
    func deletePlaylist(_ playlist: Playlist) {
        viewContext.delete(playlist)
        saveContext()
        
        if selectedPlaylist == playlist {
            selectedPlaylist = nil
        }
    }
    
    // 删除歌曲
    func deleteSong(_ song: Song) {
        viewContext.delete(song)
        saveContext()
    }
    
    
    // 保存上下文
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("保存上下文失败: \(error.localizedDescription)")
        }
    }
    
    // 打开歌单列表
    func openPlaylistsSheet() {
        showPlaylistsSheet = true
    }
    
    // 关闭歌单列表
    func closePlaylistsSheet() {
        showPlaylistsSheet = false
    }
    
    // 创建初始示例数据（如果需要）
    func createSampleDataIfNeeded() {
        let request = NSFetchRequest<Playlist>(entityName: "Playlist")
        request.fetchLimit = 1
        
        do {
            let count = try viewContext.count(for: request)
            if count == 0 {
                // 创建示例歌单
                createSamplePlaylists()
            }
        } catch {
            print("检查歌单失败: \(error.localizedDescription)")
        }
    }
    
    // 创建示例歌单
    private func createSamplePlaylists() {
        // 古典乐集
        let classicalPlaylist = createPlaylist(name: "古典乐集", color: "#8B4513")
        addSong(to: classicalPlaylist, name: "贝多芬第五交响曲", bpm: 108, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        addSong(to: classicalPlaylist, name: "莫扎特小夜曲", bpm: 70, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        addSong(to: classicalPlaylist, name: "巴赫平均律", bpm: 72, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 2, 2])
        
        // 摇滚精选
        let rockPlaylist = createPlaylist(name: "摇滚精选", color: "#B22222")
        addSong(to: rockPlaylist, name: "皇后乐队 - We Will Rock You", bpm: 81, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 0, 2])
        addSong(to: rockPlaylist, name: "AC/DC - Back in Black", bpm: 96, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        addSong(to: rockPlaylist, name: "Led Zeppelin - Stairway to Heaven", bpm: 82, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        
        // 爵士鼓点
        let jazzPlaylist = createPlaylist(name: "爵士鼓点", color: "#191970")
        addSong(to: jazzPlaylist, name: "Take Five", bpm: 172, beatsPerBar: 5, beatUnit: 4, beatStatuses: [0, 2, 1, 2, 1])
        addSong(to: jazzPlaylist, name: "So What", bpm: 136, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        addSong(to: jazzPlaylist, name: "Autumn Leaves", bpm: 100, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
    }
}
