//
//  NoteDetailView.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import SwiftData
import SwiftUI

struct NoteDetailView: View {
    let note: Note

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: Router
    @Query private var children: [Note]
    @State private var isSearching = false
    @State private var isRenaming = false
    @State private var draftTitle = ""
    @State private var isRecordingAudio = false
    @State private var recordingAudioContent: AudioNoteContent? = nil

    private var store: NoteStore {
        NoteStore(context: modelContext)
    }

    init(note: Note) {
        self.note = note
        let noteID = note.id
        _children = .init(
            FetchDescriptor(
                predicate: #Predicate { $0.parent?.id == noteID },
                sortBy: [.init(\.dateCreated)]
            )
        )
    }

    var body: some View {
        List {
            switch note.content {
            case let content as TextNoteContent:
                Section("Text") {
                    TextNoteDetailView(content: content) {
                        store.saveNote(note)
                    }
                    .listRowBackground(Color.clear)
                }
            case let content as AudioNoteContent:
                Section("Audio") {
                    AudioNoteDetailView(content: content)
                        .listRowBackground(Color.clear)
                }
            default:
                EmptyView()
            }
            if !children.isEmpty {
                Section("Child Notes") {
                    ForEach(children, id: \.id) { child in
                        NoteCardView(note: child)
                            .contextMenu {
                                Button("Open", systemImage: "arrow.up.right.square") {
                                    router.navigate(noteID: child.id, context: modelContext)
                                }
                                Divider()
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    store.deleteNote(child)
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .navigationTitle(note.title)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Add Text", systemImage: "text.document") {
                    let child = store.createTextNote(parent: note)
                    router.navigate(noteID: child.id, context: modelContext)
                }
                Button("Add Audio", systemImage: "waveform") {
                    let child = store.createAudioNote(parent: note)
                    recordingAudioContent = child.content as? AudioNoteContent
                    isRecordingAudio = true
                }
            }
            ToolbarSpacer(.flexible, placement: .topBarTrailing)
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button("Rename", systemImage: "rectangle.and.pencil.and.ellipsis") {
                        draftTitle = note.title
                        isRenaming = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            ToolbarSpacer(.flexible, placement: .topBarTrailing)
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Search", systemImage: "magnifyingglass") {
                    isSearching = true
                }
            }
        }
        .animation(.default, value: children)
        .alert("Rename Note", isPresented: $isRenaming) {
            TextField("Title", text: $draftTitle)
                .textInputAutocapitalization(.sentences)
            Button("Cancel", role: .cancel) {}
            Button("OK") {
                note.title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                store.saveNote(note)
            }
        }
        .sheet(isPresented: $isSearching) {
            SearchSheet()
        }
        .sheet(isPresented: $isRecordingAudio) {
            if let recordingAudioContent {
                AudioRecorderView(content: recordingAudioContent)
            }
        }
    }
}

struct TextNoteDetailView: View {
    @Bindable var content: TextNoteContent
    let onEndEditing: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Text(content.text.isEmpty ? " " : content.text)
            .foregroundColor(.clear)
            .padding(6)
            .frame(maxWidth: .infinity)
            .overlay(
                TextEditor(text: $content.text)
                    .focused($isFocused)
                    .onChange(of: isFocused) { _, newValue in
                        if !newValue {
                            onEndEditing()
                        }
                    }
            )
            .padding(10)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(16)
            .onDisappear {
                onEndEditing()
            }
    }
}

struct AudioNoteDetailView: View {
    let content: AudioNoteContent

    var body: some View {
        AudioPlayerView(content: content)
            .padding(16)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(16)
    }
}
