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
        // Classical Music
        let classicalPlaylist = createPlaylist(name: "Classical Masterpieces", color: "#8B4513")
        _ = addSong(to: classicalPlaylist, name: "Beethoven - Symphony No. 5", bpm: 108, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Mozart - Eine Kleine Nachtmusik", bpm: 70, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Bach - Air on the G String", bpm: 60, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Vivaldi - The Four Seasons", bpm: 104, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Chopin - Nocturne Op. 9 No. 2", bpm: 72, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Debussy - Clair de Lune", bpm: 66, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Tchaikovsky - 1812 Overture", bpm: 120, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Handel - Messiah: Hallelujah", bpm: 100, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Brahms - Hungarian Dance No. 5", bpm: 132, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: classicalPlaylist, name: "Wagner - Ride of the Valkyries", bpm: 92, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        
        // Rock Classics
        let rockPlaylist = createPlaylist(name: "Rock Legends", color: "#B22222")
        _ = addSong(to: rockPlaylist, name: "Queen - Bohemian Rhapsody", bpm: 72, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: rockPlaylist, name: "Led Zeppelin - Stairway to Heaven", bpm: 82, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: rockPlaylist, name: "Pink Floyd - Comfortably Numb", bpm: 63, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: rockPlaylist, name: "The Rolling Stones - Paint It Black", bpm: 100, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: rockPlaylist, name: "AC/DC - Back in Black", bpm: 96, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: rockPlaylist, name: "Eagles - Hotel California", bpm: 75, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: rockPlaylist, name: "Guns N' Roses - Sweet Child O' Mine", bpm: 120, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: rockPlaylist, name: "Nirvana - Smells Like Teen Spirit", bpm: 117, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: rockPlaylist, name: "The Who - Baba O'Riley", bpm: 126, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: rockPlaylist, name: "Metallica - Enter Sandman", bpm: 123, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        
        // Jazz Standards
        let jazzPlaylist = createPlaylist(name: "Jazz Essentials", color: "#191970")
        _ = addSong(to: jazzPlaylist, name: "Dave Brubeck - Take Five", bpm: 172, beatsPerBar: 5, beatUnit: 4, beatStatuses: [0, 2, 1, 2, 1])
        _ = addSong(to: jazzPlaylist, name: "Miles Davis - So What", bpm: 136, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: jazzPlaylist, name: "John Coltrane - Giant Steps", bpm: 290, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: jazzPlaylist, name: "Duke Ellington - Take the A Train", bpm: 160, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: jazzPlaylist, name: "Thelonious Monk - Round Midnight", bpm: 60, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: jazzPlaylist, name: "Charles Mingus - Goodbye Pork Pie Hat", bpm: 72, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: jazzPlaylist, name: "Herbie Hancock - Cantaloupe Island", bpm: 112, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: jazzPlaylist, name: "Bill Evans - Waltz for Debby", bpm: 120, beatsPerBar: 3, beatUnit: 4, beatStatuses: [0, 2, 1])
        _ = addSong(to: jazzPlaylist, name: "Dizzy Gillespie - A Night in Tunisia", bpm: 140, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: jazzPlaylist, name: "Louis Armstrong - What a Wonderful World", bpm: 70, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        
        // Electronic Music
        let electronicPlaylist = createPlaylist(name: "Electronic Pioneers", color: "#4B0082")
        _ = addSong(to: electronicPlaylist, name: "Daft Punk - One More Time", bpm: 123, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: electronicPlaylist, name: "Kraftwerk - The Model", bpm: 94, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: electronicPlaylist, name: "The Chemical Brothers - Block Rockin' Beats", bpm: 128, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: electronicPlaylist, name: "Aphex Twin - Windowlicker", bpm: 138, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: electronicPlaylist, name: "Fatboy Slim - Praise You", bpm: 125, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: electronicPlaylist, name: "Orbital - Halcyon and On and On", bpm: 127, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: electronicPlaylist, name: "Massive Attack - Teardrop", bpm: 79, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: electronicPlaylist, name: "Underworld - Born Slippy (NUXX)", bpm: 140, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: electronicPlaylist, name: "Moby - Porcelain", bpm: 96, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: electronicPlaylist, name: "Boards of Canada - Roygbiv", bpm: 85, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        
        // Funk & Soul
        let funkPlaylist = createPlaylist(name: "Funk & Soul Grooves", color: "#9932CC")
        _ = addSong(to: funkPlaylist, name: "James Brown - Get Up Offa That Thing", bpm: 106, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: funkPlaylist, name: "Stevie Wonder - Superstition", bpm: 101, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: funkPlaylist, name: "Earth Wind & Fire - September", bpm: 126, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: funkPlaylist, name: "Parliament - Give Up the Funk", bpm: 112, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: funkPlaylist, name: "Aretha Franklin - Respect", bpm: 115, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: funkPlaylist, name: "Marvin Gaye - What's Going On", bpm: 96, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: funkPlaylist, name: "Kool & The Gang - Celebration", bpm: 123, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: funkPlaylist, name: "Otis Redding - Sittin' On The Dock of the Bay", bpm: 96, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: funkPlaylist, name: "Sly & The Family Stone - Thank You", bpm: 103, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
        _ = addSong(to: funkPlaylist, name: "Curtis Mayfield - Move On Up", bpm: 116, beatsPerBar: 4, beatUnit: 4, beatStatuses: [0, 2, 1, 2])
    }
}
