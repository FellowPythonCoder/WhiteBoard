//
//  TextElement.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public enum TextAlignment: String, Codable, CaseIterable, Sendable {
    case left
    case center
    case right
    case justified
}

public enum FontWeight: String, Codable, CaseIterable, Sendable {
    case ultraLight
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
}

public struct TextElement: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var text: String
    public var origin: Point2D
    public var size: CGSize
    public var rotation: Double
    public var fontSize: Double
    public var fontFamily: String
    public var fontWeight: FontWeight
    public var alignment: TextAlignment
    public var textColor: ColorData
    public var isLocked: Bool
    public var zIndex: Int
    public var groupId: UUID?
    
    public init(
        id: UUID = UUID(),
        text: String = "Double-click to edit",
        origin: Point2D = Point2D(x: 0, y: 0),
        size: CGSize = CGSize(width: 200, height: 40),
        rotation: Double = 0,
        fontSize: Double = 18.0,
        fontFamily: String = "SF Pro",
        fontWeight: FontWeight = .regular,
        alignment: TextAlignment = .left,
        textColor: ColorData = .ink,
        isLocked: Bool = false,
        zIndex: Int = 0,
        groupId: UUID? = nil
    ) {
        self.id = id
        self.text = text
        self.origin = origin
        self.size = size
        self.rotation = rotation
        self.fontSize = max(8.0, min(240.0, fontSize))
        self.fontFamily = fontFamily
        self.fontWeight = fontWeight
        self.alignment = alignment
        self.textColor = textColor
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
