//
//  GuideLayoutEngine.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public enum GuideLayoutType: String, CaseIterable, Identifiable, Sendable {
    case flowchart = "Flowchart"
    case mindmap = "Mind Map"
    case stepCards = "Step Cards"
    case timeline = "Timeline"
    case checklist = "Checklist"
    case comparisonTable = "Comparison Table"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .flowchart: return "arrow.triangle.branch"
        case .mindmap: return "circle.hexagongrid"
        case .stepCards: return "square.stack.3d.forward.dottedline"
        case .timeline: return "timeline.selection"
        case .checklist: return "checklist"
        case .comparisonTable: return "tablecells"
        }
    }
}

public final class GuideLayoutEngine {
    
    public static func generateLayout(
        type: GuideLayoutType,
        parsedDoc: ParsedGuideDocument,
        origin: Point2D = Point2D(x: 100, y: 100)
    ) -> [CanvasElement] {
        switch type {
        case .flowchart:
            return generateFlowchart(parsedDoc: parsedDoc, origin: origin)
        case .mindmap:
            return generateMindMap(parsedDoc: parsedDoc, origin: origin)
        case .stepCards:
            return generateStepCards(parsedDoc: parsedDoc, origin: origin)
        case .timeline:
            return generateTimeline(parsedDoc: parsedDoc, origin: origin)
        case .checklist:
            return generateChecklist(parsedDoc: parsedDoc, origin: origin)
        case .comparisonTable:
            return generateComparisonTable(parsedDoc: parsedDoc, origin: origin)
        }
    }
    
    // MARK: - 1. Flowchart Generator
    private static func generateFlowchart(parsedDoc: ParsedGuideDocument, origin: Point2D) -> [CanvasElement] {
        var elements: [CanvasElement] = []
        var curY = origin.y
        let nodeWidth: Double = 220
        let nodeHeight: Double = 64
        let spacing: Double = 50
        
        var nodeTexts: [String] = []
        for el in parsedDoc.elements {
            switch el {
            case .flowTransition(let from, let to, _):
                if !nodeTexts.contains(from) { nodeTexts.append(from) }
                if !nodeTexts.contains(to) { nodeTexts.append(to) }
            case .numberedStep(_, let text), .bullet(let text, _), .paragraph(let text):
                if !nodeTexts.contains(text) { nodeTexts.append(text) }
            default:
                break
            }
        }
        
        if nodeTexts.isEmpty { nodeTexts = ["Start", "Process Task", "Evaluate Result", "End"] }
        
        var previousShape: ShapeElement? = nil
        
        for (idx, text) in nodeTexts.enumerated() {
            let isDecision = text.lowercased().contains("?") || text.lowercased().contains("check") || text.lowercased().contains("if")
            let shapeType: ShapeType = isDecision ? .diamond : .rectangle
            
            let shape = ShapeElement(
                type: shapeType,
                origin: Point2D(x: origin.x, y: curY),
                size: CGSize(width: nodeWidth, height: nodeHeight),
                strokeColor: .graphite,
                fillColor: ColorData(hex: isDecision ? "#FEF08A" : "#F1F5F9"),
                strokeWidth: 2.0,
                cornerRadius: 8.0
            )
            elements.append(.shape(shape))
            
            let label = TextElement(
                text: text,
                origin: Point2D(x: origin.x + 12, y: curY + (nodeHeight / 2.0) - 10),
                size: CGSize(width: nodeWidth - 24, height: 24),
                fontSize: 14.0,
                alignment: .center,
                textColor: .ink
            )
            elements.append(.text(label))
            
            if let prev = previousShape {
                let startPt = Point2D(x: prev.origin.x + prev.size.width / 2.0, y: prev.origin.y + prev.size.height)
                let endPt = Point2D(x: shape.origin.x + shape.size.width / 2.0, y: shape.origin.y)
                let conn = ConnectorElement(
                    startAnchor: ConnectorAnchor(elementId: prev.id, anchorIndex: 2, absolutePoint: startPt),
                    endAnchor: ConnectorAnchor(elementId: shape.id, anchorIndex: 0, absolutePoint: endPt),
                    routing: .straight,
                    strokeColor: .graphite,
                    strokeWidth: 2.0,
                    endArrowhead: .standard
                )
                elements.append(.connector(conn))
            }
            
            previousShape = shape
            curY += nodeHeight + spacing
        }
        
        return elements
    }
    
