//
//  SVGExporter.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public final class SVGExporter {
    
    public static func renderSVG(
        document: SlateDocument,
        selectedOnlyIds: Set<UUID>? = nil,
        transparentBackground: Bool = false
    ) -> String {
        let exportBounds: CGRect
        let elementsToExport: [CanvasElement]
        
        if let sIds = selectedOnlyIds, !sIds.isEmpty {
            elementsToExport = document.elements.filter { sIds.contains($0.id) }
            exportBounds = document.selectionBounds(for: sIds) ?? CGRect(x: 0, y: 0, width: 800, height: 600)
        } else {
            elementsToExport = document.elements
            exportBounds = document.contentBounds
        }
        
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="\(exportBounds.minX) \(exportBounds.minY) \(exportBounds.width) \(exportBounds.height)" width="\(exportBounds.width)" height="\(exportBounds.height)">
        """
        
        if !transparentBackground {
            svg += "\n  <rect x=\"\(exportBounds.minX)\" y=\"\(exportBounds.minY)\" width=\"\(exportBounds.width)\" height=\"\(exportBounds.height)\" fill=\"\(document.canvasBackground.hexString)\" />"
        }
        
        for el in elementsToExport {
            switch el {
            case .stroke(let stroke):
                guard stroke.points.count >= 2 else { continue }
                var pathStr = "M \(stroke.points[0].x) \(stroke.points[0].y)"
                for pt in stroke.points.dropFirst() {
                    pathStr += " L \(pt.x) \(pt.y)"
                }
                let opacity = stroke.opacity * (stroke.isHighlighter ? 0.35 : 1.0)
                svg += "\n  <path d=\"\(pathStr)\" fill=\"none\" stroke=\"\(stroke.color.hexString)\" stroke-width=\"\(stroke.width)\" stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-opacity=\"\(opacity)\" />"
                
            case .shape(let shape):
                let strokeHex = shape.strokeColor.hexString
                let fillHex = shape.fillColor.alpha > 0 ? shape.fillColor.hexString : "none"
                switch shape.type {
                case .rectangle:
                    svg += "\n  <rect x=\"\(shape.origin.x)\" y=\"\(shape.origin.y)\" width=\"\(shape.size.width)\" height=\"\(shape.size.height)\" rx=\"\(shape.cornerRadius)\" fill=\"\(fillHex)\" stroke=\"\(strokeHex)\" stroke-width=\"\(shape.strokeWidth)\" opacity=\"\(shape.opacity)\" />"
                case .ellipse:
                    let cx = shape.origin.x + shape.size.width / 2.0
                    let cy = shape.origin.y + shape.size.height / 2.0
                    svg += "\n  <ellipse cx=\"\(cx)\" cy=\"\(cy)\" rx=\"\(shape.size.width / 2.0)\" ry=\"\(shape.size.height / 2.0)\" fill=\"\(fillHex)\" stroke=\"\(strokeHex)\" stroke-width=\"\(shape.strokeWidth)\" opacity=\"\(shape.opacity)\" />"
                default:
                    break
                }
                
            case .text(let text):
                svg += "\n  <text x=\"\(text.origin.x)\" y=\"\(text.origin.y + text.fontSize)\" font-family=\"\(text.fontFamily)\" font-size=\"\(text.fontSize)\" fill=\"\(text.textColor.hexString)\">\(escapeXML(text.text))</text>"
                
            case .sticky(let sticky):
                svg += "\n  <rect x=\"\(sticky.origin.x)\" y=\"\(sticky.origin.y)\" width=\"\(sticky.size.width)\" height=\"\(sticky.size.height)\" rx=\"6\" fill=\"\(sticky.theme.backgroundColor.hexString)\" />"
                svg += "\n  <text x=\"\(sticky.origin.x + 12)\" y=\"\(sticky.origin.y + sticky.fontSize + 12)\" font-size=\"\(sticky.fontSize)\" fill=\"\(sticky.theme.textColor.hexString)\">\(escapeXML(sticky.text))</text>"
                
            default:
                break
            }
        }
        
        svg += "\n</svg>\n"
        return svg
    }
    
    private static func escapeXML(_ str: String) -> String {
        str.replacingOccurrences(of: "&", with: "&amp;")
           .replacingOccurrences(of: "<", with: "&lt;")
           .replacingOccurrences(of: ">", with: "&gt;")
           .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
