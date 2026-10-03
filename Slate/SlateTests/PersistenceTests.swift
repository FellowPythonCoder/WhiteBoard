//
//  PersistenceTests.swift
//  SlateTests
//
//  Created for Slate Native Whiteboard.
//

import XCTest
@testable import Slate

final class PersistenceTests: XCTestCase {
    
    func testPackageSaveAndLoad() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let packageURL = tempDir.appendingPathComponent("TestBoard.slate")
        
        var originalDoc = SlateDocument()
        originalDoc.metadata.title = "Package Unit Test"
        let sticky = StickyNoteElement(text: "Hello Slate", theme: .yellow)
        originalDoc.addElement(.sticky(sticky))
        
        let dummyPNG = Data([0x89, 0x50, 0x4E, 0x47])
        try SlatePackage.save(document: originalDoc, to: packageURL, thumbnailPNG: dummyPNG)
        
        // Load back
        let (loadedDoc, _, thumbData) = try SlatePackage.load(from: packageURL)
        XCTAssertEqual(loadedDoc.metadata.title, "Package Unit Test")
        XCTAssertEqual(loadedDoc.elements.count, 1)
        XCTAssertNotNil(thumbData)
        
        // Metadata only read
        let meta = SlatePackage.readMetadata(from: packageURL)
        XCTAssertEqual(meta?.title, "Package Unit Test")
    }
}
