//
//  NoteCardView.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import SwiftUI

struct NoteCardView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !note.title.isEmpty {
                Text(note.title)
                    .font(.headline)
            }
            switch note.content {
            case let content as TextNoteContent:
                Text(content.text)
                    .font(.body)
                    .lineLimit(4)
            case let content as AudioNoteContent:
                AudioPlayerView(content: content)
            default:
                EmptyView()
            }
            Divider()
            Text(note.dateCreated.formatted(.dateTime))
                .font(.caption)
        }
        .padding(16)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
    }
}

private let sampleTitle = "A Tale of Two Cities"

private let sampleText = """
    It was the best of times, it was the worst of times, it was the age of wisdom, it was the age \
    of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season \
    of light, it was the season of darkness, it was the spring of hope, it was the winter of \
    despair.
    """

#Preview {
    NoteCardView(note: Note(content: TextNoteContent(text: sampleText), title: sampleTitle))
}
