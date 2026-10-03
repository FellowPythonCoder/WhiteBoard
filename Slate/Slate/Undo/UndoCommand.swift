//
//  UndoCommand.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public protocol CanvasCommand: Sendable {
    var name: String { get }
    func apply(to document: inout SlateDocument)
    func rollback(from document: inout SlateDocument)
}

public struct AddElementsCommand: CanvasCommand {
    public let name: String
    public let elements: [CanvasElement]
    
    public init(name: String = "Add Element", elements: [CanvasElement]) {
        self.name = name
        self.elements = elements
    }
    
    public func apply(to document: inout SlateDocument) {
        for el in elements {
            document.addElement(el)
        }
    }
    
    public func rollback(from document: inout SlateDocument) {
        let ids = Set(elements.map(\.id))
        document.removeElements(with: ids)
    }
}

public struct RemoveElementsCommand: CanvasCommand {
    public let name: String
    public let elements: [CanvasElement]
    
    public init(name: String = "Delete", elements: [CanvasElement]) {
        self.name = name
        self.elements = elements
    }
    
    public func apply(to document: inout SlateDocument) {
        let ids = Set(elements.map(\.id))
        document.removeElements(with: ids)
    }
    
    public func rollback(from document: inout SlateDocument) {
        for el in elements {
            document.addElement(el)
        }
    }
}

public struct ModifyElementsCommand: CanvasCommand {
    public let name: String
    public let oldElements: [CanvasElement]
    public let newElements: [CanvasElement]
    
    public init(name: String = "Modify", oldElements: [CanvasElement], newElements: [CanvasElement]) {
        self.name = name
        self.oldElements = oldElements
        self.newElements = newElements
    }
    
    public func apply(to document: inout SlateDocument) {
        for el in newElements {
            document.updateElement(el)
        }
    }
    
    public func rollback(from document: inout SlateDocument) {
        for el in oldElements {
            document.updateElement(el)
        }
    }
}

public struct TransformElementsCommand: CanvasCommand {
    public let name: String
    public let elementIds: [UUID]
    public let delta: CGPoint
    
    public init(name: String = "Move", elementIds: [UUID], delta: CGPoint) {
        self.name = name
        self.elementIds = elementIds
        self.delta = delta
    }
    
    public func apply(to document: inout SlateDocument) {
        let idSet = Set(elementIds)
        for i in 0..<document.elements.count {
            if idSet.contains(document.elements[i].id) {
                document.elements[i] = document.elements[i].translated(by: delta)
            }
        }
        document.updateCounts()
    }
    
    public func rollback(from document: inout SlateDocument) {
        let invDelta = CGPoint(x: -delta.x, y: -delta.y)
        let idSet = Set(elementIds)
        for i in 0..<document.elements.count {
            if idSet.contains(document.elements[i].id) {
                document.elements[i] = document.elements[i].translated(by: invDelta)
            }
        }
        document.updateCounts()
    }
}

public struct BatchCanvasCommand: CanvasCommand {
    public let name: String
    public let commands: [CanvasCommand]
    
    public init(name: String = "Batch Edit", commands: [CanvasCommand]) {
        self.name = name
        self.commands = commands
    }
    
    public func apply(to document: inout SlateDocument) {
        for cmd in commands {
            cmd.apply(to: &document)
        }
    }
    
    public func rollback(from document: inout SlateDocument) {
        for cmd in commands.reversed() {
            cmd.rollback(from: &document)
        }
    }
}
