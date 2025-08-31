//
//  Note.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import Foundation
import SwiftData

@Model
final class Note {
    @Attribute(.unique)
    var id: UUID

    var dateCreated: Date

    @Relationship(deleteRule: .cascade, inverse: \NoteContent.note)
    var content: NoteContent?

    var title: String
    var parent: Note?

    @Relationship(deleteRule: .cascade, inverse: \Note.parent)
    var children: [Note]

    init(
        id: UUID = .init(),
        dateCreated: Date = .now,
        content: NoteContent? = nil,
        title: String = "",
        parent: Note? = nil,
        children: [Note] = []
    ) {
        self.id = id
        self.dateCreated = dateCreated
        self.content = content
        self.title = title
        self.parent = parent
        self.children = children
    }
}
