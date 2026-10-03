//
//  CanvasCoordinateTransform.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public struct CanvasCoordinateTransform: Sendable {
    public var offset: CGPoint // In canvas coordinates
    public var zoom: CGFloat   // Scale factor (e.g. 1.0 = 100%)
    
    public init(offset: CGPoint = .zero, zoom: CGFloat = 1.0) {
        self.offset = offset
        self.zoom = max(0.1, min(10.0, zoom))
    }
    
    /// Converts a point from window/view coordinates to infinite canvas coordinates.
    public func canvasPoint(from viewPoint: CGPoint) -> Point2D {
        let cx = (viewPoint.x / zoom) - offset.x
        let cy = (viewPoint.y / zoom) - offset.y
        return Point2D(x: Double(cx), y: Double(cy))
    }
    
    /// Converts a point from canvas coordinates to view/window coordinates.
    public func viewPoint(from canvasPoint: Point2D) -> CGPoint {
        let vx = (CGFloat(canvasPoint.x) + offset.x) * zoom
        let vy = (CGFloat(canvasPoint.y) + offset.y) * zoom
        return CGPoint(x: vx, y: vy)
    }
    
    /// Converts a rect from canvas coordinates to view coordinates.
    public func viewRect(from canvasRect: CGRect) -> CGRect {
        let p = viewPoint(from: Point2D(x: Double(canvasRect.minX), y: Double(canvasRect.minY)))
        return CGRect(
            x: p.x,
            y: p.y,
            width: canvasRect.width * zoom,
            height: canvasRect.height * zoom
        )
    }
    
    /// Converts a rect from view coordinates to canvas coordinates.
    public func canvasRect(from viewRect: CGRect) -> CGRect {
        let p = canvasPoint(from: CGPoint(x: viewRect.minX, y: viewRect.minY))
        return CGRect(
            x: CGFloat(p.x),
            y: CGFloat(p.y),
            width: viewRect.width / zoom,
            height: viewRect.height / zoom
        )
    }
}
