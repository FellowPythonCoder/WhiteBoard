//
//  DocumentStore.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import Combine

/// Manages local boards storage, indexing, recent boards, search, and file operations.
@MainActor
public final class DocumentStore: ObservableObject {
    public static let shared = DocumentStore()
    
    @Published public private(set) var boards: [BoardMetadata] = []
    @Published public private(set) var activeDocument: SlateDocument?
    @Published public private(set) var activeDocumentURL: URL?
    @Published public var assetDataCache: [String: Data] = [:]
    
    private let fileManager = FileManager.default
    private var baseDirectory: URL
    
    public init(customBaseDirectory: URL? = nil) {
        if let dir = customBaseDirectory {
            self.baseDirectory = dir
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseDirectory = appSupport.appendingPathComponent("Slate/Boards", isDirectory: true)
        }
        createDirectoryIfNeeded()
        reloadBoardsList()
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
    }
    
    public func reloadBoardsList() {
        createDirectoryIfNeeded()
        guard let items = try? fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            self.boards = []
            return
        }
        
        var list: [BoardMetadata] = []
        for url in items where url.pathExtension == SlatePackage.packageExtension {
            if let meta = SlatePackage.readMetadata(from: url) {
                list.append(meta)
            }
        }
        
        list.sort { $0.modifiedAt > $1.modifiedAt }
        self.boards = list
    }
    
    public func createNewBoard(title: String = "Untitled Board") -> SlateDocument {
        let id = UUID()
        var meta = BoardMetadata(id: id, title: title, createdAt: Date(), modifiedAt: Date())
        let doc = SlateDocument(metadata: meta)
        let packageURL = baseDirectory.appendingPathComponent("\(id.uuidString).\(SlatePackage.packageExtension)")
        
        try? SlatePackage.save(document: doc, to: packageURL)
        reloadBoardsList()
        return doc
    }
    
    public func loadBoard(id: UUID) -> SlateDocument? {
        let packageURL = baseDirectory.appendingPathComponent("\(id.uuidString).\(SlatePackage.packageExtension)")
        guard fileManager.fileExists(atPath: packageURL.path) else { return nil }
        
        do {
            let (doc, assets, _) = try SlatePackage.load(from: packageURL)
            self.activeDocument = doc
            self.activeDocumentURL = packageURL
            self.assetDataCache = assets
            return doc
        } catch {
            print("Failed to load board: \(error)")
            return nil
        }
    }
    
    public func saveActiveDocument(thumbnailPNG: Data? = nil) {
        guard var doc = activeDocument else { return }
        doc.updateCounts()
        self.activeDocument = doc
        
        let packageURL = activeDocumentURL ?? baseDirectory.appendingPathComponent("\(doc.id.uuidString).\(SlatePackage.packageExtension)")
        self.activeDocumentURL = packageURL
        
        do {
            try SlatePackage.save(document: doc, to: packageURL, thumbnailPNG: thumbnailPNG, assetDataMap: assetDataCache)
            reloadBoardsList()
        } catch {
            print("Error saving active document: \(error)")
        }
    }
    
    public func updateActiveDocument(_ doc: SlateDocument, saveImmediately: Bool = false, thumbnailPNG: Data? = nil) {
        self.activeDocument = doc
        if saveImmediately {
            saveActiveDocument(thumbnailPNG: thumbnailPNG)
        }
    }
    
    public func renameBoard(id: UUID, newTitle: String) {
        let packageURL = baseDirectory.appendingPathComponent("\(id.uuidString).\(SlatePackage.packageExtension)")
        guard fileManager.fileExists(atPath: packageURL.path),
              var (doc, assets, thumb) = try? SlatePackage.load(from: packageURL) else { return }
        
        doc.metadata.title = newTitle
        doc.metadata.modifiedAt = Date()
        try? SlatePackage.save(document: doc, to: packageURL, thumbnailPNG: thumb, assetDataMap: assets)
        
        if activeDocument?.id == id {
            activeDocument?.metadata.title = newTitle
        }
        reloadBoardsList()
    }
    
    public func toggleFavorite(id: UUID) {
        let packageURL = baseDirectory.appendingPathComponent("\(id.uuidString).\(SlatePackage.packageExtension)")
        guard fileManager.fileExists(atPath: packageURL.path),
              var (doc, assets, thumb) = try? SlatePackage.load(from: packageURL) else { return }
        
        doc.metadata.isFavorite.toggle()
        doc.metadata.modifiedAt = Date()
        try? SlatePackage.save(document: doc, to: packageURL, thumbnailPNG: thumb, assetDataMap: assets)
        
        if activeDocument?.id == id {
            activeDocument?.metadata.isFavorite = doc.metadata.isFavorite
        }
        reloadBoardsList()
    }
    
    public func duplicateBoard(id: UUID) -> SlateDocument? {
        let packageURL = baseDirectory.appendingPathComponent("\(id.uuidString).\(SlatePackage.packageExtension)")
        guard fileManager.fileExists(atPath: packageURL.path),
              let (doc, assets, thumb) = try? SlatePackage.load(from: packageURL) else { return nil }
        
        var newDoc = doc
        let newId = UUID()
        newDoc.metadata.id = newId
        newDoc.metadata.title = "\(doc.metadata.title) Copy"
        newDoc.metadata.createdAt = Date()
        newDoc.metadata.modifiedAt = Date()
        
        let newURL = baseDirectory.appendingPathComponent("\(newId.uuidString).\(SlatePackage.packageExtension)")
        try? SlatePackage.save(document: newDoc, to: newURL, thumbnailPNG: thumb, assetDataMap: assets)
        reloadBoardsList()
        return newDoc
    }
    
    public func deleteBoard(id: UUID) {
        let packageURL = baseDirectory.appendingPathComponent("\(id.uuidString).\(SlatePackage.packageExtension)")
        try? fileManager.removeItem(at: packageURL)
        if activeDocument?.id == id {
            activeDocument = nil
            activeDocumentURL = nil
        }
        reloadBoardsList()
    }
    
    public func searchBoards(query: String) -> [BoardMetadata] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return boards }
        
        return boards.filter { meta in
            if meta.title.lowercased().contains(trimmed) { return true }
            if meta.tags.contains(where: { $0.lowercased().contains(trimmed) }) { return true }
            
            // Search inside document text elements
            let packageURL = baseDirectory.appendingPathComponent("\(meta.id.uuidString).\(SlatePackage.packageExtension)")
            if let (doc, _, _) = try? SlatePackage.load(from: packageURL) {
                for el in doc.elements {
                    switch el {
                    case .text(let t):
                        if t.text.lowercased().contains(trimmed) { return true }
                    case .sticky(let st):
                        if st.text.lowercased().contains(trimmed) { return true }
                    case .frame(let f):
                        if f.title.lowercased().contains(trimmed) { return true }
                    default:
                        break
                    }
                }
            }
            return false
        }
    }
}
