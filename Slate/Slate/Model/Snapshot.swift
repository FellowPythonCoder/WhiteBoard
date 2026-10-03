//
//  Snapshot.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation

public struct BoardSnapshot: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var label: String
    public var strokeCount: Int
    public var elementCount: Int
    public var serializedDocument: String // JSON representation of SlateDocument
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        label: String = "Checkpoint",
        strokeCount: Int = 0,
        elementCount: Int = 0,
        serializedDocument: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.label = label
        self.strokeCount = strokeCount
        self.elementCount = elementCount
        self.serializedDocument = serializedDocument
    }
}
