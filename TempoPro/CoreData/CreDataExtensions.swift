//
//  CreDataExtensions.swift
//  TempoPro
//
//  Created by Meters on 5/3/2025.
//

import Foundation
import CoreData
import SwiftUI

// Song实体扩展
extension Song {
    // 将CoreData实体转换为模型对象
    func toModel() -> SongModel {
        let statusArray = self.beatStatuses as? [Int] ?? []
        
        return SongModel(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            bpm: Int(self.bpm),
            beatsPerBar: Int(self.beatsPerBar),
            beatUnit: Int(self.beatUnit),
            beatStatuses: statusArray
        )
    }
    
    // 从模型更新实体
    func update(from model: SongModel) {
        self.id = model.id
        self.name = model.name
        self.bpm = Int16(model.bpm)
        self.beatsPerBar = Int16(model.beatsPerBar)
        self.beatUnit = Int16(model.beatUnit)
        self.beatStatuses = model.beatStatuses as NSObject
        self.createdDate = self.createdDate ?? Date()
    }
}

// Playlist实体扩展
extension Playlist {
    // 将CoreData实体转换为模型对象
    func toModel() -> PlaylistModel {
        let playlistSongs = self.songs?.allObjects as? [Song] ?? []
        let songs = playlistSongs.map { $0.toModel() }
        
        return PlaylistModel(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            songs: songs,
            color: self.color ?? "#0000FF"
        )
    }
    
    // 从模型更新实体（不包括歌曲关系）
    func update(from model: PlaylistModel, in context: NSManagedObjectContext) {
        self.id = model.id
        self.name = model.name
        self.color = model.color
        self.createdDate = self.createdDate ?? Date()
    }
}
