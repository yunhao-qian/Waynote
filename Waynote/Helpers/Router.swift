//
//  Router.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import Combine
import Foundation
import SwiftData
import os

enum Route: Hashable {
    case note(Note)
}

final class Router: ObservableObject {
    @Published var path: [Route] = []

    func navigate(noteID: UUID, context: ModelContext) {
        let store = NoteStore(context: context)
        guard let note = store.fetchNote(withID: noteID) else {
            AppLogging.general.error("Failed to navigate to note with ID \(noteID): Note not found")
            return
        }
        var chain: [Note] = [note]
        while let parent = chain.last?.parent {
            chain.append(parent)
        }
        path = chain.dropLast().reversed().map { Route.note($0) }
    }
}
