//
//  SlateCanvasNSView.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

#if canImport(AppKit)
import AppKit
import Combine

public final class SlateCanvasNSView: NSView, NSDraggingDestination {
    public var metalView: MetalCanvasView!
    public var transform: CanvasCoordinateTransform = CanvasCoordinateTransform()
    
    public var onDocumentChanged: ((SlateDocument) -> Void)?
    public var onSelectionChanged: ((Set<UUID>) -> Void)?
    public var onColorSampled: ((ColorData) -> Void)?
    
    public var selectedElementIDs: Set<UUID> = []
    public var activeTool: CanvasTool = .pen
    public var currentStrokeColor: ColorData = .ink
    public var currentFillColor: ColorData = .clear
    public var currentStrokeWidth: Double = 3.0
    public var currentOpacity: Double = 1.0
    public var currentSmoothing: Double = 0.5
    public var isDarkMode: Bool = false
    
    private let inputHandler = CanvasInputHandler()
    private var trackingArea: NSTrackingArea?
    private var activeLaserTimer: Timer?
    private var laserPoints: [LaserPoint] = []
    private var isSpacePanning: Bool = false
    private var lastPanLocation: NSPoint = .zero
    private var marqueeRect: CGRect?
    private var alignmentGuides: [AlignmentGuide] = []
    
    public var document: SlateDocument = SlateDocument() {
        didSet {
            metalView?.renderer?.document = document
            metalView?.renderer?.isDarkMode = isDarkMode
            transform.offset = CGPoint(x: CGFloat(document.viewportOffset.x), y: CGFloat(document.viewportOffset.y))
            transform.zoom = CGFloat(document.viewportZoom)
            needsDisplay = true
        }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupCanvas()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCanvas()
    }
    
    private func setupCanvas() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        
        metalView = MetalCanvasView(frame: bounds, device: nil)
        metalView.autoresizingMask = [.width, .height]
        addSubview(metalView)
        
