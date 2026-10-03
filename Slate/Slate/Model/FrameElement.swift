//
//  FrameElement.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public struct FrameElement: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var origin: Point2D
    public var size: CGSize
    public var backgroundColor: ColorData
    public var strokeColor: ColorData
    public var orderIndex: Int // For presentation mode slide order
    public var isLocked: Bool
    public var zIndex: Int
    
    public init(
        id: UUID = UUID(),
        title: String = "Frame",
        origin: Point2D = Point2D(x: 0, y: 0),
        size: CGSize = CGSize(width: 800, height: 600),
        backgroundColor: ColorData = ColorData(red: 0.98, green: 0.98, blue: 0.99, alpha: 0.8),
        strokeColor: ColorData = ColorData(hex: "#CBD5E1"),
        orderIndex: Int = 0,
        isLocked: Bool = false,
        zIndex: Int = -1000 // Frames typically sit behind content
    ) {
        self.id = id
        self.title = title
        self.origin = origin
        self.size = size
        self.backgroundColor = backgroundColor
        self.strokeColor = strokeColor
        self.orderIndex = orderIndex
        self.isLocked = isLocked
        self.zIndex = zIndex
    }
    
    public var bounds: CGRect {
        CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }
    
    public var titleBarBounds: CGRect {
        CGRect(x: origin.x, y: origin.y - 28, width: size.width, height: 28)
    }
    
    public func hits(point: Point2D) -> Bool {
        bounds.contains(point.cgPoint) || titleBarBounds.contains(point.cgPoint)
    }
}
