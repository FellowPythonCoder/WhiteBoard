//
//  TileCache.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public struct TileCoord: Hashable, Sendable {
    public let x: Int
    public let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public final class TileCache: @unchecked Sendable {
    public static let tileSize: Double = 512.0
    
    private var tileIndex: [TileCoord: Set<UUID>] = [:]
    private var dirtyTiles: Set<TileCoord> = []
    private let lock = NSLock()
    
    public init() {}
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        tileIndex.removeAll()
        dirtyTiles.removeAll()
    }
    
    public func getTileCoords(for rect: CGRect) -> [TileCoord] {
        let minX = Int(floor(rect.minX / Self.tileSize))
        let maxX = Int(floor(rect.maxX / Self.tileSize))
        let minY = Int(floor(rect.minY / Self.tileSize))
        let maxY = Int(floor(rect.maxY / Self.tileSize))
        
        var coords: [TileCoord] = []
        for x in minX...maxX {
            for y in minY...maxY {
                coords.append(TileCoord(x: x, y: y))
            }
        }
        return coords
    }
    
    public func indexElement(_ element: CanvasElement) {
        lock.lock()
        defer { lock.unlock() }
        let coords = getTileCoords(for: element.bounds)
        for c in coords {
            tileIndex[c, default: []].insert(element.id)
            dirtyTiles.insert(c)
        }
    }
    
    public func removeElement(id: UUID, bounds: CGRect) {
        lock.lock()
        defer { lock.unlock() }
        let coords = getTileCoords(for: bounds)
        for c in coords {
            tileIndex[c]?.remove(id)
            dirtyTiles.insert(c)
        }
    }
    
    public func getVisibleElementIDs(in viewportRect: CGRect) -> Set<UUID> {
        lock.lock()
        defer { lock.unlock() }
        let coords = getTileCoords(for: viewportRect)
        var visibleIds = Set<UUID>()
        for c in coords {
            if let ids = tileIndex[c] {
                visibleIds.formUnion(ids)
            }
        }
        return visibleIds
    }
    
    public func markAllDirty() {
        lock.lock()
        defer { lock.unlock() }
        for k in tileIndex.keys {
            dirtyTiles.insert(k)
        }
    }
}
