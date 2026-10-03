//
//  AutosaveManager.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import Combine

/// Provides debounced background autosaving for Slate boards.
@MainActor
public final class AutosaveManager: ObservableObject {
    public static let shared = AutosaveManager()
    
    private var cancellable: AnyCancellable?
    private let debounceInterval: TimeInterval = 0.3
    private var pendingDocument: SlateDocument?
    private var pendingThumbnailPNG: Data?
    
    public init() {}
    
    public func scheduleSave(document: SlateDocument, thumbnailPNG: Data? = nil) {
        self.pendingDocument = document
        if let thumb = thumbnailPNG {
            self.pendingThumbnailPNG = thumb
        }
        
        cancellable?.cancel()
        cancellable = Just(())
            .delay(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.performSave()
            }
    }
    
    public func saveImmediatelyNow(document: SlateDocument, thumbnailPNG: Data? = nil) {
        cancellable?.cancel()
        self.pendingDocument = document
        if let thumb = thumbnailPNG {
            self.pendingThumbnailPNG = thumb
        }
        performSave()
    }
    
    private func performSave() {
        guard let doc = pendingDocument else { return }
        DocumentStore.shared.updateActiveDocument(doc, saveImmediately: true, thumbnailPNG: pendingThumbnailPNG)
        self.pendingDocument = nil
        self.pendingThumbnailPNG = nil
    }
}
