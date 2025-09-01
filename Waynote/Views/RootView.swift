//
//  RootView.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import CoreSpotlight
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var router = Router()
    @State private var rootNote: Note? = nil

    var body: some View {
        NavigationStack(path: $router.path) {
            if let rootNote {
                NoteDetailView(note: rootNote)
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .note(let note):
                            NoteDetailView(note: note)
                        }
                    }
                    .onContinueUserActivity(CSSearchableItemActionType) { activity in
                        if let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier]
                            as? String, let id = UUID(uuidString: identifier)
                        {
                            router.navigate(noteID: id, context: modelContext)
                        }
                    }
            } else {
                EmptyView()
            }
        }
        .environmentObject(router)
        .task {
            let store = NoteStore(context: modelContext)
            rootNote = store.fetchRootNote()
        }
    }
}
