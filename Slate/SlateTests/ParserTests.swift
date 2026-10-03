//
//  ParserTests.swift
//  SlateTests
//
//  Created for Slate Native Whiteboard.
//

import XCTest
@testable import Slate

final class ParserTests: XCTestCase {
    
    func testHeaderAndBulletsParsing() {
        let text = """
        # Architecture Overview
        - Metal canvas pipeline
        - AppKit input event handling
        - Zero ML computer vision
        """
        
        let parsed = TextGuideParser.parse(text: text)
        XCTAssertEqual(parsed.title, "Architecture Overview")
        XCTAssertEqual(parsed.elements.count, 4)
        
        if case .heading(let level, let t) = parsed.elements[0] {
            XCTAssertEqual(level, 1)
            XCTAssertEqual(t, "Architecture Overview")
        } else {
            XCTFail("First element should be heading")
        }
    }
    
    func testFlowTransitionsParsing() {
        let text = """
        User Input -> Background Queue -> Metal GPU Render
        """
        
        let parsed = TextGuideParser.parse(text: text)
        XCTAssertEqual(parsed.elements.count, 2)
        
        if case .flowTransition(let from, let to, _) = parsed.elements[0] {
            XCTAssertEqual(from, "User Input")
            XCTAssertEqual(to, "Background Queue")
        } else {
            XCTFail("Expected flow transition")
        }
    }
    
    func testComparisonParsing() {
        let text = """
        Native Swift vs Electron App
        """
        let parsed = TextGuideParser.parse(text: text)
        XCTAssertEqual(parsed.elements.count, 1)
        
        if case .comparison(let left, let right, _) = parsed.elements[0] {
            XCTAssertEqual(left, "Native Swift")
            XCTAssertEqual(right, "Electron App")
        } else {
            XCTFail("Expected comparison")
        }
    }
    
    func testTimelineEventParsing() {
        let text = """
        2026-10-03: Production release of Slate
        """
        let parsed = TextGuideParser.parse(text: text)
        XCTAssertEqual(parsed.elements.count, 1)
        
        if case .timelineEvent(let date, let title, _) = parsed.elements[0] {
            XCTAssertEqual(date, "2026-10-03")
            XCTAssertEqual(title, "Production release of Slate")
        } else {
            XCTFail("Expected timeline event")
        }
    }
}
