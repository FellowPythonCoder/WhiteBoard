//
//  GestureStateMachine.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public enum PenPointSelection: String, Codable, CaseIterable, Sendable {
    case topmost
    case midpoint
}

public final class GestureStateMachine: @unchecked Sendable {
    public var penPointMode: PenPointSelection = .topmost
    public var activeAreaRect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    public var isTestModeNoInk: Bool = false
    
    private var currentState: CameraGestureMode = .hover
    private var candidateState: CameraGestureMode = .hover
    private var candidateFrameCount: Int = 0
    private let hysteresisThreshold: Int = 3 // 3-frame hysteresis
    
    private let oneEuroX = OneEuroFilter(minCutoff: 1.5, beta: 0.007, dCutoff: 1.0)
    private let oneEuroY = OneEuroFilter(minCutoff: 1.5, beta: 0.007, dCutoff: 1.0)
    
    public init() {}
    
    public func reset() {
        currentState = .hover
        candidateState = .hover
        candidateFrameCount = 0
        oneEuroX.reset()
        oneEuroY.reset()
    }
    
    public func update(blobs: [CameraTrackedBlob], timestamp: TimeInterval) -> (mode: CameraGestureMode, position: CGPoint) {
        // Raw state evaluation based on blob count
        let rawState: CameraGestureMode
        if blobs.count >= 2 {
            rawState = .draw
        } else if blobs.count == 1 {
            rawState = .erase
        } else {
            rawState = .hover
        }
        
        // Hysteresis debouncing
        if rawState == candidateState {
            candidateFrameCount += 1
            if candidateFrameCount >= hysteresisThreshold && currentState != candidateState {
                currentState = candidateState
            }
        } else {
            candidateState = rawState
            candidateFrameCount = 1
        }
        
        // Compute raw position
        var rawPos = CGPoint(x: 0.5, y: 0.5)
        if blobs.count >= 2 {
            if penPointMode == .topmost {
                // Topmost blob has smallest Y (or highest on screen)
                let sorted = blobs.sorted { $0.centroid.y < $1.centroid.y }
                rawPos = sorted[0].centroid
            } else {
                // Midpoint of first two blobs
                rawPos = CGPoint(
                    x: (blobs[0].centroid.x + blobs[1].centroid.x) / 2.0,
                    y: (blobs[0].centroid.y + blobs[1].centroid.y) / 2.0
                )
            }
        } else if blobs.count == 1 {
            rawPos = blobs[0].centroid
        }
        
        // Mirror horizontally (webcam selfie perspective)
        let mirroredX = 1.0 - rawPos.x
        let rawMirrored = CGPoint(x: mirroredX, y: rawPos.y)
        
        // Map from activeAreaRect to (0.0 ... 1.0)
        let normalizedX = max(0.0, min(1.0, (rawMirrored.x - activeAreaRect.minX) / activeAreaRect.width))
        let normalizedY = max(0.0, min(1.0, (rawMirrored.y - activeAreaRect.minY) / activeAreaRect.height))
        
        // Smooth position with One Euro filter
        let smoothX = oneEuroX.filter(x: Double(normalizedX), timestamp: timestamp)
        let smoothY = oneEuroY.filter(x: Double(normalizedY), timestamp: timestamp)
        
        let finalPos = CGPoint(x: CGFloat(smoothX), y: CGFloat(smoothY))
        let effectiveMode = isTestModeNoInk ? .hover : currentState
        return (effectiveMode, finalPos)
    }
}
