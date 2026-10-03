//
//  StickyNoteElement.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public enum StickyColorTheme: String, Codable, CaseIterable, Sendable {
    case yellow
    case green
    case blue
    case pink
    case orange
    case purple
    case gray
    
    public var backgroundColor: ColorData {
        switch self {
        case .yellow: return .stickyYellow
        case .green: return .stickyGreen
        case .blue: return .stickyBlue
        case .pink: return .stickyPink
        case .orange: return .stickyOrange
        case .purple: return .stickyPurple
        case .gray: return .stickyGray
        }
    }
    
    public var textColor: ColorData {
        return .ink
    }
}

public struct StickyNoteElement: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var text: String
    public var origin: Point2D
    public var size: CGSize
    public var rotation: Double
    public var theme: StickyColorTheme
    public var fontSize: Double
    public var isLocked: Bool
    public var zIndex: Int
    public var groupId: UUID?
    
    public init(
        id: UUID = UUID(),
        text: String = "Note",
        origin: Point2D = Point2D(x: 0, y: 0),
        size: CGSize = CGSize(width: 180, height: 180),
        rotation: Double = 0,
        theme: StickyColorTheme = .yellow,
        fontSize: Double = 16.0,
        isLocked: Bool = false,
        zIndex: Int = 0,
        groupId: UUID? = nil
    ) {
        self.id = id
        self.text = text
        self.origin = origin
        self.size = size
        self.rotation = rotation
        self.theme = theme
        self.fontSize = max(10.0, min(72.0, fontSize))
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
