//
//  Point2D.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics
import simd

/// A lightweight, high-performance 2D point value with optional pressure, tilt, and timestamp.
public struct Point2D: Codable, Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var pressure: Double
    public var timestamp: TimeInterval
    
    public init(x: Double, y: Double, pressure: Double = 1.0, timestamp: TimeInterval = 0) {
        self.x = x
        self.y = y
        self.pressure = max(0.0, min(1.0, pressure))
        self.timestamp = timestamp
    }
    
    public init(_ cgPoint: CGPoint, pressure: Double = 1.0, timestamp: TimeInterval = 0) {
        self.x = Double(cgPoint.x)
        self.y = Double(cgPoint.y)
        self.pressure = max(0.0, min(1.0, pressure))
        self.timestamp = timestamp
    }
    
    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
    
    public var simdFloat2: SIMD2<Float> {
        SIMD2<Float>(Float(x), Float(y))
    }
    
    public func distance(to other: Point2D) -> Double {
        let dx = other.x - x
        let dy = other.y - y
        return (dx * dx + dy * dy).squareRoot()
    }
    
    public func midpoint(to other: Point2D) -> Point2D {
        Point2D(
            x: (x + other.x) / 2.0,
            y: (y + other.y) / 2.0,
            pressure: (pressure + other.pressure) / 2.0,
            timestamp: (timestamp + other.timestamp) / 2.0
        )
    }
    
    public func translated(by delta: CGPoint) -> Point2D {
        Point2D(x: x + Double(delta.x), y: y + Double(delta.y), pressure: pressure, timestamp: timestamp)
    }
    
    public func rotated(around center: Point2D, by angleRadians: Double) -> Point2D {
        let cosA = cos(angleRadians)
        let sinA = sin(angleRadians)
        let dx = x - center.x
        let dy = y - center.y
        let nx = center.x + (dx * cosA - dy * sinA)
        let ny = center.y + (dx * sinA + dy * cosA)
        return Point2D(x: nx, y: ny, pressure: pressure, timestamp: timestamp)
    }
}
