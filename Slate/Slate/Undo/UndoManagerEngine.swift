//
//  UndoManagerEngine.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import Combine

/// Unlimited undo/redo stack using the Command pattern.
@MainActor
public final class UndoManagerEngine: ObservableObject {
    @Published public private(set) var canUndo: Bool = false
    @Published public private(set) var canRedo: Bool = false
    @Published public private(set) var undoActionName: String = ""
    @Published public private(set) var redoActionName: String = ""
    
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []
    
    public init() {}
    
    public func execute(_ command: CanvasCommand, on document: inout SlateDocument) {
        command.apply(to: &document)
        undoStack.append(command)
        redoStack.removeAll()
        updateState()
    }
    
    public func undo(on document: inout SlateDocument) {
        guard let command = undoStack.popLast() else { return }
        command.rollback(from: &document)
        redoStack.append(command)
        updateState()
    }
    
    public func redo(on document: inout SlateDocument) {
        guard let command = redoStack.popLast() else { return }
        command.apply(to: &document)
        undoStack.append(command)
        updateState()
    }
    
    public func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateState()
    }
    
    private func updateState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
        undoActionName = undoStack.last?.name ?? ""
        redoActionName = redoStack.last?.name ?? ""
    }
}
