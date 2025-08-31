//
//  NoteContent.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import Foundation
import SwiftData

@Model
class NoteContent {
    var note: Note?

    init(note: Note?) {
        self.note = note
    }
}

@available(iOS 26, *)
@Model
final class TextNoteContent: NoteContent {
    var text: String

    init(note: Note? = nil, text: String = "") {
        self.text = text
        super.init(note: note)
    }
}

@available(iOS 26, *)
@Model
final class AudioNoteContent: NoteContent {
    var fileName: String
    var duration: TimeInterval

    var fileURL: URL {
        AudioFiles.url(for: fileName)
    }

    init(note: Note? = nil, fileName: String, duration: TimeInterval = 0) {
        self.fileName = fileName
        self.duration = duration
        super.init(note: note)
    }
}