    // MARK: - 2. Mind Map Generator
    private static func generateMindMap(parsedDoc: ParsedGuideDocument, origin: Point2D) -> [CanvasElement] {
        var elements: [CanvasElement] = []
        let center = Point2D(x: origin.x + 350, y: origin.y + 250)
        
        // Central Node
        let centerShape = ShapeElement(
            type: .rectangle,
            origin: Point2D(x: center.x - 100, y: center.y - 40),
            size: CGSize(width: 200, height: 80),
            strokeColor: .cobalt,
            fillColor: ColorData(hex: "#EFF6FF"),
            strokeWidth: 2.5,
            cornerRadius: 12.0
        )
        elements.append(.shape(centerShape))
        
        let centerText = TextElement(
            text: parsedDoc.title,
            origin: Point2D(x: center.x - 90, y: center.y - 14),
            size: CGSize(width: 180, height: 28),
            fontSize: 18.0,
            fontWeight: .bold,
            alignment: .center,
            textColor: .ink
        )
        elements.append(.text(centerText))
        
        // Extract branch topics
        var branches: [String] = []
        for el in parsedDoc.elements {
            switch el {
            case .heading(_, let text), .bullet(let text, _), .numberedStep(_, let text), .paragraph(let text):
                if text != parsedDoc.title { branches.append(text) }
            default: break
            }
        }
        if branches.isEmpty { branches = ["Overview", "Architecture", "Design Goals", "Milestones"] }
        
        let radius: Double = 260
        let count = branches.count
        let colors: [ColorData] = [.emerald, .amber, .coral, .indigo, .teal, .wine]
        
        for (i, branch) in branches.enumerated() {
            let angle = (Double(i) / Double(count)) * Double.pi * 2.0 - (Double.pi / 2.0)
            let branchX = center.x + cos(angle) * radius - 80
            let branchY = center.y + sin(angle) * radius - 25
            let color = colors[i % colors.count]
            
            let bShape = ShapeElement(
                type: .rectangle,
                origin: Point2D(x: branchX, y: branchY),
                size: CGSize(width: 160, height: 50),
                strokeColor: color,
                fillColor: ColorData(hex: "#F8FAFC"),
                strokeWidth: 2.0,
                cornerRadius: 8.0
            )
            elements.append(.shape(bShape))
            
            let bText = TextElement(
                text: branch,
                origin: Point2D(x: branchX + 8, y: branchY + 12),
                size: CGSize(width: 144, height: 24),
                fontSize: 13.0,
                fontWeight: .semibold,
                alignment: .center,
                textColor: .ink
            )
            elements.append(.text(bText))
            
            let startPt = Point2D(x: center.x, y: center.y)
            let endPt = Point2D(x: branchX + 80, y: branchY + 25)
            let conn = ConnectorElement(
                startAnchor: ConnectorAnchor(elementId: centerShape.id, absolutePoint: startPt),
                endAnchor: ConnectorAnchor(elementId: bShape.id, absolutePoint: endPt),
                routing: .curved,
                strokeColor: color,
                strokeWidth: 2.0
            )
            elements.append(.connector(conn))
        }
        
        return elements
    }
    
