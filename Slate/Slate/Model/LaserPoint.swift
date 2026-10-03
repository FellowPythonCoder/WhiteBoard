//
//  LaserPoint.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

/// A single point in the transient laser pointer trail.
public struct LaserPoint: Equatable, Sendable {
    public var position: Point2D
    public var timestamp: TimeInterval
    public var color: ColorData
    public var initialRadius: Double
    
    public init(position: Point2D, timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime, color: ColorData = ColorData(red: 0.95, green: 0.2, blue: 0.2, alpha: 0.9), initialRadius: Double = 6.0) {
        self.position = position
        self.timestamp = timestamp
        self.color = color
        self.initialRadius = initialRadius
    }
    
    /// Calculate the remaining alpha multiplier given current time and lifetime.
    public func alpha(at currentTime: TimeInterval, lifetime: TimeInterval = 1.2) -> Double {
        let age = currentTime - timestamp
        guard age >= 0 && age < lifetime else { return 0.0 }
        let progress = age / lifetime
        return max(0.0, 1.0 - progress)
    }
}
