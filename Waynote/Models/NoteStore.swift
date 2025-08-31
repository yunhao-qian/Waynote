//
//  NoteStore.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import Foundation
import SwiftData
import os

struct NoteStore {
    let context: ModelContext

    func save() {
        do {
            try context.save()
        } catch {
            AppLogging.general.error("Failed to save context: \(error.localizedDescription)")
        }
        AppLogging.general.info("Context saved")
    }

    func fetchRootNote() -> Note {
        var descriptor = FetchDescriptor<Note>(predicate: #Predicate { $0.parent == nil })
        descriptor.fetchLimit = 1
        let rootNote: Note?
        do {
            rootNote = try context.fetch(descriptor).first
        } catch {
            AppLogging.general.error("Failed to fetch root note: \(error.localizedDescription)")
            rootNote = nil
        }
        if let rootNote {
            return rootNote
        }
        let newNote = Note(title: "Waynote")
        context.insert(newNote)
        save()
        AppLogging.general.info("Created new root note with ID \(newNote.id)")
        return newNote
    }

    func fetchNote(withID id: UUID) -> Note? {
        var descriptor = FetchDescriptor<Note>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let note: Note?
        do {
            note = try context.fetch(descriptor).first
        } catch {
            AppLogging.general.error(
                "Failed to fetch note with ID \(id): \(error.localizedDescription)"
            )
            note = nil
        }
        return note
    }

    func createTextNote(parent: Note) -> Note {
        let note = Note(content: TextNoteContent(), parent: parent)
        context.insert(note)
        save()
        AppLogging.general.info("Created new text note with ID \(note.id)")
        return note
    }

    func createAudioNote(parent: Note) -> Note {
        let id = UUID()
        let fileName = "\(id.uuidString).m4a"
        let note = Note(id: id, content: AudioNoteContent(fileName: fileName), parent: parent)
        context.insert(note)
        save()
        AppLogging.general.info("Created new audio note with ID \(note.id)")
        return note
    }

    func deleteNote(_ note: Note) {
        // SwiftData seems to have bugs in cascaded deletion, so we delete the descendants manually.
        while let last = note.children.last {
            deleteNote(last)
        }
        let audioFileURL = (note.content as? AudioNoteContent)?.fileURL
        if let content = note.content {
            context.delete(content)
            save()
        }
        context.delete(note)
        save()
        if let audioFileURL {
            do {
                try FileManager.default.removeItem(at: audioFileURL)
                AppLogging.general.info("Deleted audio file at \"\(audioFileURL)\"")
            } catch {
                AppLogging.general.warning(
                    """
                    Failed to delete audio file at "\(audioFileURL)": \(error.localizedDescription)
                    """
                )
            }
        }
        AppLogging.general.info("Deleted note with ID \(note.id) and title \"\(note.title)\"")
    }
}
