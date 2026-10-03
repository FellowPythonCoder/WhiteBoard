//
//  CameraTrackingProtocol.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public enum CameraGestureMode: String, Sendable {
    case hover = "Hover (Pen Up)"
    case draw = "Drawing"
    case erase = "Erasing"
    
    public var iconName: String {
        switch self {
        case .hover: return "hand.point.up.left"
        case .draw: return "pencil.tip"
        case .erase: return "eraser"
        }
    }
}

public struct CameraTrackedBlob: Sendable {
    public var centroid: CGPoint // Normalized (0.0 ... 1.0)
    public var pixelArea: Int
    public var boundingBox: CGRect
}

public struct CameraFrameTrackingResult: Sendable {
    public var gestureMode: CameraGestureMode
    public var fingertipPosition: CGPoint // Mapped to normalized active area (0.0 ... 1.0)
    public var rawBlobs: [CameraTrackedBlob]
    public var timestamp: TimeInterval
}

public protocol CameraTrackingService: AnyObject, Sendable {
    var isTrackingEnabled: Bool { get }
    var currentGestureMode: CameraGestureMode { get }
    func startTracking()
    func stopTracking()
    func processFrame(rgbBuffer: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int, timestamp: TimeInterval) -> CameraFrameTrackingResult
}