    // MARK: - 3. Step Cards Generator
    private static func generateStepCards(parsedDoc: ParsedGuideDocument, origin: Point2D) -> [CanvasElement] {
        var elements: [CanvasElement] = []
        var curX = origin.x
        let cardWidth: Double = 240
        let cardHeight: Double = 160
        let spacing: Double = 40
        
        var steps: [(number: Int, text: String)] = []
        var stepNum = 1
        for el in parsedDoc.elements {
            switch el {
            case .numberedStep(let num, let text):
                steps.append((num, text))
            case .bullet(let text, _), .paragraph(let text):
                steps.append((stepNum, text))
                stepNum += 1
            default: break
            }
        }
        if steps.isEmpty {
            steps = [(1, "Discovery & Research"), (2, "System Architecture"), (3, "Implementation"), (4, "Quality Assurance")]
        }
        
        var prevCard: ShapeElement? = nil
        for step in steps {
            let card = ShapeElement(
                type: .rectangle,
                origin: Point2D(x: curX, y: origin.y),
                size: CGSize(width: cardWidth, height: cardHeight),
                strokeColor: ColorData(hex: "#E2E8F0"),
                fillColor: .white,
                strokeWidth: 1.5,
                cornerRadius: 12.0
            )
            elements.append(.shape(card))
            
            // Step Number Badge
            let badge = ShapeElement(
                type: .ellipse,
                origin: Point2D(x: curX + 16, y: origin.y + 16),
                size: CGSize(width: 32, height: 32),
                strokeColor: .cobalt,
                fillColor: ColorData(hex: "#DBEAFE"),
                strokeWidth: 1.5
            )
            elements.append(.shape(badge))
            
            let numText = TextElement(
                text: "\(step.number)",
                origin: Point2D(x: curX + 16, y: origin.y + 20),
                size: CGSize(width: 32, height: 24),
                fontSize: 14.0,
                fontWeight: .bold,
                alignment: .center,
                textColor: .cobalt
            )
            elements.append(.text(numText))
            
            // Step Content Text
            let descText = TextElement(
                text: step.text,
                origin: Point2D(x: curX + 16, y: origin.y + 60),
                size: CGSize(width: cardWidth - 32, height: 80),
                fontSize: 15.0,
                fontWeight: .medium,
                textColor: .ink
            )
            elements.append(.text(descText))
            
            if let prev = prevCard {
                let p1 = Point2D(x: prev.origin.x + prev.size.width, y: origin.y + cardHeight / 2.0)
                let p2 = Point2D(x: card.origin.x, y: origin.y + cardHeight / 2.0)
                let arrow = ShapeElement(
                    type: .arrow,
                    origin: p1,
                    size: CGSize(width: spacing, height: 10),
                    strokeColor: .graphite,
                    strokeWidth: 2.0,
                    endArrowhead: .standard,
                    startPoint: p1,
                    endPoint: p2
                )
                elements.append(.shape(arrow))
            }
            
            prevCard = card
            curX += cardWidth + spacing
        }
        
        return elements
    }
    