        registerForDraggedTypes([.fileURL, .png, .tiff, .string])
    }
    
    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea { removeTrackingArea(existing) }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }
    
    // MARK: - Gestures (Pinch to zoom & Two-finger Pan)
    
    override public func magnify(with event: NSEvent) {
        let mouseLoc = convert(event.locationInWindow, from: nil)
        let canvasPtBefore = transform.canvasPoint(from: mouseLoc)
        
        let newZoom = max(0.1, min(10.0, transform.zoom * (1.0 + event.magnification)))
        transform.zoom = newZoom
        
        let canvasPtAfter = transform.canvasPoint(from: mouseLoc)
        transform.offset.x += CGFloat(canvasPtAfter.x - canvasPtBefore.x)
        transform.offset.y += CGFloat(canvasPtAfter.y - canvasPtBefore.y)
        
        document.viewportZoom = Double(transform.zoom)
        document.viewportOffset = Point2D(x: Double(transform.offset.x), y: Double(transform.offset.y))
        
        metalView?.renderer?.document = document
        needsDisplay = true
    }
    
    override public func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            // Pinch / zoom via scroll
            let factor = 1.0 + (event.scrollingDeltaY * 0.01)
            let newZoom = max(0.1, min(10.0, transform.zoom * factor))
            transform.zoom = newZoom
        } else {
            // Pan
            let dx = event.scrollingDeltaX / transform.zoom
            let dy = event.scrollingDeltaY / transform.zoom
            transform.offset.x += dx
            transform.offset.y += dy
        }
        
        document.viewportZoom = Double(transform.zoom)
        document.viewportOffset = Point2D(x: Double(transform.offset.x), y: Double(transform.offset.y))
        
        metalView?.renderer?.document = document
        needsDisplay = true
    }
    
    // MARK: - Mouse & Tablet Events
    
    override public func mouseDown(with event: NSEvent) {
        let viewLoc = convert(event.locationInWindow, from: nil)
        let canvasPt = transform.canvasPoint(from: viewLoc)
        let pressure = Double(event.pressure > 0 ? event.pressure : 1.0)
        let pt = Point2D(x: canvasPt.x, y: canvasPt.y, pressure: pressure, timestamp: event.timestamp)
        
        if isSpacePanning || activeTool == .hand {
            lastPanLocation = viewLoc
            return
        }
        
        switch activeTool {
        case .pen, .highlighter:
            inputHandler.startStroke(point: pt)
            let s = Stroke(
                points: [pt],
                color: currentStrokeColor,
                width: currentStrokeWidth,
                opacity: currentOpacity,
                isHighlighter: activeTool == .highlighter
            )
            metalView?.renderer?.liveStroke = s
            
        case .strokeEraser:
            eraseAt(point: pt, strokeOnly: true)
            
        case .pixelEraser:
            eraseAt(point: pt, strokeOnly: false)
            
        case .laser:
            addLaserPoint(pt)
            
        case .select:
            handleSelectionMouseDown(at: pt, shiftKey: event.modifierFlags.contains(.shift))
            
        case .lasso:
            inputHandler.startStroke(point: pt, enableHoldToSnap: false)
            
        case .rectangle, .ellipse, .line, .arrow, .diamond, .triangle:
            inputHandler.dragStartPoint = pt
            
        case .text:
            createTextElement(at: pt)
            
        case .sticky:
            createStickyNote(at: pt)
            
        case .frame:
            inputHandler.dragStartPoint = pt
            
        case .eyedropper:
            sampleColorAt(point: pt)
            
        default:
            break
        }
        needsDisplay = true
    }
    
    override public func mouseDragged(with event: NSEvent) {
        let viewLoc = convert(event.locationInWindow, from: nil)
        let canvasPt = transform.canvasPoint(from: viewLoc)
        let pressure = Double(event.pressure > 0 ? event.pressure : 1.0)
        let pt = Point2D(x: canvasPt.x, y: canvasPt.y, pressure: pressure, timestamp: event.timestamp)
        let shiftKey = event.modifierFlags.contains(.shift)
        
        if isSpacePanning || activeTool == .hand {
            let dx = (viewLoc.x - lastPanLocation.x) / transform.zoom
            let dy = (viewLoc.y - lastPanLocation.y) / transform.zoom
            transform.offset.x += dx
            transform.offset.y += dy
            lastPanLocation = viewLoc
            document.viewportOffset = Point2D(x: Double(transform.offset.x), y: Double(transform.offset.y))
            metalView?.renderer?.document = document
            needsDisplay = true
            return
        }
        
        switch activeTool {
        case .pen, .highlighter:
            inputHandler.continueStroke(point: pt, straightLineWithShift: shiftKey)
            var s = Stroke(
                points: inputHandler.currentPoints,
                color: currentStrokeColor,
                width: currentStrokeWidth,
                opacity: currentOpacity,
                isHighlighter: activeTool == .highlighter
            )
            metalView?.renderer?.liveStroke = s
            
        case .strokeEraser:
            eraseAt(point: pt, strokeOnly: true)
            
        case .pixelEraser:
            eraseAt(point: pt, strokeOnly: false)
            
        case .laser:
            addLaserPoint(pt)
            
        case .select:
            if let start = inputHandler.dragStartPoint {
                // Drag move or marquee
                if !selectedElementIDs.isEmpty {
                    let delta = CGPoint(x: pt.x - start.x, y: pt.y - start.y)
                    moveSelectedElements(by: delta)
                    inputHandler.dragStartPoint = pt
                } else {
                    let minX = min(start.x, pt.x)
                    let minY = min(start.y, pt.y)
                    let w = abs(pt.x - start.x)
                    let h = abs(pt.y - start.y)
                    marqueeRect = CGRect(x: minX, y: minY, width: w, height: h)
                }
            }
            
        case .lasso:
            inputHandler.continueStroke(point: pt, straightLineWithShift: false)
            
        case .rectangle, .ellipse, .line, .arrow, .diamond, .triangle, .frame:
            break
            
        default:
            break
        }
        needsDisplay = true
    }
    
    override public func mouseUp(with event: NSEvent) {
        let viewLoc = convert(event.locationInWindow, from: nil)
        let canvasPt = transform.canvasPoint(from: viewLoc)
        let pt = Point2D(x: canvasPt.x, y: canvasPt.y, pressure: 1.0, timestamp: event.timestamp)
        
        if isSpacePanning || activeTool == .hand {
            return
        }
        
        switch activeTool {
        case .pen, .highlighter:
            let points = inputHandler.endStroke()
            metalView?.renderer?.liveStroke = nil
            
            if inputHandler.isHolding && activeTool == .pen {
                let stroke = Stroke(points: points, color: currentStrokeColor, width: currentStrokeWidth, opacity: currentOpacity)
                if let snapped = GeometrySnapper.recognize(stroke: stroke) {
                    document.addElement(.shape(snapped.shapeElement))
                    onDocumentChanged?(document)
                    needsDisplay = true
                    return
                }
            }
            
            if points.count >= 2 {
                let stroke = Stroke(
                    points: points,
                    color: currentStrokeColor,
                    width: currentStrokeWidth,
                    opacity: currentOpacity,
                    isHighlighter: activeTool == .highlighter
                )
                document.addElement(.stroke(stroke))
                onDocumentChanged?(document)
            }
            
        case .select:
            if let mr = marqueeRect {
                let hits = document.elements.filter { $0.intersects(rect: mr) }.map(\.id)
                selectedElementIDs = Set(hits)
                onSelectionChanged?(selectedElementIDs)
                marqueeRect = nil
            }
            inputHandler.dragStartPoint = nil
            alignmentGuides = []
            
        case .lasso:
            let pts = inputHandler.endStroke()
            if pts.count >= 3 {
                // Polygon intersection
                let polyRect = Stroke(points: pts).bounds
                let hits = document.elements.filter { $0.intersects(rect: polyRect) }.map(\.id)
                selectedElementIDs = Set(hits)
                onSelectionChanged?(selectedElementIDs)
            }
            
        case .rectangle, .ellipse, .line, .arrow, .diamond, .triangle:
            if let start = inputHandler.dragStartPoint {
                createShape(start: start, end: pt)
                inputHandler.dragStartPoint = nil
            }
            
        case .frame:
            if let start = inputHandler.dragStartPoint {
                createFrame(start: start, end: pt)
                inputHandler.dragStartPoint = nil
            }
            
        default:
            break
        }
        needsDisplay = true
    }
    
    // MARK: - Element Creation & Manipulation Helpers
    
    private func handleSelectionMouseDown(at point: Point2D, shiftKey: Bool) {
        inputHandler.dragStartPoint = point
        // Hit test top-most element
        for el in document.elements.reversed() {
            if el.hits(point: point) {
                if shiftKey {
                    if selectedElementIDs.contains(el.id) {
                        selectedElementIDs.remove(el.id)
                    } else {
                        selectedElementIDs.insert(el.id)
                    }
                } else {
                    if !selectedElementIDs.contains(el.id) {
                        selectedElementIDs = [el.id]
                    }
                }
                onSelectionChanged?(selectedElementIDs)
                return
            }
        }
        
        if !shiftKey {
            selectedElementIDs.removeAll()
            onSelectionChanged?(selectedElementIDs)
        }
    }
    
    private func moveSelectedElements(by delta: CGPoint) {
        for id in selectedElementIDs {
            if let idx = document.elements.firstIndex(where: { $0.id == id }) {
                document.elements[idx] = document.elements[idx].translated(by: delta)
            }
        }
        onDocumentChanged?(document)
    }
    
    private func eraseAt(point: Point2D, strokeOnly: Bool) {
        var toRemove = Set<UUID>()
        var newStrokes: [Stroke] = []
        
        for el in document.elements {
            if case .stroke(let stroke) = el {
                if stroke.hits(point: point, tolerance: 12.0) {
                    toRemove.insert(stroke.id)
                    if !strokeOnly {
                        let split = stroke.splitByEraser(eraserCenter: point, eraserRadius: 16.0)
                        newStrokes.append(contentsOf: split)
                    }
                }
            } else if !strokeOnly && el.hits(point: point) {
                toRemove.insert(el.id)
            }
        }
        
        if !toRemove.isEmpty {
            document.removeElements(with: toRemove)
            for s in newStrokes {
                document.addElement(.stroke(s))
            }
            onDocumentChanged?(document)
        }
    }
    
    private func addLaserPoint(_ pt: Point2D) {
        let lp = LaserPoint(position: pt)
        laserPoints.append(lp)
        metalView?.renderer?.laserPoints = laserPoints
        
        if activeLaserTimer == nil {
            activeLaserTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
                guard let self = self else { timer.invalidate(); return }
                let now = ProcessInfo.processInfo.systemUptime
                self.laserPoints.removeAll { $0.alpha(at: now) <= 0.05 }
                self.metalView?.renderer?.laserPoints = self.laserPoints
                if self.laserPoints.isEmpty {
                    timer.invalidate()
                    self.activeLaserTimer = nil
                }
                self.needsDisplay = true
            }
        }
    }
    
    private func createShape(start: Point2D, end: Point2D) {
        var shapeType: ShapeType = .rectangle
        switch activeTool {
        case .rectangle: shapeType = .rectangle
        case .ellipse: shapeType = .ellipse
        case .line: shapeType = .line
        case .arrow: shapeType = .arrow
        case .diamond: shapeType = .diamond
        case .triangle: shapeType = .triangle
        default: break
        }
        
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let w = max(10.0, abs(end.x - start.x))
        let h = max(10.0, abs(end.y - start.y))
        
        let shape = ShapeElement(
            type: shapeType,
            origin: Point2D(x: minX, y: minY),
            size: CGSize(width: w, height: h),
            strokeColor: currentStrokeColor,
            fillColor: currentFillColor,
            strokeWidth: currentStrokeWidth,
            opacity: currentOpacity,
            endArrowhead: shapeType == .arrow ? .standard : .none,
            startPoint: start,
            endPoint: end
        )
        document.addElement(.shape(shape))
        selectedElementIDs = [shape.id]
        onSelectionChanged?(selectedElementIDs)
        onDocumentChanged?(document)
    }
    
    private func createTextElement(at point: Point2D) {
        let text = TextElement(
            origin: point,
            size: CGSize(width: 240, height: 44),
            fontSize: 20.0,
            textColor: currentStrokeColor
        )
        document.addElement(.text(text))
        selectedElementIDs = [text.id]
        onSelectionChanged?(selectedElementIDs)
        onDocumentChanged?(document)
    }
    
    private func createStickyNote(at point: Point2D) {
        let sticky = StickyNoteElement(
            origin: point,
            size: CGSize(width: 200, height: 200),
            theme: .yellow
        )
        document.addElement(.sticky(sticky))
        selectedElementIDs = [sticky.id]
        onSelectionChanged?(selectedElementIDs)
        onDocumentChanged?(document)
    }
    
    private func createFrame(start: Point2D, end: Point2D) {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let w = max(100.0, abs(end.x - start.x))
        let h = max(100.0, abs(end.y - start.y))
        
        let frameCount = document.elements.filter {
            if case .frame = $0 { return true }
            return false
        }.count
        
        let frame = FrameElement(
            title: "Frame \(frameCount + 1)",
            origin: Point2D(x: minX, y: minY),
            size: CGSize(width: w, height: h),
            orderIndex: frameCount
        )
        document.addElement(.frame(frame))
        selectedElementIDs = [frame.id]
        onSelectionChanged?(selectedElementIDs)
        onDocumentChanged?(document)
    }
    
    private func sampleColorAt(point: Point2D) {
        for el in document.elements.reversed() {
            if el.hits(point: point) {
                switch el {
                case .stroke(let s): onColorSampled?(s.color); return
                case .shape(let s): onColorSampled?(s.strokeColor); return
                case .text(let t): onColorSampled?(t.textColor); return
                case .sticky(let st): onColorSampled?(st.theme.backgroundColor); return
                default: break
                }
            }
        }
    }
    
    // MARK: - Drawing Overlays (Shapes, Sticky Notes, Text, Selection Outlines)
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        
        // Draw non-Metal canvas elements (Shapes, Text, Stickies, Frames, Images)
        for el in document.elements {
            drawElement(el, in: ctx)
        }
        
        // Draw Selection Bounding Boxes & Transform Handles
        if !selectedElementIDs.isEmpty {
            drawSelectionOverlay(in: ctx)
        }
        
        // Draw Marquee Rect
        if let mr = marqueeRect {
            let vRect = transform.viewRect(from: mr)
            ctx.setFillColor(NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor)
            ctx.setStrokeColor(NSColor.controlAccentColor.withAlphaComponent(0.8).cgColor)
            ctx.setLineWidth(1.0)
            ctx.fill(vRect)
            ctx.stroke(vRect)
        }
        
        // Draw Alignment Guides
        for guide in alignmentGuides {
            ctx.setStrokeColor(NSColor.systemTeal.withAlphaComponent(0.8).cgColor)
            ctx.setLineWidth(1.0)
            if guide.isVertical {
                let p1 = transform.viewPoint(from: Point2D(x: Double(guide.position), y: Double(guide.start)))
                let p2 = transform.viewPoint(from: Point2D(x: Double(guide.position), y: Double(guide.end)))
                ctx.move(to: p1)
                ctx.addLine(to: p2)
            } else {
                let p1 = transform.viewPoint(from: Point2D(x: Double(guide.start), y: Double(guide.position)))
                let p2 = transform.viewPoint(from: Point2D(x: Double(guide.end), y: Double(guide.position)))
                ctx.move(to: p1)
                ctx.addLine(to: p2)
            }
            ctx.strokePath()
        }
    }
    
    private func drawElement(_ element: CanvasElement, in ctx: CGContext) {
        switch element {
        case .shape(let shape):
            drawShape(shape, in: ctx)
        case .text(let text):
            drawText(text, in: ctx)
        case .sticky(let sticky):
            drawStickyNote(sticky, in: ctx)
        case .connector(let conn):
            drawConnector(conn, in: ctx)
        case .frame(let frame):
            drawFrame(frame, in: ctx)
        case .image(let image):
            drawImage(image, in: ctx)
        case .stroke:
            break // Rendered at 120fps via Metal
        }
    }
    
    private func drawShape(_ shape: ShapeElement, in ctx: CGContext) {
        ctx.saveGState()
        let vOrigin = transform.viewPoint(from: shape.origin)
        let vSize = CGSize(width: shape.size.width * transform.zoom, height: shape.size.height * transform.zoom)
        let rect = CGRect(origin: vOrigin, size: vSize)
        
        ctx.setStrokeColor(shape.strokeColor.cgColor)
        ctx.setFillColor(shape.fillColor.cgColor)
        ctx.setLineWidth(CGFloat(shape.strokeWidth) * transform.zoom)
        ctx.setAlpha(CGFloat(shape.opacity))
        
        switch shape.type {
        case .rectangle:
            let cr = CGFloat(shape.cornerRadius) * transform.zoom
            let path = CGPath(roundedRect: rect, cornerWidth: cr, cornerHeight: cr, transform: nil)
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
            let p1 = transform.viewPoint(from: shape.startPoint ?? shape.origin)
            let p2 = transform.viewPoint(from: shape.endPoint ?? Point2D(x: shape.origin.x + shape.size.width, y: shape.origin.y + shape.size.height))
            ctx.move(to: p1)
            ctx.addLine(to: p2)
            ctx.strokePath()
            
            if shape.type == .arrow {
                drawArrowhead(from: p1, to: p2, in: ctx, color: shape.strokeColor.cgColor, size: CGFloat(shape.strokeWidth * 4.0 * Double(transform.zoom)))
            }
        }
        ctx.restoreGState()
    }
    
    private func drawArrowhead(from p1: CGPoint, to p2: CGPoint, in ctx: CGContext, color: CGColor, size: CGFloat) {
        let angle = atan2(p2.y - p1.y, p2.x - p1.x)
        let arrowLen = max(10.0, size)
        let arrowAngle: CGFloat = .pi / 6.0
        
        let a1 = CGPoint(x: p2.x - arrowLen * cos(angle - arrowAngle), y: p2.y - arrowLen * sin(angle - arrowAngle))
        let a2 = CGPoint(x: p2.x - arrowLen * cos(angle + arrowAngle), y: p2.y - arrowLen * sin(angle + arrowAngle))
        
        ctx.setFillColor(color)
        ctx.move(to: p2)
        ctx.addLine(to: a1)
        ctx.addLine(to: a2)
        ctx.closePath()
        ctx.fillPath()
    }
    
    private func drawText(_ text: TextElement, in ctx: CGContext) {
        let vOrigin = transform.viewPoint(from: text.origin)
        let font = NSFont.systemFont(ofSize: CGFloat(text.fontSize) * transform.zoom, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: text.textColor.nsColor
        ]
        let attrStr = NSAttributedString(string: text.text, attributes: attrs)
        let vSize = CGSize(width: text.size.width * transform.zoom, height: text.size.height * transform.zoom)
        attrStr.draw(in: CGRect(origin: vOrigin, size: vSize))
    }
    
    private func drawStickyNote(_ sticky: StickyNoteElement, in ctx: CGContext) {
        let vOrigin = transform.viewPoint(from: sticky.origin)
        let vSize = CGSize(width: sticky.size.width * transform.zoom, height: sticky.size.height * transform.zoom)
        let rect = CGRect(origin: vOrigin, size: vSize)
        
        ctx.saveGState()
        // Subtle single-layer shadow
        ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: 6.0, color: NSColor.black.withAlphaComponent(0.08).cgColor)
        ctx.setFillColor(sticky.theme.backgroundColor.cgColor)
        let path = CGPath(roundedRect: rect, cornerWidth: 6.0, cornerHeight: 6.0, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Draw sticky text
        let font = NSFont.systemFont(ofSize: CGFloat(sticky.fontSize) * transform.zoom, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: sticky.theme.textColor.nsColor
        ]
        let pad = 12.0 * transform.zoom
        let textRect = rect.insetBy(dx: pad, dy: pad)
        let attrStr = NSAttributedString(string: sticky.text, attributes: attrs)
        attrStr.draw(in: textRect)
    }
    
    private func drawConnector(_ conn: ConnectorElement, in ctx: CGContext) {
        let pts = conn.computePathPoints(startPt: conn.startAnchor.absolutePoint, endPt: conn.endAnchor.absolutePoint)
        guard pts.count >= 2 else { return }
        
        ctx.saveGState()
        ctx.setStrokeColor(conn.strokeColor.cgColor)
        ctx.setLineWidth(CGFloat(conn.strokeWidth) * transform.zoom)
        ctx.setAlpha(CGFloat(conn.opacity))
        
        let vPoints = pts.map { transform.viewPoint(from: $0) }
        ctx.move(to: vPoints[0])
        for pt in vPoints.dropFirst() {
            ctx.addLine(to: pt)
        }
        ctx.strokePath()
        
        if conn.endArrowhead == .standard, vPoints.count >= 2 {
            let last = vPoints[vPoints.count - 1]
            let prev = vPoints[vPoints.count - 2]
            drawArrowhead(from: prev, to: last, in: ctx, color: conn.strokeColor.cgColor, size: CGFloat(conn.strokeWidth * 4.0 * Double(transform.zoom)))
        }
        ctx.restoreGState()
    }
    
    private func drawFrame(_ frame: FrameElement, in ctx: CGContext) {
        let vRect = transform.viewRect(from: frame.bounds)
        let titleRect = transform.viewRect(from: frame.titleBarBounds)
        
        ctx.saveGState()
        ctx.setFillColor(frame.backgroundColor.cgColor)
        ctx.setStrokeColor(frame.strokeColor.cgColor)
        ctx.setLineWidth(1.0)
        let path = CGPath(roundedRect: vRect, cornerWidth: 8.0, cornerHeight: 8.0, transform: nil)
        ctx.addPath(path)
        ctx.drawPath(using: .fillStroke)
        
        // Title Bar Label
        let font = NSFont.systemFont(ofSize: 13.0, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let attrStr = NSAttributedString(string: frame.title, attributes: attrs)
        attrStr.draw(at: CGPoint(x: titleRect.minX + 8, y: titleRect.minY + 4))
        ctx.restoreGState()
    }
    
    private func drawImage(_ image: ImageElement, in ctx: CGContext) {
        let vRect = transform.viewRect(from: image.bounds)
        if let data = image.rawImageData ?? DocumentStore.shared.assetDataCache[image.assetId],
           let nsImg = NSImage(data: data) {
            ctx.saveGState()
            ctx.setAlpha(CGFloat(image.opacity))
            nsImg.draw(in: vRect)
            ctx.restoreGState()
        }
    }
    
    private func drawSelectionOverlay(in ctx: CGContext) {
        guard let b = document.selectionBounds(for: selectedElementIDs) else { return }
        let vRect = transform.viewRect(from: b)
        
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.controlAccentColor.cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(vRect)
        
        // Draw 8 resize handles
        let handleSize: CGFloat = 8.0
        let handlePoints = [
            CGPoint(x: vRect.minX, y: vRect.minY),
            CGPoint(x: vRect.midX, y: vRect.minY),
            CGPoint(x: vRect.maxX, y: vRect.minY),
            CGPoint(x: vRect.minX, y: vRect.midY),
            CGPoint(x: vRect.maxX, y: vRect.midY),
            CGPoint(x: vRect.minX, y: vRect.maxY),
            CGPoint(x: vRect.midX, y: vRect.maxY),
            CGPoint(x: vRect.maxX, y: vRect.maxY)
        ]
        
        ctx.setFillColor(NSColor.white.cgColor)
        for hp in handlePoints {
            let handleRect = CGRect(x: hp.x - handleSize / 2, y: hp.y - handleSize / 2, width: handleSize, height: handleSize)
            ctx.fill(handleRect)
            ctx.stroke(handleRect)
        }
        ctx.restoreGState()
    }
}
#endif
