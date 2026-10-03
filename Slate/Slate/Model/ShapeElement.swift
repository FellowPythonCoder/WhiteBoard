//
//  ShapeElement.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public enum ShapeType: String, Codable, CaseIterable, Sendable {
    case rectangle
    case ellipse
    case line
    case arrow
    case diamond
    case triangle
    
    public var displayName: String {
        switch self {
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .line: return "Line"
        case .arrow: return "Arrow"
        case .diamond: return "Diamond"
        case .triangle: return "Triangle"
        }
    }
    
    public var iconName: String {
        switch self {
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .line: return "line.diagonal"
        case .arrow: return "arrow.right"
        case .diamond: return "rhombus"
        case .triangle: return "triangle"
        }
    }
}

public enum ArrowheadStyle: String, Codable, CaseIterable, Sendable {
    case none
    case standard
    case triangle
    case diamond
    case circle
}

public struct ShapeElement: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var type: ShapeType
    public var origin: Point2D
    public var size: CGSize
    public var rotation: Double // In radians
    public var strokeColor: ColorData
    public var fillColor: ColorData
    public var strokeWidth: Double
    public var opacity: Double
    public var cornerRadius: Double
    public var dashPattern: [Double]?
    public var startArrowhead: ArrowheadStyle
    public var endArrowhead: ArrowheadStyle
    public var startPoint: Point2D? // For lines and arrows
    public var endPoint: Point2D?   // For lines and arrows
    public var isLocked: Bool
    public var zIndex: Int
    public var groupId: UUID?
    
    public init(
        id: UUID = UUID(),
        type: ShapeType = .rectangle,
        origin: Point2D = Point2D(x: 0, y: 0),
        size: CGSize = CGSize(width: 160, height: 100),
        rotation: Double = 0,
        strokeColor: ColorData = .ink,
        fillColor: ColorData = .clear,
        strokeWidth: Double = 2.0,
        opacity: Double = 1.0,
        cornerRadius: Double = 8.0,
        dashPattern: [Double]? = nil,
        startArrowhead: ArrowheadStyle = .none,
        endArrowhead: ArrowheadStyle = .standard,
        startPoint: Point2D? = nil,
        endPoint: Point2D? = nil,
        isLocked: Bool = false,
        zIndex: Int = 0,
        groupId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.origin = origin
        self.size = size
        self.rotation = rotation
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.strokeWidth = max(0.5, min(64.0, strokeWidth))
        self.opacity = max(0.01, min(1.0, opacity))
        self.cornerRadius = max(0, cornerRadius)
        self.dashPattern = dashPattern
        self.startArrowhead = startArrowhead
        self.endArrowhead = endArrowhead
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.isLocked = isLocked
        self.zIndex = zIndex
        self.groupId = groupId
    }
    
    public var bounds: CGRect {
        if type == .line || type == .arrow {
            let p1 = startPoint ?? origin
            let p2 = endPoint ?? Point2D(x: origin.x + size.width, y: origin.y + size.height)
            let minX = min(p1.x, p2.x) - strokeWidth - 8
            let minY = min(p1.y, p2.y) - strokeWidth - 8
            let maxX = max(p1.x, p2.x) + strokeWidth + 8
            let maxY = max(p1.y, p2.y) + strokeWidth + 8
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
        
        let rawRect = CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
        if abs(rotation) < 0.001 {
            return rawRect.insetBy(dx: -strokeWidth / 2.0, dy: -strokeWidth / 2.0)
        }
        
        // Compute rotated bounding box
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
            return CGPoint(
                x: center.x + (dx * cosA - dy * sinA),
                y: center.y + (dx * sinA + dy * cosA)
            )
        }
        
        let minX = corners.map(\.x).min() ?? rawRect.minX
        let maxX = corners.map(\.x).max() ?? rawRect.maxX
        let minY = corners.map(\.y).min() ?? rawRect.minY
        let maxY = corners.map(\.y).max() ?? rawRect.maxY
        
        return CGRect(x: minX - strokeWidth, y: minY - strokeWidth, width: (maxX - minX) + strokeWidth * 2, height: (maxY - minY) + strokeWidth * 2)
    }
    
    /// Magnetic anchor points for connectors
    public var connectionPoints: [Point2D] {
        let rect = CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
        return [
            Point2D(x: rect.midX, y: rect.minY), // Top
            Point2D(x: rect.maxX, y: rect.midY), // Right
            Point2D(x: rect.midX, y: rect.maxY), // Bottom
            Point2D(x: rect.minX, y: rect.midY)  // Left
        ]
    }
    
    public func hits(point: Point2D) -> Bool {
        if type == .line || type == .arrow {
            let p1 = startPoint ?? origin
            let p2 = endPoint ?? Point2D(x: origin.x + size.width, y: origin.y + size.height)
            let l2 = (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y)
            if l2 == 0 { return point.distance(to: p1) <= max(12.0, strokeWidth + 4.0) }
            var t = ((point.x - p1.x) * (p2.x - p1.x) + (point.y - p1.y) * (p2.y - p1.y)) / l2
            t = max(0, min(1, t))
            let projX = p1.x + t * (p2.x - p1.x)
            let projY = p1.y + t * (p2.y - p1.y)
            let dist = ((point.x - projX) * (point.x - projX) + (point.y - projY) * (point.y - projY)).squareRoot()
            return dist <= max(12.0, strokeWidth + 4.0)
        }
        
        // Un-rotate test point relative to center
        let center = CGPoint(x: origin.x + size.width / 2.0, y: origin.y + size.height / 2.0)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let cosA = cos(-rotation)
        let sinA = sin(-rotation)
        let localX = center.x + (dx * cosA - dy * sinA)
        let localY = center.y + (dx * sinA + dy * cosA)
        let localRect = CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
        
        switch type {
        case .rectangle:
            return localRect.contains(CGPoint(x: localX, y: localY))
        case .ellipse:
            let rx = size.width / 2.0
            let ry = size.height / 2.0
            guard rx > 0 && ry > 0 else { return false }
            let ex = (localX - center.x) / rx
            let ey = (localY - center.y) / ry
            return (ex * ex + ey * ey) <= 1.0
        case .diamond:
            let rx = size.width / 2.0
            let ry = size.height / 2.0
            guard rx > 0 && ry > 0 else { return false }
            let ex = abs(localX - center.x) / rx
            let ey = abs(localY - center.y) / ry
            return (ex + ey) <= 1.0
        case .triangle:
            let p1 = CGPoint(x: localRect.midX, y: localRect.minY)
            let p2 = CGPoint(x: localRect.maxX, y: localRect.maxY)
            let p3 = CGPoint(x: localRect.minX, y: localRect.maxY)
            return pointInTriangle(p: CGPoint(x: localX, y: localY), a: p1, b: p2, c: p3)
        case .line, .arrow:
            return false
        }
    }
    
    private func pointInTriangle(p: CGPoint, a: CGPoint, b: CGPoint, c: CGPoint) -> Bool {
        let d1 = (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y)
        let d2 = (p.x - c.x) * (b.y - c.y) - (b.x - c.x) * (p.y - c.y)
        let d3 = (p.x - a.x) * (c.y - a.y) - (c.x - a.x) * (p.y - a.y)
        let hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0)
        let hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0)
        return !(hasNeg && hasPos)
    }
}
