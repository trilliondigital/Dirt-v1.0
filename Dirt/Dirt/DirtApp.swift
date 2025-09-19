//
//  DirtApp.swift
//  Dirt
//
//  Created by Kaegan Braud on 9/18/25.
//

import SwiftUI
import CoreData

@main
struct DirtApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
