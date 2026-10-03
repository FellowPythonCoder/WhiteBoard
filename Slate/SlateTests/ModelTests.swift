//
//  ModelTests.swift
//  SlateTests
//
//  Created for Slate Native Whiteboard.
//

import XCTest
@testable import Slate

final class ModelTests: XCTestCase {
    
    func testPoint2DDistanceAndMidpoint() {
        let p1 = Point2D(x: 0, y: 0)
        let p2 = Point2D(x: 3, y: 4)
        XCTAssertEqual(p1.distance(to: p2), 5.0, accuracy: 0.001)
        
        let mid = p1.midpoint(to: p2)
        XCTAssertEqual(mid.x, 1.5, accuracy: 0.001)
        XCTAssertEqual(mid.y, 2.0, accuracy: 0.001)
    }
    
    func testStrokeBoundingBox() {
        let pts = [Point2D(x: 10, y: 10), Point2D(x: 100, y: 50)]
        let stroke = Stroke(points: pts, width: 4.0)
        let bounds = stroke.bounds
        
        XCTAssertTrue(bounds.minX <= 10)
        XCTAssertTrue(bounds.maxX >= 100)
        XCTAssertTrue(bounds.minY <= 10)
        XCTAssertTrue(bounds.maxY >= 50)
    }
    
    func testStrokePixelSplit() {
        let pts = [
            Point2D(x: 0, y: 0),
            Point2D(x: 10, y: 0),
            Point2D(x: 20, y: 0),
            Point2D(x: 30, y: 0),
            Point2D(x: 40, y: 0),
            Point2D(x: 50, y: 0)
        ]
        let stroke = Stroke(points: pts, width: 2.0)
        let split = stroke.splitByEraser(eraserCenter: Point2D(x: 25, y: 0), eraserRadius: 10.0)
        
        XCTAssertEqual(split.count, 2)
        XCTAssertEqual(split[0].points.count, 2) // 0, 10
        XCTAssertEqual(split[1].points.count, 2) // 40, 50
    }
    
    func testDocumentJSONSerialization() throws {
        var doc = SlateDocument()
        doc.metadata.title = "Test Board"
        
        let stroke = Stroke(points: [Point2D(x: 10, y: 10), Point2D(x: 20, y: 20)], color: .cobalt)
        doc.addElement(.stroke(stroke))
        
        let shape = ShapeElement(type: .rectangle, origin: Point2D(x: 50, y: 50), size: CGSize(width: 100, height: 60))
        doc.addElement(.shape(shape))
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(doc)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SlateDocument.self, from: data)
        
        XCTAssertEqual(decoded.metadata.title, "Test Board")
        XCTAssertEqual(decoded.elements.count, 2)
        XCTAssertEqual(decoded.metadata.strokeCount, 1)
        XCTAssertEqual(decoded.metadata.elementCount, 2)
    }
}
