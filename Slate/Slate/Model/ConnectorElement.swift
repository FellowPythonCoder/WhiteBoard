//
//  ConnectorElement.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public enum ConnectorRouting: String, Codable, CaseIterable, Sendable {
    case straight
    case orthogonal
    case curved
}

public struct ConnectorAnchor: Codable, Equatable, Hashable, Sendable {
    public var elementId: UUID?
    public var anchorIndex: Int // 0: Top, 1: Right, 2: Bottom, 3: Left
    public var relativeOffset: Point2D // (0.0 ... 1.0) on element bounding box
    public var absolutePoint: Point2D
    
    public init(elementId: UUID? = nil, anchorIndex: Int = 0, relativeOffset: Point2D = Point2D(x: 0.5, y: 0.5), absolutePoint: Point2D = Point2D(x: 0, y: 0)) {
        self.elementId = elementId
        self.anchorIndex = anchorIndex
        self.relativeOffset = relativeOffset
        self.absolutePoint = absolutePoint
    }
}

public struct ConnectorElement: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var startAnchor: ConnectorAnchor
    public var endAnchor: ConnectorAnchor
    public var routing: ConnectorRouting
    public var strokeColor: ColorData
    public var strokeWidth: Double
    public var opacity: Double
    public var dashPattern: [Double]?
    public var startArrowhead: ArrowheadStyle
    public var endArrowhead: ArrowheadStyle
    public var label: String?
    public var isLocked: Bool
    public var zIndex: Int
    
    public init(
        id: UUID = UUID(),
        startAnchor: ConnectorAnchor = ConnectorAnchor(),
        endAnchor: ConnectorAnchor = ConnectorAnchor(),
        routing: ConnectorRouting = .orthogonal,
        strokeColor: ColorData = .ink,
        strokeWidth: Double = 2.0,
        opacity: Double = 1.0,
        dashPattern: [Double]? = nil,
        startArrowhead: ArrowheadStyle = .none,
        endArrowhead: ArrowheadStyle = .standard,
        label: String? = nil,
        isLocked: Bool = false,
        zIndex: Int = 0
    ) {
        self.id = id
        self.startAnchor = startAnchor
        self.endAnchor = endAnchor
        self.routing = routing
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.opacity = opacity
        self.dashPattern = dashPattern
        self.startArrowhead = startArrowhead
        self.endArrowhead = endArrowhead
        self.label = label
        self.isLocked = isLocked
        self.zIndex = zIndex
    }
    
    /// Generates key points along the connector route given start and end absolute positions.
    public func computePathPoints(startPt: Point2D, endPt: Point2D) -> [Point2D] {
        switch routing {
        case .straight:
            return [startPt, endPt]
        case .orthogonal:
            let midX = (startPt.x + endPt.x) / 2.0
            return [
                startPt,
                Point2D(x: midX, y: startPt.y),
                Point2D(x: midX, y: endPt.y),
                endPt
            ]
        case .curved:
            // 4 points representing a cubic bezier curve
            let dx = abs(endPt.x - startPt.x) * 0.5
            let c1 = Point2D(x: startPt.x + dx, y: startPt.y)
            let c2 = Point2D(x: endPt.x - dx, y: endPt.y)
            return [startPt, c1, c2, endPt]
        }
    }
    
    public var bounds: CGRect {
        let p1 = startAnchor.absolutePoint
        let p2 = endAnchor.absolutePoint
        let minX = min(p1.x, p2.x) - strokeWidth - 12
        let minY = min(p1.y, p2.y) - strokeWidth - 12
        let maxX = max(p1.x, p2.x) + strokeWidth + 12
        let maxY = max(p1.y, p2.y) + strokeWidth + 12
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    public func hits(point: Point2D) -> Bool {
        let pts = computePathPoints(startPt: startAnchor.absolutePoint, endPt: endAnchor.absolutePoint)
        for i in 0..<(pts.count - 1) {
            let p1 = pts[i]
            let p2 = pts[i + 1]
            let l2 = (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y)
            let dist: Double
            if l2 == 0 {
                dist = point.distance(to: p1)
            } else {
                var t = ((point.x - p1.x) * (p2.x - p1.x) + (point.y - p1.y) * (p2.y - p1.y)) / l2
                t = max(0, min(1, t))
                let projX = p1.x + t * (p2.x - p1.x)
                let projY = p1.y + t * (p2.y - p1.y)
                dist = ((point.x - projX) * (point.x - projX) + (point.y - projY) * (point.y - projY)).squareRoot()
            }
            if dist <= max(10.0, strokeWidth + 4.0) {
                return true
            }
        }
        return false
    }
}
