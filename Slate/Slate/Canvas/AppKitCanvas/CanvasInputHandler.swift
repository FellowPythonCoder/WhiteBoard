//
//  CanvasInputHandler.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

public enum TransformHandle: String, Sendable {
    case topLeft, topCenter, topRight
    case middleLeft, middleRight
    case bottomLeft, bottomCenter, bottomRight
    case rotation
}

public protocol CanvasInputDelegate: AnyObject {
    func canvasDidUpdateStroke(_ stroke: Stroke?)
    func canvasDidAddElement(_ element: CanvasElement)
    func canvasDidModifyElement(_ element: CanvasElement)
    func canvasDidRemoveElements(_ ids: Set<UUID>)
    func canvasDidChangeSelection(_ selectedIds: Set<UUID>)
    func canvasDidUpdateLaserPoints(_ points: [LaserPoint])
    func canvasDidRequestRedraw()
}

public final class CanvasInputHandler {
    public weak var delegate: CanvasInputDelegate?
    
    public var currentPoints: [Point2D] = []
    public var isDrawing: Bool = false
    public var isHolding: Bool = false
    public var activeTransformHandle: TransformHandle?
    public var initialSelectionBounds: CGRect?
    public var dragStartPoint: Point2D?
    
    private var holdToSnapTimer: Timer?
    private let pointFilter = Point2DOneEuroFilter()
    
    public init() {}
    
    public func startStroke(point: Point2D, enableHoldToSnap: Bool = true) {
        pointFilter.reset()
        let filtered = pointFilter.filter(point: point)
        currentPoints = [filtered]
        isDrawing = true
        isHolding = false
        
        if enableHoldToSnap {
            startHoldTimer()
        }
    }
    
    public func continueStroke(point: Point2D, straightLineWithShift: Bool = false) {
        guard isDrawing else { return }
        resetHoldTimer()
        
        if straightLineWithShift, let first = currentPoints.first {
            let dx = point.x - first.x
            let dy = point.y - first.y
            if abs(dx) > abs(dy) {
                currentPoints = [first, Point2D(x: point.x, y: first.y, pressure: point.pressure, timestamp: point.timestamp)]
            } else {
                currentPoints = [first, Point2D(x: first.x, y: point.y, pressure: point.pressure, timestamp: point.timestamp)]
            }
            return
        }
        
        let filtered = pointFilter.filter(point: point)
        currentPoints.append(filtered)
    }
    
    public func endStroke() -> [Point2D] {
        holdToSnapTimer?.invalidate()
        holdToSnapTimer = nil
        isDrawing = false
        let pts = currentPoints
        currentPoints = []
        return pts
    }
    
    private func startHoldTimer() {
        holdToSnapTimer?.invalidate()
        holdToSnapTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
            guard let self = self, self.isDrawing, self.currentPoints.count >= 8 else { return }
            self.isHolding = true
        }
    }
    
    private func resetHoldTimer() {
        holdToSnapTimer?.invalidate()
        startHoldTimer()
    }
}
