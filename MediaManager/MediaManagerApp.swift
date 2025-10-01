//
//  MediaManagerApp.swift
//  MediaManager
//
//  Created by Reut Farkash on 01/10/2025.
//

import SwiftUI
import CoreData

@main
struct MediaManagerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
