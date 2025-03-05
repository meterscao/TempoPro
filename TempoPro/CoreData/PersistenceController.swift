//
//  PersistenceController.swift
//  TempoPro
//
//  Created by Meters on 5/3/2025.
//


import CoreData

struct PersistenceController {
    // 单例实例
    static let shared = PersistenceController()
    
    // 用于预览的实例
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // 创建预览数据
        let viewContext = controller.container.viewContext
        
        // 创建示例歌单
        let samplePlaylist = Playlist(context: viewContext)
        samplePlaylist.id = UUID()
        samplePlaylist.name = "示例歌单"
        samplePlaylist.color = "#4682B4"
        samplePlaylist.createdDate = Date()
        
        // 创建示例歌曲
        let sampleSong = Song(context: viewContext)
        sampleSong.id = UUID()
        sampleSong.name = "示例歌曲"
        sampleSong.bpm = 120
        sampleSong.beatsPerBar = 4
        sampleSong.beatUnit = 4
        sampleSong.beatStatuses = [0, 2, 1, 2] as NSArray
        sampleSong.createdDate = Date()
        sampleSong.playlist = samplePlaylist
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("创建预览数据失败: \(nsError)")
        }
        
        return controller
    }()
    
    // CoreData容器
    let container: NSPersistentContainer
    
    // 获取主视图上下文的便捷访问器
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    // 初始化方法
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
        
        // 启用自动合并策略
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // 保存上下文的方便方法
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("保存CoreData上下文失败: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
