//
//  GestureStateMachineTests.swift
//  SlateTests
//
//  Created for Slate Native Whiteboard.
//

import XCTest
@testable import Slate

final class GestureStateMachineTests: XCTestCase {
    
    func testTwoBlobsTriggerDrawStateWithHysteresis() {
        let sm = GestureStateMachine()
        let b1 = CameraTrackedBlob(centroid: CGPoint(x: 0.3, y: 0.4), pixelArea: 50, boundingBox: .zero)
        let b2 = CameraTrackedBlob(centroid: CGPoint(x: 0.32, y: 0.42), pixelArea: 60, boundingBox: .zero)
        let twoBlobs = [b1, b2]
        
        // Frame 1: candidate is draw, current remains hover (hysteresis = 3)
        let r1 = sm.update(blobs: twoBlobs, timestamp: 1.0)
        XCTAssertEqual(r1.mode, .hover)
        
        // Frame 2: candidate count = 2
        let r2 = sm.update(blobs: twoBlobs, timestamp: 1.033)
        XCTAssertEqual(r2.mode, .hover)
        
        // Frame 3: hysteresis threshold reached -> transitions to DRAW
        let r3 = sm.update(blobs: twoBlobs, timestamp: 1.066)
        XCTAssertEqual(r3.mode, .draw)
    }
    
    func testSingleBlobTriggersEraseState() {
        let sm = GestureStateMachine()
        let b1 = CameraTrackedBlob(centroid: CGPoint(x: 0.5, y: 0.5), pixelArea: 100, boundingBox: .zero)
        
        _ = sm.update(blobs: [b1], timestamp: 1.0)
        _ = sm.update(blobs: [b1], timestamp: 1.033)
        let r3 = sm.update(blobs: [b1], timestamp: 1.066)
        
        XCTAssertEqual(r3.mode, .erase)
    }
    
    func testZeroBlobsTriggersHoverState() {
        let sm = GestureStateMachine()
        _ = sm.update(blobs: [], timestamp: 1.0)
        _ = sm.update(blobs: [], timestamp: 1.033)
        let r3 = sm.update(blobs: [], timestamp: 1.066)
        
        XCTAssertEqual(r3.mode, .hover)
    }
}
