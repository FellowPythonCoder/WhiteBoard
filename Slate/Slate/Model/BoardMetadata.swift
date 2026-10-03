//
//  BoardMetadata.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation

public struct BoardMetadata: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var createdAt: Date
    public var modifiedAt: Date
    public var isFavorite: Bool
    public var tags: [String]
    public var strokeCount: Int
    public var elementCount: Int
    public var thumbnailAssetId: String?
    
    public init(
        id: UUID = UUID(),
        title: String = "Untitled Board",
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isFavorite: Bool = false,
        tags: [String] = [],
        strokeCount: Int = 0,
        elementCount: Int = 0,
        thumbnailAssetId: String? = "thumbnail.png"
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isFavorite = isFavorite
        self.tags = tags
        self.strokeCount = strokeCount
        self.elementCount = elementCount
        self.thumbnailAssetId = thumbnailAssetId
    }
}
