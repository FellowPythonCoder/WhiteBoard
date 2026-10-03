//
//  AlignmentEngine.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public struct AlignmentGuide: Identifiable, Sendable {
    public var id = UUID()
    public var isVertical: Bool
    public var position: CGFloat
    public var start: CGFloat
    public var end: CGFloat
}

public struct SnapResult: Sendable {
    public var snappedOrigin: Point2D
    public var guides: [AlignmentGuide]
}

public final class AlignmentEngine {
    public static let snapThreshold: CGFloat = 8.0
    
    public static func snap(
        rect: CGRect,
        to otherRects: [CGRect],
        snapToGrid: Bool = true,
        gridSize: CGFloat = 24.0
    ) -> SnapResult {
        var snappedX = rect.origin.x
        var snappedY = rect.origin.y
        var guides: [AlignmentGuide] = []
        
        let targetLeft = rect.minX
        let targetCenterX = rect.midX
        let targetRight = rect.maxX
        
        let targetTop = rect.minY
        let targetCenterY = rect.midY
        let targetBottom = rect.maxY
        
        var minDiffX: CGFloat = snapThreshold
        var minDiffY: CGFloat = snapThreshold
        
        // 1. Object Snapping
        for other in otherRects {
            let otherLeft = other.minX
            let otherCenterX = other.midX
            let otherRight = other.maxX
            
            let otherTop = other.minY
            let otherCenterY = other.midY
            let otherBottom = other.maxY
            
            // X-axis comparisons
            let xPairs: [(CGFloat, CGFloat, CGFloat)] = [
                (targetLeft, otherLeft, 0),
                (targetLeft, otherRight, 0),
                (targetCenterX, otherCenterX, rect.width / 2.0),
                (targetRight, otherLeft, rect.width),
                (targetRight, otherRight, rect.width)
            ]
            
            for (tVal, oVal, offset) in xPairs {
                let diff = abs(tVal - oVal)
                if diff < minDiffX {
                    minDiffX = diff
                    snappedX = oVal - offset
                    guides.append(AlignmentGuide(
                        isVertical: true,
                        position: oVal,
                        start: min(rect.minY, other.minY) - 20,
                        end: max(rect.maxY, other.maxY) + 20
                    ))
                }
            }
            
            // Y-axis comparisons
            let yPairs: [(CGFloat, CGFloat, CGFloat)] = [
                (targetTop, otherTop, 0),
                (targetTop, otherBottom, 0),
                (targetCenterY, otherCenterY, rect.height / 2.0),
                (targetBottom, otherTop, rect.height),
                (targetBottom, otherBottom, rect.height)
            ]
            
            for (tVal, oVal, offset) in yPairs {
                let diff = abs(tVal - oVal)
                if diff < minDiffY {
                    minDiffY = diff
                    snappedY = oVal - offset
                    guides.append(AlignmentGuide(
                        isVertical: false,
                        position: oVal,
                        start: min(rect.minX, other.minX) - 20,
                        end: max(rect.maxX, other.maxX) + 20
                    ))
                }
            }
        }
        
        // 2. Grid Snapping fallback
        if snapToGrid {
            if minDiffX == snapThreshold {
                let gridX = round(snappedX / gridSize) * gridSize
                if abs(gridX - snappedX) < snapThreshold {
                    snappedX = gridX
                }
            }
            if minDiffY == snapThreshold {
                let gridY = round(snappedY / gridSize) * gridSize
                if abs(gridY - snappedY) < snapThreshold {
                    snappedY = gridY
                }
            }
        }
        
        return SnapResult(snappedOrigin: Point2D(x: Double(snappedX), y: Double(snappedY)), guides: guides)
    }
}
