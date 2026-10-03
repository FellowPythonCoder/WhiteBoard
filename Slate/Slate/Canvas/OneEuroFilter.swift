//
//  OneEuroFilter.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation

/// 1€ Filter for low-latency adaptive jitter reduction and smoothing.
public final class OneEuroFilter: @unchecked Sendable {
    private var minCutoff: Double
    private var beta: Double
    private var dCutoff: Double
    
    private var xPrev: Double?
    private var dxPrev: Double = 0.0
    private var tPrev: TimeInterval?
    
    public init(minCutoff: Double = 1.0, beta: Double = 0.007, dCutoff: Double = 1.0) {
        self.minCutoff = minCutoff
        self.beta = beta
        self.dCutoff = dCutoff
    }
    
    public func reset() {
        xPrev = nil
        dxPrev = 0.0
        tPrev = nil
    }
    
    public func filter(x: Double, timestamp: TimeInterval) -> Double {
        guard let prev = xPrev, let tP = tPrev else {
            xPrev = x
            tPrev = timestamp
            return x
        }
        
        let dt = max(1e-4, timestamp - tP)
        let dx = (x - prev) / dt
        let edx = lowPassFilter(alpha: alpha(rate: 1.0 / dt, cutoff: dCutoff), x: dx, prev: dxPrev)
        dxPrev = edx
        
        let cutoff = minCutoff + beta * abs(edx)
        let a = alpha(rate: 1.0 / dt, cutoff: cutoff)
        let filtered = lowPassFilter(alpha: a, x: x, prev: prev)
        
        xPrev = filtered
        tPrev = timestamp
        return filtered
    }
    
    private func alpha(rate: Double, cutoff: Double) -> Double {
        let tau = 1.0 / (2.0 * Double.pi * cutoff)
        let te = 1.0 / rate
        return 1.0 / (1.0 + tau / te)
    }
    
    private func lowPassFilter(alpha: Double, x: Double, prev: Double) -> Double {
        return alpha * x + (1.0 - alpha) * prev
    }
}

public final class Point2DOneEuroFilter: @unchecked Sendable {
    private let filterX: OneEuroFilter
    private let filterY: OneEuroFilter
    private let filterPressure: OneEuroFilter
    
    public init(minCutoff: Double = 1.2, beta: Double = 0.005, dCutoff: Double = 1.0) {
        self.filterX = OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: dCutoff)
        self.filterY = OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: dCutoff)
        self.filterPressure = OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: dCutoff)
    }
    
    public func reset() {
        filterX.reset()
        filterY.reset()
        filterPressure.reset()
    }
    
    public func filter(point: Point2D) -> Point2D {
        let ts = point.timestamp > 0 ? point.timestamp : ProcessInfo.processInfo.systemUptime
        let nx = filterX.filter(x: point.x, timestamp: ts)
        let ny = filterY.filter(x: point.y, timestamp: ts)
        let np = filterPressure.filter(x: point.pressure, timestamp: ts)
        return Point2D(x: nx, y: ny, pressure: np, timestamp: ts)
    }
}
