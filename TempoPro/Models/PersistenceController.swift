//
//  PersistenceController.swift
//  TempoPro
//
//  Created by Meters on 5/3/2025.
//


import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    // 预览环境的示例数据
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // 添加预览数据
        let viewContext = controller.container.viewContext
        
        // 创建示例歌单
        let classicalPlaylist = Playlist(context: viewContext)
        classicalPlaylist.id = UUID()
        classicalPlaylist.name = "古典乐集"
        classicalPlaylist.color = "#8B4513"
        classicalPlaylist.createdDate = Date()
        
        // 创建示例歌曲
        let song = Song(context: viewContext)
        song.id = UUID()
        song.name = "贝多芬第五交响曲"
        song.bpm = 108
        song.beatsPerBar = 4
        song.beatUnit = 4
        song.beatStatuses = [0, 2, 1, 2] as NSArray
        song.createdDate = Date()
        song.playlist = classicalPlaylist
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("创建预览数据失败: \(nsError)")
        }
        
        return controller
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TempoProModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("加载CoreData存储失败: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
