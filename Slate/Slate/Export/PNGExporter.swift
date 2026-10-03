//
//  PNGExporter.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

#if canImport(AppKit)
import AppKit

public final class PNGExporter {
    
    public static func renderPNG(
        document: SlateDocument,
        selectedOnlyIds: Set<UUID>? = nil,
        scale: CGFloat = 2.0,
        transparentBackground: Bool = false
    ) -> Data? {
        let exportBounds: CGRect
        let elementsToExport: [CanvasElement]
        
        if let sIds = selectedOnlyIds, !sIds.isEmpty {
            elementsToExport = document.elements.filter { sIds.contains($0.id) }
            exportBounds = document.selectionBounds(for: sIds) ?? CGRect(x: 0, y: 0, width: 800, height: 600)
        } else {
            elementsToExport = document.elements
            exportBounds = document.contentBounds
        }
        
        let width = Int(max(100, exportBounds.width * scale))
        let height = Int(max(100, exportBounds.height * scale))
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }
        
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -exportBounds.minX, y: -exportBounds.minY)
        
        if !transparentBackground {
            context.setFillColor(document.canvasBackground.cgColor)
            context.fill(exportBounds)
        }
        
        // Draw strokes and vector elements
        for el in elementsToExport {
            switch el {
            case .stroke(let stroke):
                drawStroke(stroke, in: context)
            case .shape(let shape):
                drawShape(shape, in: context)
            case .text(let text):
                drawText(text, in: context)
            case .sticky(let sticky):
                drawSticky(sticky, in: context)
            case .connector(let conn):
                drawConnector(conn, in: context)
            case .frame(let frame):
                drawFrame(frame, in: context)
            case .image(let img):
                drawImage(img, in: context)
            }
        }
        
        guard let cgImg = context.makeImage() else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImg)
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    private static func drawStroke(_ stroke: Stroke, in ctx: CGContext) {
        guard stroke.points.count >= 2 else { return }
        ctx.saveGState()
        ctx.setStrokeColor(stroke.color.cgColor)
        ctx.setLineWidth(CGFloat(stroke.width))
        ctx.setAlpha(CGFloat(stroke.opacity * (stroke.isHighlighter ? 0.35 : 1.0)))
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        
        ctx.move(to: stroke.points[0].cgPoint)
        for pt in stroke.points.dropFirst() {
            ctx.addLine(to: pt.cgPoint)
        }
        ctx.strokePath()
        ctx.restoreGState()
    }
    
    private static func drawShape(_ shape: ShapeElement, in ctx: CGContext) {
        ctx.saveGState()
        let rect = CGRect(x: shape.origin.x, y: shape.origin.y, width: shape.size.width, height: shape.size.height)
        ctx.setStrokeColor(shape.strokeColor.cgColor)
        ctx.setFillColor(shape.fillColor.cgColor)
        ctx.setLineWidth(CGFloat(shape.strokeWidth))
        ctx.setAlpha(CGFloat(shape.opacity))
        
        switch shape.type {
        case .rectangle:
            let path = CGPath(roundedRect: rect, cornerWidth: CGFloat(shape.cornerRadius), cornerHeight: CGFloat(shape.cornerRadius), transform: nil)
            ctx.addPath(path)
            ctx.drawPath(using: .fillStroke)
        case .ellipse:
            ctx.addEllipse(in: rect)
            ctx.drawPath(using: .fillStroke)
        case .diamond:
            ctx.move(to: CGPoint(x: rect.midX, y: rect.minY))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            ctx.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            ctx.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            ctx.closePath()
            ctx.drawPath(using: .fillStroke)
        case .triangle:
            ctx.move(to: CGPoint(x: rect.midX, y: rect.minY))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            ctx.closePath()
            ctx.drawPath(using: .fillStroke)
        case .line, .arrow:
            let p1 = shape.startPoint?.cgPoint ?? rect.origin
            let p2 = shape.endPoint?.cgPoint ?? CGPoint(x: rect.maxX, y: rect.maxY)
            ctx.move(to: p1)
            ctx.addLine(to: p2)
            ctx.strokePath()
        }
        ctx.restoreGState()
    }
    
    private static func drawText(_ text: TextElement, in ctx: CGContext) {
        let font = NSFont.systemFont(ofSize: CGFloat(text.fontSize))
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: text.textColor.nsColor]
        let attrStr = NSAttributedString(string: text.text, attributes: attrs)
        attrStr.draw(in: CGRect(x: text.origin.x, y: text.origin.y, width: text.size.width, height: text.size.height))
    }
    
    private static func drawSticky(_ sticky: StickyNoteElement, in ctx: CGContext) {
        ctx.saveGState()
        let rect = CGRect(x: sticky.origin.x, y: sticky.origin.y, width: sticky.size.width, height: sticky.size.height)
        ctx.setFillColor(sticky.theme.backgroundColor.cgColor)
        let path = CGPath(roundedRect: rect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()
        
        let font = NSFont.systemFont(ofSize: CGFloat(sticky.fontSize), weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: sticky.theme.textColor.nsColor]
        let attrStr = NSAttributedString(string: sticky.text, attributes: attrs)
        attrStr.draw(in: rect.insetBy(dx: 12, dy: 12))
    }
    
    private static func drawConnector(_ conn: ConnectorElement, in ctx: CGContext) {
        let pts = conn.computePathPoints(startPt: conn.startAnchor.absolutePoint, endPt: conn.endAnchor.absolutePoint)
        guard pts.count >= 2 else { return }
        ctx.saveGState()
        ctx.setStrokeColor(conn.strokeColor.cgColor)
        ctx.setLineWidth(CGFloat(conn.strokeWidth))
        ctx.move(to: pts[0].cgPoint)
        for p in pts.dropFirst() {
            ctx.addLine(to: p.cgPoint)
        }
        ctx.strokePath()
        ctx.restoreGState()
    }
    
    private static func drawFrame(_ frame: FrameElement, in ctx: CGContext) {
        ctx.saveGState()
        let rect = frame.bounds
        ctx.setFillColor(frame.backgroundColor.cgColor)
        ctx.setStrokeColor(frame.strokeColor.cgColor)
        ctx.setLineWidth(1.0)
        let path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)
        ctx.addPath(path)
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()
    }
    
    private static func drawImage(_ img: ImageElement, in ctx: CGContext) {
        if let data = img.rawImageData ?? DocumentStore.shared.assetDataCache[img.assetId],
           let nsImg = NSImage(data: data) {
            ctx.saveGState()
            nsImg.draw(in: img.bounds)
            ctx.restoreGState()
        }
    }
}
#endif
