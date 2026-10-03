//
//  StrokeTessellator.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics
import simd

public struct StrokeVertex {
    public var position: SIMD2<Float>
    public var color: SIMD4<Float>
    public var uv: SIMD2<Float> // u: progression, v: distance (-1 to 1)
    
    public init(position: SIMD2<Float>, color: SIMD4<Float>, uv: SIMD2<Float>) {
        self.position = position
        self.color = color
        self.uv = uv
    }
}

public final class StrokeTessellator {
    
    /// Tessellates a stroke into triangle strip vertices using normal extrusions and smoothing.
    public static func tessellate(stroke: Stroke, smoothingSteps: Int = 4) -> [StrokeVertex] {
        guard stroke.points.count >= 2 else {
            if let single = stroke.points.first {
                return tessellateDot(point: single, width: Float(stroke.width), color: stroke.color, opacity: Float(stroke.opacity))
            }
            return []
        }
        
        let smoothedPoints = smoothPoints(stroke.points, steps: smoothingSteps)
        guard smoothedPoints.count >= 2 else { return [] }
        
        var vertices: [StrokeVertex] = []
        vertices.reserveCapacity(smoothedPoints.count * 6)
        
        let colorVec = SIMD4<Float>(
            Float(stroke.color.red),
            Float(stroke.color.green),
            Float(stroke.color.blue),
            Float(stroke.color.alpha * stroke.opacity)
        )
        
        let baseRadius = Float(stroke.width / 2.0)
        let count = smoothedPoints.count
        
        for i in 0..<count {
            let curr = smoothedPoints[i]
            let pCurr = curr.simdFloat2
            let rCurr = max(0.5, baseRadius * Float(curr.pressure))
            
            // Calculate normal vector
            var tangent: SIMD2<Float>
            if i == 0 {
                tangent = smoothedPoints[1].simdFloat2 - pCurr
            } else if i == count - 1 {
                tangent = pCurr - smoothedPoints[i - 1].simdFloat2
            } else {
                let t1 = normalize(pCurr - smoothedPoints[i - 1].simdFloat2)
                let t2 = normalize(smoothedPoints[i + 1].simdFloat2 - pCurr)
                tangent = t1 + t2
            }
            
            let len = length(tangent)
            let normal: SIMD2<Float>
            if len > 0.0001 {
                let normTangent = tangent / len
                normal = SIMD2<Float>(-normTangent.y, normTangent.x)
            } else {
                normal = SIMD2<Float>(0, 1)
            }
            
            let leftPos = pCurr + normal * rCurr
            let rightPos = pCurr - normal * rCurr
            let progress = Float(i) / Float(count - 1)
            
            if i > 0 && !vertices.isEmpty {
                // Add two triangles (6 vertices) forming the quad between i-1 and i
                let lastLeft = vertices[vertices.count - 2]
                let lastRight = vertices[vertices.count - 1]
                
                let curLeft = StrokeVertex(position: leftPos, color: colorVec, uv: SIMD2<Float>(progress, -1.0))
                let curRight = StrokeVertex(position: rightPos, color: colorVec, uv: SIMD2<Float>(progress, 1.0))
                
                // Triangle 1: lastLeft, lastRight, curLeft
                vertices.append(lastLeft)
                vertices.append(lastRight)
                vertices.append(curLeft)
                
                // Triangle 2: lastRight, curRight, curLeft
                vertices.append(lastRight)
                vertices.append(curRight)
                vertices.append(curLeft)
            } else {
                // Initial edge
                vertices.append(StrokeVertex(position: leftPos, color: colorVec, uv: SIMD2<Float>(0, -1.0)))
                vertices.append(StrokeVertex(position: rightPos, color: colorVec, uv: SIMD2<Float>(0, 1.0)))
            }
        }
        
        return vertices
    }
    
    private static func tessellateDot(point: Point2D, width: Float, color: ColorData, opacity: Float) -> [StrokeVertex] {
        let center = point.simdFloat2
        let radius = max(1.0, width * Float(point.pressure) / 2.0)
        let segments = 16
        var vertices: [StrokeVertex] = []
        
        let colorVec = SIMD4<Float>(
            Float(color.red),
            Float(color.green),
            Float(color.blue),
            Float(color.alpha * Double(opacity))
        )
        
        for i in 0..<segments {
            let theta1 = (Float(i) / Float(segments)) * Float.pi * 2.0
            let theta2 = (Float(i + 1) / Float(segments)) * Float.pi * 2.0
            
            let p1 = center + SIMD2<Float>(cos(theta1), sin(theta1)) * radius
            let p2 = center + SIMD2<Float>(cos(theta2), sin(theta2)) * radius
            
            vertices.append(StrokeVertex(position: center, color: colorVec, uv: SIMD2<Float>(0, 0)))
            vertices.append(StrokeVertex(position: p1, color: colorVec, uv: SIMD2<Float>(0, 1.0)))
            vertices.append(StrokeVertex(position: p2, color: colorVec, uv: SIMD2<Float>(0, 1.0)))
        }
        return vertices
    }
    
    /// Catmull-Rom spline smoothing
    private static func smoothPoints(_ points: [Point2D], steps: Int = 4) -> [Point2D] {
        guard points.count >= 3 && steps > 1 else { return points }
        
        var result: [Point2D] = []
        result.reserveCapacity(points.count * steps)
        
        for i in 0..<(points.count - 1) {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = (i + 2 < points.count) ? points[i + 2] : p2
            
            for s in 0..<steps {
                let t = Double(s) / Double(steps)
                let t2 = t * t
                let t3 = t2 * t
                
                let x = 0.5 * ((2.0 * p1.x) +
                              (-p0.x + p2.x) * t +
                              (2.0 * p0.x - 5.0 * p1.x + 4.0 * p2.x - p3.x) * t2 +
                              (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3)
                
                let y = 0.5 * ((2.0 * p1.y) +
                              (-p0.y + p2.y) * t +
                              (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 +
                              (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3)
                
                let pr = p1.pressure + (p2.pressure - p1.pressure) * t
                let ts = p1.timestamp + (p2.timestamp - p1.timestamp) * t
                
                result.append(Point2D(x: x, y: y, pressure: pr, timestamp: ts))
            }
        }
        
        if let last = points.last {
            result.append(last)
        }
        
        return result
    }
}
