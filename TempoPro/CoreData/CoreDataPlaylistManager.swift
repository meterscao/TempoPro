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
    func addSong(to playlist: Playlist, name: String, bpm: Int, beatsPerBar: Int, beatUnit: Int, beatStatuses: [Int], subdivisionPattern: String) -> Song {
        let newSong = Song(context: viewContext)
        newSong.id = UUID()
        newSong.name = name
        newSong.bpm = Int16(bpm)
        newSong.beatsPerBar = Int16(beatsPerBar)
        newSong.beatUnit = Int16(beatUnit)
        newSong.beatStatuses = beatStatuses as NSArray
        newSong.createdDate = Date()
        newSong.playlist = playlist
        newSong.subdivisionPattern = subdivisionPattern
        
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
    func updateSong(_ song: Song, name: String, bpm: Int, beatsPerBar: Int, beatUnit: Int, beatStatuses: [Int], subdivisionPattern: String) {
        song.name = name
        song.bpm = Int16(bpm)
        song.beatsPerBar = Int16(beatsPerBar)
        song.beatUnit = Int16(beatUnit)
        song.beatStatuses = beatStatuses as NSArray
        song.subdivisionPattern = subdivisionPattern
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
   // Create sample playlists
    private func createSamplePlaylists() {
        // Classical Music
        let classicalPlaylist = createPlaylist(name: "Classical Music", color: "#8B4513")
        _ = addSong(to: classicalPlaylist, name: "Mozart Sonata", bpm: 120, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_whole")
        _ = addSong(to: classicalPlaylist, name: "Beethoven Symphony No.5", bpm: 108, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_triplet")
        _ = addSong(to: classicalPlaylist, name: "Chopin Nocturne", bpm: 80, beatsPerBar: 3, beatUnit: 4, beatStatuses: [0, 1, 1], subdivisionPattern: "quarter_duple")
        _ = addSong(to: classicalPlaylist, name: "Mozart Sonata", bpm: 120, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_whole")
        
        // Jazz Music
        let jazzPlaylist = createPlaylist(name: "Jazz Music", color: "#4682B4")
        _ = addSong(to: jazzPlaylist, name: "Swing Jazz", bpm: 132, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_eighth_dotted_sixteenth")
        _ = addSong(to: jazzPlaylist, name: "Bebop", bpm: 160, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_quadruplet")
        _ = addSong(to: jazzPlaylist, name: "Bossa Nova", bpm: 110, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_sixteenth_eighth_sixteenth")
        
        // Rock Music
        let rockPlaylist = createPlaylist(name: "Rock Music", color: "#CD5C5C")
        _ = addSong(to: rockPlaylist, name: "Classic Rock", bpm: 128, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_duple")
        _ = addSong(to: rockPlaylist, name: "Heavy Metal", bpm: 180, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_quadruplet")
        _ = addSong(to: rockPlaylist, name: "Punk Rock", bpm: 190, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_double_rest_sixteenth")
        
        // Electronic Music
        let electronicPlaylist = createPlaylist(name: "Electronic Music", color: "#9370DB")
        _ = addSong(to: electronicPlaylist, name: "House Music", bpm: 128, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_quadruplet")
        _ = addSong(to: electronicPlaylist, name: "Drum and Bass", bpm: 175, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_two_sixteenth_eighth")
        _ = addSong(to: electronicPlaylist, name: "Techno", bpm: 135, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_sixteenth_eighth_sixteenth")
        
        // World Music
        let worldPlaylist = createPlaylist(name: "World Music", color: "#228B22")
        _ = addSong(to: worldPlaylist, name: "Waltz", bpm: 90, beatsPerBar: 3, beatUnit: 4, beatStatuses: [0, 1, 1], subdivisionPattern: "quarter_whole")
        _ = addSong(to: worldPlaylist, name: "Flamenco", bpm: 120, beatsPerBar: 12, beatUnit: 8, beatStatuses: [0, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1], subdivisionPattern: "quarter_triplet")
        _ = addSong(to: worldPlaylist, name: "Indian Tabla", bpm: 80, beatsPerBar: 16, beatUnit: 4, beatStatuses: [0, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1], subdivisionPattern: "quarter_triplet_rest_middle")
        
        _ = addSong(to: classicalPlaylist, name: "Beethoven Symphony No.5", bpm: 108, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_triplet")
        _ = addSong(to: classicalPlaylist, name: "Chopin Nocturne", bpm: 80, beatsPerBar: 3, beatUnit: 4, beatStatuses: [0, 1, 1], subdivisionPattern: "quarter_duple")
        _ = addSong(to: classicalPlaylist, name: "Mozart Sonata", bpm: 120, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_whole")
        _ = addSong(to: classicalPlaylist, name: "Beethoven Symphony No.5", bpm: 108, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_triplet")
        _ = addSong(to: classicalPlaylist, name: "Chopin Nocturne", bpm: 80, beatsPerBar: 3, beatUnit: 4, beatStatuses: [0, 1, 1], subdivisionPattern: "quarter_duple")
        _ = addSong(to: classicalPlaylist, name: "Mozart Sonata", bpm: 120, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_whole")
        _ = addSong(to: classicalPlaylist, name: "Beethoven Symphony No.5", bpm: 108, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 1, 2, 1], subdivisionPattern: "quarter_triplet")
        _ = addSong(to: classicalPlaylist, name: "Chopin Nocturne", bpm: 80, beatsPerBar: 3, beatUnit: 4, beatStatuses: [0, 1, 1], subdivisionPattern: "quarter_duple")
    }
}
