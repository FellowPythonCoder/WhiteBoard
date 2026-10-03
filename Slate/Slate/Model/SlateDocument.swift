//
//  SlateDocument.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public enum GridStyle: String, Codable, CaseIterable, Sendable {
    case dots
    case grid
    case lines
    case blank
    
    public var displayName: String {
        switch self {
        case .dots: return "Dots"
        case .grid: return "Grid"
        case .lines: return "Lines"
        case .blank: return "Blank"
        }
    }
}

public struct SlateDocument: Codable, Identifiable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    
    public var schemaVersion: Int
    public var metadata: BoardMetadata
    public var elements: [CanvasElement]
    public var gridStyle: GridStyle
    public var gridSize: Double
    public var snapToGrid: Bool
    public var snapToObjects: Bool
    public var showRulers: Bool
    public var showMinimap: Bool
    public var canvasBackground: ColorData
    public var viewportOffset: Point2D
    public var viewportZoom: Double
    public var snapshots: [BoardSnapshot]
    
    public var id: UUID { metadata.id }
    
    public init(
        metadata: BoardMetadata = BoardMetadata(),
        elements: [CanvasElement] = [],
        gridStyle: GridStyle = .dots,
        gridSize: Double = 24.0,
        snapToGrid: Bool = true,
        snapToObjects: Bool = true,
        showRulers: Bool = false,
        showMinimap: Bool = true,
        canvasBackground: ColorData = .white,
        viewportOffset: Point2D = Point2D(x: 0, y: 0),
        viewportZoom: Double = 1.0,
        snapshots: [BoardSnapshot] = []
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.metadata = metadata
        self.elements = elements
        self.gridStyle = gridStyle
        self.gridSize = gridSize
        self.snapToGrid = snapToGrid
        self.snapToObjects = snapToObjects
        self.showRulers = showRulers
        self.showMinimap = showMinimap
        self.canvasBackground = canvasBackground
        self.viewportOffset = viewportOffset
        self.viewportZoom = viewportZoom
        self.snapshots = snapshots
        self.updateCounts()
    }
    
    public mutating func updateCounts() {
        let strokes = elements.filter {
            if case .stroke = $0 { return true }
            return false
        }.count
        metadata.strokeCount = strokes
        metadata.elementCount = elements.count
        metadata.modifiedAt = Date()
    }
    
    public func element(with id: UUID) -> CanvasElement? {
        elements.first { $0.id == id }
    }
    
    public mutating func addElement(_ element: CanvasElement) {
        elements.append(element)
        updateCounts()
    }
    
    public mutating func removeElements(with ids: Set<UUID>) {
        elements.removeAll { ids.contains($0.id) }
        updateCounts()
    }
    
    public mutating func updateElement(_ element: CanvasElement) {
        if let idx = elements.firstIndex(where: { $0.id == element.id }) {
            elements[idx] = element
            updateCounts()
        }
    }
    
    /// Returns the combined bounding box of all elements on the canvas (or a default 1000x800 if empty).
    public var contentBounds: CGRect {
        guard !elements.isEmpty else {
            return CGRect(x: 0, y: 0, width: 1200, height: 800)
        }
        var rect = elements[0].bounds
        for el in elements.dropFirst() {
            rect = rect.union(el.bounds)
        }
        return rect.insetBy(dx: -40, dy: -40)
    }
    
    /// Bounding box for a specific set of selected element IDs
    public func selectionBounds(for ids: Set<UUID>) -> CGRect? {
        let selected = elements.filter { ids.contains($0.id) }
        guard let first = selected.first else { return nil }
        var rect = first.bounds
        for el in selected.dropFirst() {
            rect = rect.union(el.bounds)
        }
        return rect
    }
    
    /// Creates a snapshot checkpoint of the current document state
    public mutating func createSnapshot(label: String = "Checkpoint") {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(self), let jsonString = String(data: data, encoding: .utf8) {
            let snap = BoardSnapshot(
                id: UUID(),
                timestamp: Date(),
                label: label,
                strokeCount: metadata.strokeCount,
                elementCount: metadata.elementCount,
                serializedDocument: jsonString
            )
            snapshots.insert(snap, at: 0)
            if snapshots.count > 50 {
                snapshots.removeLast()
            }
        }
    }
    
    /// Restores document state from a snapshot
    public mutating func restoreSnapshot(_ snapshot: BoardSnapshot) -> Bool {
        guard let data = snapshot.serializedDocument.data(using: .utf8) else { return false }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let doc = try? decoder.decode(SlateDocument.self, from: data) else { return false }
        self = doc
        return true
    }
}
