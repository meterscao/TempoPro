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
    
    // 获取所有曲库
    func fetchPlaylists() -> [Playlist] {
        let request = NSFetchRequest<Playlist>(entityName: "Playlist")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Playlist.createdDate, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("获取曲库失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // 创建新曲库
    func createPlaylist(name: String, color: String) -> Playlist {
        let newPlaylist = Playlist(context: viewContext)
        newPlaylist.id = UUID()
        newPlaylist.name = name
        newPlaylist.color = color
        newPlaylist.createdDate = Date()
        
        saveContext()
        return newPlaylist
    }
    
    // 添加曲目到曲库
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
    
    // 更新曲库
    func updatePlaylist(_ playlist: Playlist, name: String, color: String) {
        playlist.name = name
        playlist.color = color
        saveContext()
    }
    
    // 更新曲目
    func updateSong(_ song: Song, name: String, bpm: Int, beatsPerBar: Int, beatUnit: Int, beatStatuses: [Int]) {
        song.name = name
        song.bpm = Int16(bpm)
        song.beatsPerBar = Int16(beatsPerBar)
        song.beatUnit = Int16(beatUnit)
        song.beatStatuses = beatStatuses as NSArray
        saveContext()
    }
    
    // 删除曲库
    func deletePlaylist(_ playlist: Playlist) {
        viewContext.delete(playlist)
        saveContext()
        
        if selectedPlaylist == playlist {
            selectedPlaylist = nil
        }
    }
    
    // 删除曲目
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
    
    // 打开曲库列表
    func openPlaylistsSheet() {
        showPlaylistsSheet = true
    }
    
    // 关闭曲库列表
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
                // 创建示例曲库
                createSamplePlaylists()
            }
        } catch {
            print("检查曲库失败: \(error.localizedDescription)")
        }
    }
    
    // 创建示例曲库
    // Create sample playlists
    private func createSamplePlaylists() {
        // Classical Music
        let classicalPlaylist = createPlaylist(name: "Default Library", color: "#8B4513")
        _ = addSong(to: classicalPlaylist, name: "Tchaikovsky - Waltz of the Flowers", bpm: 84, beatsPerBar: 3, beatUnit: 4, beatStatuses: [0, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Debussy - Clair de Lune", bpm: 66, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1])
        _ = addSong(to: classicalPlaylist, name: "Holst - Mars, The Bringer of War", bpm: 100, beatsPerBar: 5, beatUnit: 4, beatStatuses: [0, 1, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Chopin - Fantaisie-Impromptu", bpm: 168, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Bach - Prelude in C Major", bpm: 70, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 0, 1])
        
    }
}
