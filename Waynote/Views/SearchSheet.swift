//
//  SearchSheet.swift
//  Waynote
//
//  Created by Yunhao Qian on 9/1/25.
//

import CoreSpotlight
import SwiftData
import SwiftUI
import os

struct SearchSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @State private var searchText: String = ""
    @State private var userQuery: CSUserQuery? = nil
    @State private var handlerTask: Task<Void, Never>? = nil
    @State private var searchResults: [Note] = []

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit(performSearch)
                    .onChange(of: searchText) { _, _ in
                        performSearch()
                    }
                if userQuery != nil {
                    ProgressView()
                }
            }
            .padding(16)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(16)

            List(searchResults, id: \.id) { note in
                Button {
                    router.navigate(noteID: note.id, context: modelContext)
                    dismiss()
                } label: {
                    NoteCardView(note: note)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .animation(.default, value: searchResults)
        }
        .padding()
        .presentationDetents([.large])
        .onAppear {
            CSUserQuery.prepare()
        }
        .onDisappear {
            searchText = ""
            userQuery?.cancel()
            userQuery = nil
            handlerTask?.cancel()
            handlerTask = nil
            searchResults = []
        }
    }

    private func performSearch() {
        searchResults = []
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            return
        }
        userQuery?.cancel()
        handlerTask?.cancel()
        let queryContext = CSUserQueryContext()
        queryContext.fetchAttributes = ["title", "contentDescription"]
        queryContext.enableRankedResults = true
        queryContext.filterQueries = ["domainIdentifier == '\(SpotlightIndex.domainIdentifier)'"]
        let query = CSUserQuery(userQueryString: trimmedText, userQueryContext: queryContext)
        userQuery = query
        handlerTask = Task {
            await handleQueryResponses()
        }
    }

    @MainActor
    private func handleQueryResponses() async {
        guard let userQuery else {
            return
        }
        let store = NoteStore(context: modelContext)
        do {
            for try await element in userQuery.responses {
                guard case .item(let item) = element else {
                    continue
                }
                guard let id = UUID(uuidString: item.item.uniqueIdentifier) else {
                    AppLogging.general.error(
                        """
                        Failed to parse UUID from Spotlight identifier \
                        "\(item.item.uniqueIdentifier)"
                        """
                    )
                    continue
                }
                guard let note = store.fetchNote(withID: id) else {
                    AppLogging.general.error("Failed to fetch note with ID \(id)")
                    continue
                }
                if searchResults.contains(where: { $0.id == note.id }) {
                    continue
                }
                searchResults.append(note)
            }
        } catch {
            AppLogging.general.error(
                "Failed to fetch query responses: \(error.localizedDescription)"
            )
        }
        userQuery.cancel()
        self.userQuery = nil
    }
}
