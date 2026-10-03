//
//  KeyboardCheatSheetModal.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public struct KeyboardCheatSheetModal: View {
    public var onClose: () -> Void
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    private let toolShortcuts: [(key: String, desc: String)] = [
        ("V", "Select / Move"),
        ("P", "Pen (Pressure sensitive)"),
        ("H", "Highlighter"),
        ("E", "Stroke Eraser"),
        ("X", "Pixel Partial Eraser"),
        ("T", "Text Element"),
        ("R", "Rectangle"),
        ("O", "Ellipse / Circle"),
        ("L", "Line"),
        ("A", "Arrow"),
        ("D", "Diamond"),
        ("G", "Triangle"),
        ("S", "Sticky Note"),
        ("C", "Smart Connector"),
        ("K", "Laser Pointer"),
        ("F", "Frame / Slide"),
        ("Q", "Lasso Select"),
        ("Y", "Eyedropper"),
        ("Space", "Hand / Pan Canvas")
    ]
    
    private let actionShortcuts: [(key: String, desc: String)] = [
        ("⌘K", "Command Palette"),
        ("⌘Z", "Undo"),
        ("⇧⌘Z", "Redo"),
        ("⌘C / ⌘V", "Copy / Paste"),
        ("⌘D", "Duplicate"),
        ("⌘G / ⇧⌘G", "Group / Ungroup"),
        ("⌘L", "Lock / Unlock"),
        ("⌘R", "Toggle Rulers"),
        ("⌘0", "Zoom to Fit"),
        ("⌘1", "Zoom to 100%"),
        ("⌘2", "Zoom to Selection"),
        ("⌥C", "Toggle Camera Tracking"),
        ("⌃⌘F", "Full Screen / Presentation")
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Keyboard Shortcuts", systemImage: "command")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            HStack(alignment: .top, spacing: 20) {
                // Column 1: Tools
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOOLS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    ForEach(toolShortcuts, id: \.key) { item in
                        HStack {
                            Text(item.desc)
                                .font(.system(size: 12))
                            Spacer()
                            Text(item.key)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Column 2: Commands & Actions
                VStack(alignment: .leading, spacing: 8) {
                    Text("ACTIONS & NAVIGATION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    ForEach(actionShortcuts, id: \.key) { item in
                        HStack {
                            Text(item.desc)
                                .font(.system(size: 12))
                            Spacer()
                            Text(item.key)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .frame(width: 520, height: 460)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}
