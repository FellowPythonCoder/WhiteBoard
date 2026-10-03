//
//  MenuCommands.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public struct SlateMenuCommands: Commands {
    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Board") {
                _ = DocumentStore.shared.createNewBoard()
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("Open Board Library...") {
                // Handled via state notification
            }
            .keyboardShortcut("o", modifiers: .command)
            
            Divider()
            
            Button("Save Checkpoint") {
                if var doc = DocumentStore.shared.activeDocument {
                    doc.createSnapshot(label: "Manual Checkpoint")
                    DocumentStore.shared.updateActiveDocument(doc, saveImmediately: true)
                }
            }
            .keyboardShortcut("s", modifiers: .command)
        }
        
        CommandMenu("Tools") {
            ForEach(CanvasTool.allCases) { tool in
                Button(tool.rawValue) {
                    // Set active tool
                }
                .keyboardShortcut(KeyEquivalent(tool.shortcutKey ?? "v"), modifiers: [])
            }
        }
        
        CommandMenu("View") {
            Button("Zoom to Fit") {
                // Fit canvas
            }
            .keyboardShortcut("0", modifiers: .command)
            
            Button("Zoom to 100%") {
                // Reset zoom
            }
            .keyboardShortcut("1", modifiers: .command)
            
            Button("Toggle Rulers") {
                if var doc = DocumentStore.shared.activeDocument {
                    doc.showRulers.toggle()
                    DocumentStore.shared.updateActiveDocument(doc)
                }
            }
            .keyboardShortcut("r", modifiers: .command)
            
            Button("Toggle Minimap") {
                if var doc = DocumentStore.shared.activeDocument {
                    doc.showMinimap.toggle()
                    DocumentStore.shared.updateActiveDocument(doc)
                }
            }
            .keyboardShortcut("m", modifiers: .command)
        }
        
        CommandMenu("Camera") {
            Button("Toggle Finger Tracking") {
                if CameraManager.shared.isTrackingEnabled {
                    CameraManager.shared.stopTracking()
                } else {
                    CameraManager.shared.startTracking()
                }
            }
            .keyboardShortcut("c", modifiers: .option)
        }
    }
}
