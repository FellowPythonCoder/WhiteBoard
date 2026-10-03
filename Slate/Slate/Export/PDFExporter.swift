//
//  PDFExporter.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

#if canImport(AppKit)
import AppKit

public final class PDFExporter {
    
    public static func renderPDF(document: SlateDocument, selectedOnlyIds: Set<UUID>? = nil) -> Data? {
        let exportBounds: CGRect
        let elementsToExport: [CanvasElement]
        
        if let sIds = selectedOnlyIds, !sIds.isEmpty {
            elementsToExport = document.elements.filter { sIds.contains($0.id) }
            exportBounds = document.selectionBounds(for: sIds) ?? CGRect(x: 0, y: 0, width: 800, height: 600)
        } else {
            elementsToExport = document.elements
            exportBounds = document.contentBounds
        }
        
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: exportBounds.width, height: exportBounds.height)
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }
        
        context.beginPage(mediaBox: &mediaBox)
        context.translateBy(x: -exportBounds.minX, y: -exportBounds.minY)
        
        // Background
        context.setFillColor(document.canvasBackground.cgColor)
        context.fill(exportBounds)
        
        // Draw elements in PDF vector context
        for el in elementsToExport {
            if case .stroke(let stroke) = el {
                guard stroke.points.count >= 2 else { continue }
                context.saveGState()
                context.setStrokeColor(stroke.color.cgColor)
                context.setLineWidth(CGFloat(stroke.width))
                context.setAlpha(CGFloat(stroke.opacity * (stroke.isHighlighter ? 0.35 : 1.0)))
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.move(to: stroke.points[0].cgPoint)
                for pt in stroke.points.dropFirst() {
                    context.addLine(to: pt.cgPoint)
                }
                context.strokePath()
                context.restoreGState()
            }
        }
        
        context.endPage()
        context.closePDF()
        return pdfData as Data
    }
}
#endif
