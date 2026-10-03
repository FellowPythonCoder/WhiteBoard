//
//  ClipboardManager.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

#if canImport(AppKit)
import AppKit

public final class ClipboardManager {
    
    public static func copySelection(document: SlateDocument, selectedIds: Set<UUID>) {
        guard !selectedIds.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // 1. Copy as PNG Image
        if let pngData = PNGExporter.renderPNG(document: document, selectedOnlyIds: selectedIds, scale: 2.0, transparentBackground: true) {
            pasteboard.setData(pngData, forType: .png)
        }
        
        // 2. Copy as SVG String
        let svgString = SVGExporter.renderSVG(document: document, selectedOnlyIds: selectedIds, transparentBackground: true)
        pasteboard.setString(svgString, forType: .string)
    }
}
#endif
