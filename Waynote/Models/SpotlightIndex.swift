//
//  SpotlightIndex.swift
//  Waynote
//
//  Created by Yunhao Qian on 9/1/25.
//

import CoreSpotlight
import os

enum SpotlightIndex {
    static let domainIdentifier = "note"

    static func index(note: Note) {
        let attributeSet = CSSearchableItemAttributeSet(
            itemContentType: UTType.plainText.identifier
        )
        attributeSet.title = getTitle(for: note)
        attributeSet.containerTitle = getContainerTitle(for: note)
        attributeSet.contentCreationDate = note.dateCreated
        attributeSet.contentDescription = getContentDescription(for: note)
        if let content = note.content as? TextNoteContent {
            attributeSet.textContent = content.text
        }

        let item = CSSearchableItem(
            uniqueIdentifier: note.id.uuidString,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error {
                AppLogging.general.error(
                    "Failed to index note with ID \(note.id): \(error.localizedDescription)"
                )
            } else {
                AppLogging.general.info("Indexed note with ID \(note.id)")
            }
        }
    }

    static func delete(noteID: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [noteID.uuidString]) {
            error in
            if let error {
                AppLogging.general.error(
                    "Failed to delete indexed note with ID \(noteID): \(error.localizedDescription)"
                )
            } else {
                AppLogging.general.info("Deleted indexed note with ID \(noteID)")
            }
        }
    }

    private static func getTitle(for note: Note) -> String {
        if !note.title.isEmpty {
            return note.title
        }
        switch note.content {
        case .none:
            return "Waynote"
        case is TextNoteContent:
            return "Text Note"
        case is AudioNoteContent:
            return "Audio Note"
        default:
            return "Unknown Note"
        }
    }

    private static func getContainerTitle(for note: Note) -> String {
        var parts: [Note] = [note]
        while let parent = parts.last?.parent {
            parts.append(parent)
        }
        return parts.reversed().map { getTitle(for: $0) }.joined(separator: " › ")
    }

    private static func getContentDescription(for note: Note) -> String? {
        switch note.content {
        case let content as TextNoteContent:
            return content.text.prefix(256).trimmingCharacters(in: .whitespacesAndNewlines)
        case is AudioNoteContent:
            return "Audio Recording"
        default:
            return nil
        }
    }
}
