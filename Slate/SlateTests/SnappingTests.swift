//
//  SnappingTests.swift
//  SlateTests
//
//  Created for Slate Native Whiteboard.
//

import XCTest
@testable import Slate

final class SnappingTests: XCTestCase {
    
    func testStraightLineRecognition() {
        var points: [Point2D] = []
        for i in 0...20 {
            points.append(Point2D(x: Double(i * 10), y: 50.0))
        }
        let stroke = Stroke(points: points)
        let recognized = GeometrySnapper.recognize(stroke: stroke)
        
        XCTAssertNotNil(recognized)
        XCTAssertEqual(recognized?.shapeElement.type, .line)
    }
    
    func testCircleRecognition() {
        var points: [Point2D] = []
        let center = Point2D(x: 100, y: 100)
        let radius = 50.0
        let steps = 32
        
        for i in 0...steps {
            let theta = (Double(i) / Double(steps)) * Double.pi * 2.0
            points.append(Point2D(x: center.x + cos(theta) * radius, y: center.y + sin(theta) * radius))
        }
        
        let stroke = Stroke(points: points)
        let recognized = GeometrySnapper.recognize(stroke: stroke)
        
        XCTAssertNotNil(recognized)
        XCTAssertEqual(recognized?.shapeElement.type, .ellipse)
    }
}
