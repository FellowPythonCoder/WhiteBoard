//
//  ImageElement.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public struct ImageElement: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var assetId: String // Relative filename or hash in the package assets/ folder
    public var origin: Point2D
    public var size: CGSize
    public var rotation: Double
    public var opacity: Double
    public var cornerRadius: Double
    public var rawImageData: Data? // Inlined for export/undo or nil when loaded from package
    public var isLocked: Bool
    public var zIndex: Int
    public var groupId: UUID?
    
    public init(
        id: UUID = UUID(),
        assetId: String = UUID().uuidString + ".png",
        origin: Point2D = Point2D(x: 0, y: 0),
        size: CGSize = CGSize(width: 320, height: 240),
        rotation: Double = 0,
        opacity: Double = 1.0,
        cornerRadius: Double = 4.0,
        rawImageData: Data? = nil,
        isLocked: Bool = false,
        zIndex: Int = 0,
        groupId: UUID? = nil
    ) {
        self.id = id
        self.assetId = assetId
        self.origin = origin
        self.size = size
        self.rotation = rotation
        self.opacity = max(0.01, min(1.0, opacity))
        self.cornerRadius = max(0, cornerRadius)
        self.rawImageData = rawImageData
        self.isLocked = isLocked
        self.zIndex = zIndex
        self.groupId = groupId
    }
    
    public var bounds: CGRect {
        let rawRect = CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
        if abs(rotation) < 0.001 {
            return rawRect
        }
        let center = CGPoint(x: rawRect.midX, y: rawRect.midY)
        let corners = [
            CGPoint(x: rawRect.minX, y: rawRect.minY),
            CGPoint(x: rawRect.maxX, y: rawRect.minY),
            CGPoint(x: rawRect.maxX, y: rawRect.maxY),
            CGPoint(x: rawRect.minX, y: rawRect.maxY)
        ].map { pt -> CGPoint in
            let dx = pt.x - center.x
            let dy = pt.y - center.y
            let cosA = cos(rotation)
            let sinA = sin(rotation)
            return CGPoint(x: center.x + (dx * cosA - dy * sinA), y: center.y + (dx * sinA + dy * cosA))
        }
        let minX = corners.map(\.x).min() ?? rawRect.minX
        let maxX = corners.map(\.x).max() ?? rawRect.maxX
        let minY = corners.map(\.y).min() ?? rawRect.minY
        let maxY = corners.map(\.y).max() ?? rawRect.maxY
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    public func hits(point: Point2D) -> Bool {
        bounds.contains(point.cgPoint)
    }
}