    // MARK: - 4. Timeline Generator
    private static func generateTimeline(parsedDoc: ParsedGuideDocument, origin: Point2D) -> [CanvasElement] {
        var elements: [CanvasElement] = []
        var events: [(date: String, title: String)] = []
        
        for el in parsedDoc.elements {
            switch el {
            case .timelineEvent(let date, let title, _):
                events.append((date, title))
            case .numberedStep(let num, let text):
                events.append(("Phase \(num)", text))
            case .bullet(let text, _):
                events.append(("Milestone", text))
            default: break
            }
        }
        if events.isEmpty {
            events = [("Q1 2026", "Requirements & Architecture"), ("Q2 2026", "Core Engine Development"), ("Q3 2026", "Camera CV Integration"), ("Q4 2026", "Production Release")]
        }
        
        let nodeSpacing: Double = 220
        let startX = origin.x + 40
        let lineY = origin.y + 120
        let totalWidth = Double(events.count - 1) * nodeSpacing
        
        // Central Axis Line
        let axisLine = ShapeElement(
            type: .line,
            origin: Point2D(x: startX, y: lineY),
            size: CGSize(width: totalWidth, height: 1),
            strokeColor: .graphite,
            strokeWidth: 2.5,
            startPoint: Point2D(x: startX, y: lineY),
            endPoint: Point2D(x: startX + totalWidth, y: lineY)
        )
        elements.append(.shape(axisLine))
        
        for (i, evt) in events.enumerated() {
            let nodeX = startX + Double(i) * nodeSpacing
            let isAbove = i % 2 == 0
            
            // Milestone Pin Dot
            let dot = ShapeElement(
                type: .ellipse,
                origin: Point2D(x: nodeX - 8, y: lineY - 8),
                size: CGSize(width: 16, height: 16),
                strokeColor: .cobalt,
                fillColor: .white,
                strokeWidth: 3.0
            )
            elements.append(.shape(dot))
            
            // Date Chip
            let chipY = isAbove ? lineY - 90 : lineY + 30
            let chip = ShapeElement(
                type: .rectangle,
                origin: Point2D(x: nodeX - 90, y: chipY),
                size: CGSize(width: 180, height: 60),
                strokeColor: ColorData(hex: "#E2E8F0"),
                fillColor: ColorData(hex: "#F8FAFC"),
                strokeWidth: 1.0,
                cornerRadius: 8.0
            )
            elements.append(.shape(chip))
            
            let dateLabel = TextElement(
                text: evt.date,
                origin: Point2D(x: nodeX - 80, y: chipY + 8),
                size: CGSize(width: 160, height: 18),
                fontSize: 12.0,
                fontWeight: .bold,
                textColor: .cobalt
            )
            elements.append(.text(dateLabel))
            
            let titleLabel = TextElement(
                text: evt.title,
                origin: Point2D(x: nodeX - 80, y: chipY + 28),
                size: CGSize(width: 160, height: 26),
                fontSize: 13.0,
                fontWeight: .regular,
                textColor: .ink
            )
            elements.append(.text(titleLabel))
        }
        
        return elements
    }
    
    // MARK: - 5. Checklist Generator
    private static func generateChecklist(parsedDoc: ParsedGuideDocument, origin: Point2D) -> [CanvasElement] {
        var elements: [CanvasElement] = []
        var curY = origin.y
        let itemWidth: Double = 400
        let itemHeight: Double = 48
        let spacing: Double = 12
        
        var items: [(text: String, isDone: Bool)] = []
        for el in parsedDoc.elements {
            switch el {
            case .checklistItem(let text, let isDone):
                items.append((text, isDone))
            case .bullet(let text, _), .numberedStep(_, let text), .paragraph(let text):
                items.append((text, false))
            default: break
            }
        }
        if items.isEmpty {
            items = [("Review functional specification", true), ("Implement zero-latency Metal stroke renderer", true), ("Add camera finger tracking computer vision", true), ("Write unit test suite", true), ("Package native macOS DMG", false)]
        }
        
        for item in items {
            let row = ShapeElement(
                type: .rectangle,
                origin: Point2D(x: origin.x, y: curY),
                size: CGSize(width: itemWidth, height: itemHeight),
                strokeColor: ColorData(hex: "#E2E8F0"),
                fillColor: ColorData(hex: item.isDone ? "#F0FDF4" : "#FFFFFF"),
                strokeWidth: 1.0,
                cornerRadius: 8.0
            )
            elements.append(.shape(row))
            
            // Checkbox Icon box
            let box = ShapeElement(
                type: .rectangle,
                origin: Point2D(x: origin.x + 14, y: curY + 14),
                size: CGSize(width: 20, height: 20),
                strokeColor: item.isDone ? .emerald : .graphite,
                fillColor: item.isDone ? .emerald : .clear,
                strokeWidth: 1.5,
                cornerRadius: 4.0
            )
            elements.append(.shape(box))
            
            let label = TextElement(
                text: item.text,
                origin: Point2D(x: origin.x + 46, y: curY + 13),
                size: CGSize(width: itemWidth - 60, height: 22),
                fontSize: 14.0,
                fontWeight: item.isDone ? .regular : .medium,
                textColor: item.isDone ? .graphite : .ink
            )
            elements.append(.text(label))
            
            curY += itemHeight + spacing
        }
        
        return elements
    }
    
