//
//  WaynoteApp.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/25/25.
//

import SwiftData
import SwiftUI

@main
struct WaynoteApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Note.self,
            NoteContent.self,
            TextNoteContent.self,
            AudioNoteContent.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
