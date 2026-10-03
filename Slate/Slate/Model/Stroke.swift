//
//  Stroke.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

/// Represents a single continuous vector ink stroke drawn on the canvas.
public struct Stroke: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var points: [Point2D]
    public var color: ColorData
    public var width: Double
    public var opacity: Double
    public var isHighlighter: Bool
    public var dashPattern: [Double]?
    public var isLocked: Bool
    public var createdAt: Date
    public var zIndex: Int
    
    public init(
        id: UUID = UUID(),
        points: [Point2D] = [],
        color: ColorData = .ink,
        width: Double = 3.0,
        opacity: Double = 1.0,
        isHighlighter: Bool = false,
        dashPattern: [Double]? = nil,
        isLocked: Bool = false,
        createdAt: Date = Date(),
        zIndex: Int = 0
    ) {
        self.id = id
        self.points = points
        self.color = color
        self.width = max(0.5, min(120.0, width))
        self.opacity = max(0.01, min(1.0, opacity))
        self.isHighlighter = isHighlighter
        self.dashPattern = dashPattern
        self.isLocked = isLocked
        self.createdAt = createdAt
        self.zIndex = zIndex
    }
    
    /// Bounding rectangle for the stroke with padding for stroke width.
    public var bounds: CGRect {
        guard !points.isEmpty else { return .zero }
        var minX = Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude
        
        for pt in points {
            if pt.x < minX { minX = pt.x }
            if pt.y < minY { minY = pt.y }
            if pt.x > maxX { maxX = pt.x }
            if pt.y > maxY { maxY = pt.y }
        }
        
        let pad = width * 1.5 + 4.0
        return CGRect(
            x: minX - pad,
            y: minY - pad,
            width: (maxX - minX) + pad * 2.0,
            height: (maxY - minY) + pad * 2.0
        )
    }
    
    /// Checks if a test point is within radius distance of any segment in this stroke.
    public func hits(point: Point2D, tolerance: Double = 8.0) -> Bool {
        let testRadius = (width / 2.0) + tolerance
        guard points.count > 1 else {
            if let first = points.first {
                return first.distance(to: point) <= testRadius
            }
            return false
        }
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            if distanceToSegment(p: point, v: p1, w: p2) <= testRadius {
                return true
            }
        }
        return false
    }
    
    /// Splits the stroke into segments removing points within `eraserRadius` of `eraserCenter`.
    /// Used for pixel-style partial eraser.
    public func splitByEraser(eraserCenter: Point2D, eraserRadius: Double) -> [Stroke] {
        var resultStrokes: [Stroke] = []
        var currentChunk: [Point2D] = []
        
        for pt in points {
            if pt.distance(to: eraserCenter) <= eraserRadius {
                if currentChunk.count >= 2 {
                    var newStroke = self
                    newStroke.id = UUID()
                    newStroke.points = currentChunk
                    resultStrokes.append(newStroke)
                }
                currentChunk = []
            } else {
                currentChunk.append(pt)
            }
        }
        
        if currentChunk.count >= 2 {
            var newStroke = self
            newStroke.id = UUID()
            newStroke.points = currentChunk
            resultStrokes.append(newStroke)
        }
        
        return resultStrokes
    }
    
    /// Translates all points by delta.
    public func translated(by delta: CGPoint) -> Stroke {
        var copy = self
        copy.points = points.map { $0.translated(by: delta) }
        return copy
    }
    
    /// Scales all points relative to center.
    public func scaled(by scale: CGPoint, anchor: CGPoint) -> Stroke {
        var copy = self
        copy.points = points.map { pt in
            let nx = anchor.x + CGFloat(pt.x - Double(anchor.x)) * scale.x
            let ny = anchor.y + CGFloat(pt.y - Double(anchor.y)) * scale.y
            return Point2D(x: Double(nx), y: Double(ny), pressure: pt.pressure, timestamp: pt.timestamp)
        }
        copy.width = max(0.5, width * Double(scale.x + scale.y) / 2.0)
        return copy
    }
    
    private func distanceToSegment(p: Point2D, v: Point2D, w: Point2D) -> Double {
        let l2 = (w.x - v.x) * (w.x - v.x) + (w.y - v.y) * (w.y - v.y)
        if l2 == 0 { return p.distance(to: v) }
        var t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2
        t = max(0, min(1, t))
        let projX = v.x + t * (w.x - v.x)
        let projY = v.y + t * (w.y - v.y)
        let dx = p.x - projX
        let dy = p.y - projY
        return (dx * dx + dy * dy).squareRoot()
    }
}
