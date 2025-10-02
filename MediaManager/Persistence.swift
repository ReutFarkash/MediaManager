//
//  Persistence.swift
//  MediaManager
//
//  Created by Reut Farkash on 01/10/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date().addingTimeInterval(TimeInterval(i * 100))
            newItem.title = "Sample Item \(i + 1)"
            newItem.descriptionText = "This is a description for sample item number \(i + 1)."
            newItem.mediaType = ["Book", "Movie", "Podcast", "Document"].randomElement()
            newItem.url = i % 3 == 0 ? "https://www.apple.com" : nil
            newItem.favorite = i % 2 == 0
            newItem.isDownloading = i % 4 == 0
            newItem.isOnMac = i % 2 == 1
            newItem.isOnIPhone = i % 3 == 1
            newItem.isInApp = i % 5 == 0
        }
        do {
            try viewContext.save()
        } catch {
            // In previews/tests, fatalError is acceptable for unrecoverable setup errors.
            let nsError = error as NSError
            fatalError("Unresolved error during preview data setup: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MediaManager")
        if inMemory {
            // For in-memory stores, assign a null URL
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // In a shipping application, this should be handled more gracefully, e.g.,
                // logging the error and presenting a user-friendly message, rather than crashing.
                fatalError("Unresolved error loading persistent stores: \(error), \(error.userInfo)")
            }
        })
        // Automatically merge changes from parent contexts (e.g., background saves)
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Optional: Set merge policy for better conflict resolution
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
