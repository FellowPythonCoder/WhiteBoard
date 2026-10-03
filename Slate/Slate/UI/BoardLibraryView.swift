//
//  BoardLibraryView.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public struct BoardLibraryView: View {
    @ObservedObject public var documentStore: DocumentStore = .shared
    public var onSelectBoard: (UUID) -> Void
    public var onClose: () -> Void
    
    @State private var searchQuery: String = ""
    @State private var showOnlyFavorites: Bool = false
    @State private var boardToRename: BoardMetadata?
    @State private var newBoardTitle: String = ""
    
    public init(onSelectBoard: @escaping (UUID) -> Void, onClose: @escaping () -> Void) {
        self.onSelectBoard = onSelectBoard
        self.onClose = onClose
    }
    
    private var displayedBoards: [BoardMetadata] {
        var list = searchQuery.isEmpty ? documentStore.boards : documentStore.searchBoards(query: searchQuery)
        if showOnlyFavorites {
            list = list.filter { $0.isFavorite }
        }
        return list
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Text("Boards")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                // Search Field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    TextField("Search boards or notes...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(width: 200)
                
                Toggle(isOn: $showOnlyFavorites) {
                    Image(systemName: showOnlyFavorites ? "star.fill" : "star")
                        .foregroundColor(showOnlyFavorites ? .yellow : .secondary)
                }
                .toggleStyle(.button)
                .buttonStyle(.plain)
                
                Button(action: {
                    let newDoc = documentStore.createNewBoard()
                    onSelectBoard(newDoc.id)
                }) {
                    Label("New Board", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.leading, 6)
            }
            .padding(14)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Boards Card Grid
            ScrollView {
                if displayedBoards.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text(searchQuery.isEmpty ? "No boards yet" : "No boards match your search")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 16)], spacing: 16) {
                        ForEach(displayedBoards) { meta in
                            boardCard(meta: meta)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(minWidth: 640, minHeight: 460)
        .background(Color(nsColor: .underPageBackgroundColor))
    }
    
    private func boardCard(meta: BoardMetadata) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail Card Area
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(height: 130)
                
                // Vector Mini-canvas preview icon
                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Favorite Star
                Button(action: { documentStore.toggleFavorite(id: meta.id) }) {
                    Image(systemName: meta.isFavorite ? "star.fill" : "star")
                        .foregroundColor(meta.isFavorite ? .yellow : .secondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            
            // Title & Info
            VStack(alignment: .leading, spacing: 2) {
                Text(meta.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                
                HStack {
                    Text("\(meta.elementCount) items")
                    Spacer()
                    Text(meta.modifiedAt, style: .date)
                }
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 2)
        }
        .padding(8)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectBoard(meta.id)
        }
        .contextMenu {
            Button("Duplicate") { _ = documentStore.duplicateBoard(id: meta.id) }
            Button(meta.isFavorite ? "Unfavorite" : "Favorite") { documentStore.toggleFavorite(id: meta.id) }
            Divider()
            Button("Delete", role: .destructive) { documentStore.deleteBoard(id: meta.id) }
        }
    }
}
