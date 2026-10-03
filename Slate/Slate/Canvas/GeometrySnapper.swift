//
//  GeometrySnapper.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public struct SnappedShapeResult: Sendable {
    public var shapeElement: ShapeElement
    public var confidence: Double
}

/// Rule-based geometric shape recognizer (Zero ML).
public final class GeometrySnapper {
    
    public static func recognize(stroke: Stroke) -> SnappedShapeResult? {
        let pts = stroke.points
        guard pts.count >= 8 else { return nil }
        
        let startPt = pts.first!
        let endPt = pts.last!
        let strokeBounds = stroke.bounds
        let width = strokeBounds.width
        let height = strokeBounds.height
        let diagonal = (width * width + height * height).squareRoot()
        
        let startToEndDist = startPt.distance(to: endPt)
        let isClosed = startToEndDist < max(24.0, diagonal * 0.2)
        
        // Calculate total perimeter length
        var totalLength = 0.0
        for i in 0..<(pts.count - 1) {
            totalLength += pts[i].distance(to: pts[i + 1])
        }
        
        if isClosed {
            // Find corners based on angle changes
            let corners = findCorners(points: pts)
            
            // 1. Triangle Check (3 prominent corners)
            if corners.count == 3 {
                let shape = ShapeElement(
                    type: .triangle,
                    origin: Point2D(x: Double(strokeBounds.minX), y: Double(strokeBounds.minY)),
                    size: CGSize(width: width, height: height),
                    strokeColor: stroke.color,
                    fillColor: .clear,
                    strokeWidth: stroke.width,
                    opacity: stroke.opacity
                )
                return SnappedShapeResult(shapeElement: shape, confidence: 0.85)
            }
            
            // 2. 4 Corners -> Rectangle or Diamond
            if corners.count == 4 {
                // Check if corners are aligned with axis or rotated 45 deg (diamond)
                let c0 = corners[0]
                let c1 = corners[1]
                let angle = atan2(c1.y - c0.y, c1.x - c0.x) * 180.0 / Double.pi
                let isDiamond = abs(abs(angle) - 45.0) < 18.0
                
                let shape = ShapeElement(
                    type: isDiamond ? .diamond : .rectangle,
                    origin: Point2D(x: Double(strokeBounds.minX), y: Double(strokeBounds.minY)),
                    size: CGSize(width: width, height: height),
                    strokeColor: stroke.color,
                    fillColor: .clear,
                    strokeWidth: stroke.width,
                    opacity: stroke.opacity,
                    cornerRadius: isDiamond ? 0 : 8.0
                )
                return SnappedShapeResult(shapeElement: shape, confidence: 0.88)
            }
            
            // 3. Ellipse or Circle Check
            let expectedPerimeter = Double.pi * (width + height) / 2.0
            let perimeterRatio = totalLength / expectedPerimeter
            
            if perimeterRatio > 0.75 && perimeterRatio < 1.35 {
                let aspectRatio = min(width, height) / max(width, height)
                let isCircle = aspectRatio > 0.82
                
                let shape = ShapeElement(
                    type: .ellipse,
                    origin: Point2D(x: Double(strokeBounds.minX), y: Double(strokeBounds.minY)),
                    size: isCircle ? CGSize(width: max(width, height), height: max(width, height)) : CGSize(width: width, height: height),
                    strokeColor: stroke.color,
                    fillColor: .clear,
                    strokeWidth: stroke.width,
                    opacity: stroke.opacity
                )
                return SnappedShapeResult(shapeElement: shape, confidence: 0.90)
            }
        } else {
            // Open stroke: Line or Arrow
            let directDist = startPt.distance(to: endPt)
            let straightness = directDist / max(1.0, totalLength)
            
            // Arrow detection: Check if end has a sharp back-and-forth arrowhead hook
            let hasArrowhead = checkArrowhead(points: pts)
            
            if straightness > 0.85 || (hasArrowhead && straightness > 0.70) {
                // Snap angle to 15-degree increments if close
                let dx = endPt.x - startPt.x
                let dy = endPt.y - startPt.y
                var angle = atan2(dy, dx)
                let snapAngle = round(angle / (Double.pi / 12.0)) * (Double.pi / 12.0)
                if abs(angle - snapAngle) < (Double.pi / 24.0) {
                    angle = snapAngle
                }
                
                let length = directDist
                let snappedEnd = Point2D(
                    x: startPt.x + cos(angle) * length,
                    y: startPt.y + sin(angle) * length
                )
                
                let shape = ShapeElement(
                    type: hasArrowhead ? .arrow : .line,
                    origin: startPt,
                    size: CGSize(width: abs(snappedEnd.x - startPt.x), height: abs(snappedEnd.y - startPt.y)),
                    strokeColor: stroke.color,
                    fillColor: .clear,
                    strokeWidth: stroke.width,
                    opacity: stroke.opacity,
                    endArrowhead: hasArrowhead ? .standard : .none,
                    startPoint: startPt,
                    endPoint: snappedEnd
                )
                return SnappedShapeResult(shapeElement: shape, confidence: 0.92)
            }
        }
        
        return nil
    }
    
    private static func findCorners(points: [Point2D], step: Int = 4, angleThresholdDegrees: Double = 45.0) -> [Point2D] {
        guard points.count >= step * 2 + 1 else { return [] }
        var corners: [Point2D] = []
        
        for i in step..<(points.count - step) {
            let pPrev = points[i - step]
            let pCurr = points[i]
            let pNext = points[i + step]
            
            let v1 = Point2D(x: pCurr.x - pPrev.x, y: pCurr.y - pPrev.y)
            let v2 = Point2D(x: pNext.x - pCurr.x, y: pNext.y - pCurr.y)
            
            let l1 = (v1.x * v1.x + v1.y * v1.y).squareRoot()
            let l2 = (v2.x * v2.x + v2.y * v2.y).squareRoot()
            if l1 < 1.0 || l2 < 1.0 { continue }
            
            let dot = (v1.x * v2.x + v1.y * v2.y) / (l1 * l2)
            let clampedDot = max(-1.0, min(1.0, dot))
            let angleRad = acos(clampedDot)
            let angleDeg = angleRad * 180.0 / Double.pi
            
            if angleDeg > angleThresholdDegrees {
                // Ensure not too close to previously detected corner
                if let last = corners.last {
                    if last.distance(to: pCurr) > 20.0 {
                        corners.append(pCurr)
                    }
                } else {
                    corners.append(pCurr)
                }
            }
        }
        
        return corners
    }
    
    private static func checkArrowhead(points: [Point2D]) -> Bool {
        guard points.count >= 12 else { return false }
        let endIdx = points.count - 1
        let pEnd = points[endIdx]
        let pBack = points[max(0, endIdx - 8)]
        
        // If the stroke turns back on itself sharply in the last 20%
        let v1 = Point2D(x: pEnd.x - pBack.x, y: pEnd.y - pBack.y)
        let pOrigin = points[0]
        let vMain = Point2D(x: pEnd.x - pOrigin.x, y: pEnd.y - pOrigin.y)
        
        let l1 = (v1.x * v1.x + v1.y * v1.y).squareRoot()
        let l2 = (vMain.x * vMain.x + vMain.y * vMain.y).squareRoot()
        if l1 < 2.0 || l2 < 2.0 { return false }
        
        let dot = (v1.x * vMain.x + v1.y * vMain.y) / (l1 * l2)
        return dot < 0.2 // Sharp turn
    }
}