    // MARK: - 6. Comparison Table Generator
    private static func generateComparisonTable(parsedDoc: ParsedGuideDocument, origin: Point2D) -> [CanvasElement] {
        var elements: [CanvasElement] = []
        let colWidth: Double = 260
        let rowHeight: Double = 56
        let headerHeight: Double = 60
        
        var comparisons: [(left: String, right: String)] = []
        for el in parsedDoc.elements {
            if case .comparison(let l, let r, _) = el {
                comparisons.append((l, r))
            }
        }
        if comparisons.isEmpty {
            comparisons = [("Local-First Native App", "Cloud SaaS Subscription"), ("120fps Metal Pipeline", "Web DOM / Electron"), ("Deterministic CV Tracking", "Heavy Cloud ML"), ("Full Sandboxed Privacy", "Third-party Telemetry")]
        }
        
        // Header Left Card
        let headLeft = ShapeElement(
            type: .rectangle,
            origin: origin,
            size: CGSize(width: colWidth, height: headerHeight),
            strokeColor: .cobalt,
            fillColor: ColorData(hex: "#EFF6FF"),
            strokeWidth: 1.5,
            cornerRadius: 8.0
        )
        elements.append(.shape(headLeft))
        
        let headLeftText = TextElement(
            text: "Option A (Slate)",
            origin: Point2D(x: origin.x + 16, y: origin.y + 18),
            size: CGSize(width: colWidth - 32, height: 24),
            fontSize: 16.0,
            fontWeight: .bold,
            textColor: .cobalt
        )
        elements.append(.text(headLeftText))
        
        // Header Right Card
        let headRight = ShapeElement(
            type: .rectangle,
            origin: Point2D(x: origin.x + colWidth + 16, y: origin.y),
            size: CGSize(width: colWidth, height: headerHeight),
            strokeColor: .graphite,
            fillColor: ColorData(hex: "#F8FAFC"),
            strokeWidth: 1.5,
            cornerRadius: 8.0
        )
        elements.append(.shape(headRight))
        
        let headRightText = TextElement(
            text: "Option B (Alternatives)",
            origin: Point2D(x: origin.x + colWidth + 32, y: origin.y + 18),
            size: CGSize(width: colWidth - 32, height: 24),
            fontSize: 16.0,
            fontWeight: .bold,
            textColor: .ink
        )
        elements.append(.text(headRightText))
        
        var curY = origin.y + headerHeight + 12
        for pair in comparisons {
            let rowL = ShapeElement(
                type: .rectangle,
                origin: Point2D(x: origin.x, y: curY),
                size: CGSize(width: colWidth, height: rowHeight),
                strokeColor: ColorData(hex: "#E2E8F0"),
                fillColor: .white,
                strokeWidth: 1.0,
                cornerRadius: 6.0
            )
            elements.append(.shape(rowL))
            
            let textL = TextElement(
                text: pair.left,
                origin: Point2D(x: origin.x + 12, y: curY + 16),
                size: CGSize(width: colWidth - 24, height: 24),
                fontSize: 14.0,
                textColor: .ink
            )
            elements.append(.text(textL))
            
            let rowR = ShapeElement(
                type: .rectangle,
                origin: Point2D(x: origin.x + colWidth + 16, y: curY),
                size: CGSize(width: colWidth, height: rowHeight),
                strokeColor: ColorData(hex: "#E2E8F0"),
                fillColor: .white,
                strokeWidth: 1.0,
                cornerRadius: 6.0
            )
            elements.append(.shape(rowR))
            
            let textR = TextElement(
                text: pair.right,
                origin: Point2D(x: origin.x + colWidth + 28, y: curY + 16),
                size: CGSize(width: colWidth - 24, height: 24),
                fontSize: 14.0,
                textColor: .ink
            )
            elements.append(.text(textR))
            
            curY += rowHeight + 8
        }
        
        return elements
    }
}
