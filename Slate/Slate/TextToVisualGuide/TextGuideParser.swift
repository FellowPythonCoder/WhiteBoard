//
//  TextGuideParser.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation

public enum GuideElementType: Sendable {
    case heading(level: Int, text: String)
    case bullet(text: String, indent: Int)
    case numberedStep(number: Int, text: String)
    case flowTransition(from: String, to: String, label: String?)
    case comparison(left: String, right: String, attribute: String?)
    case timelineEvent(date: String, title: String, description: String?)
    case checklistItem(text: String, isCompleted: Bool)
    case paragraph(text: String)
}

public struct ParsedGuideDocument: Sendable {
    public var title: String
    public var elements: [GuideElementType]
    public var rawText: String
}

public final class TextGuideParser {
    
    public static func parse(text: String) -> ParsedGuideDocument {
        let lines = text.components(separatedBy: .newlines)
        var elements: [GuideElementType] = []
        var detectedTitle = "Visual Guide"
        var firstHeadingFound = false
        
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            // 1. Heading (#, ##, ###)
            if line.hasPrefix("#") {
                let level = line.prefix(while: { $0 == "#" }).count
                let text = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
                elements.append(.heading(level: level, text: text))
                if !firstHeadingFound {
                    detectedTitle = text
                    firstHeadingFound = true
                }
                continue
            }
            
            // 2. Checklist ([ ] or [x] or - [ ])
            if line.hasPrefix("[ ]") || line.hasPrefix("- [ ]") {
                let clean = line.replacingOccurrences(of: "- [ ]", with: "").replacingOccurrences(of: "[ ]", with: "").trimmingCharacters(in: .whitespaces)
                elements.append(.checklistItem(text: clean, isCompleted: false))
                continue
            } else if line.hasPrefix("[x]") || line.hasPrefix("- [x]") || line.hasPrefix("[X]") {
                let clean = line.replacingOccurrences(of: "- [x]", with: "").replacingOccurrences(of: "[x]", with: "").replacingOccurrences(of: "[X]", with: "").trimmingCharacters(in: .whitespaces)
                elements.append(.checklistItem(text: clean, isCompleted: true))
                continue
            }
            
            // 3. Flow Transition ("->" or "=>")
            if line.contains("->") || line.contains("=>") {
                let delimiter = line.contains("->") ? "->" : "=>"
                let parts = line.components(separatedBy: delimiter)
                if parts.count >= 2 {
                    for i in 0..<(parts.count - 1) {
                        let from = parts[i].trimmingCharacters(in: .whitespaces)
                        let to = parts[i + 1].trimmingCharacters(in: .whitespaces)
                        elements.append(.flowTransition(from: from, to: to, label: nil))
                    }
                    continue
                }
            }
            
            // 4. Comparison (" vs " or " vs. " or " versus ")
            let lower = line.lowercased()
            if lower.contains(" vs ") || lower.contains(" vs. ") || lower.contains(" versus ") {
                var compParts: [String] = []
                if lower.contains(" vs ") { compParts = line.components(separatedBy: " vs ") }
                else if lower.contains(" vs. ") { compParts = line.components(separatedBy: " vs. ") }
                else if lower.contains(" versus ") { compParts = line.components(separatedBy: " versus ") }
                
                if compParts.count == 2 {
                    elements.append(.comparison(left: compParts[0].trimmingCharacters(in: .whitespaces),
                                               right: compParts[1].trimmingCharacters(in: .whitespaces),
                                               attribute: nil))
                    continue
                }
            }
            
            // 5. Timeline Event (Starts with date or year e.g. 2026, Oct 2026, Q1 2026, 2026-10-03)
            if let timeline = parseTimelineLine(line) {
                elements.append(timeline)
                continue
            }
            
            // 6. Numbered Step (1. 2. 3.)
            if let num = parseNumberedStep(line) {
                elements.append(num)
                continue
            }
            
            // 7. Bullet List (- * •)
            if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") {
                let clean = line.dropFirst(2).trimmingCharacters(in: .whitespaces)
                let leadingSpaces = rawLine.prefix(while: { $0 == " " || $0 == "\t" }).count
                elements.append(.bullet(text: clean, indent: leadingSpaces / 2))
                continue
            }
            
            // 8. General Paragraph
            elements.append(.paragraph(text: line))
        }
        
        return ParsedGuideDocument(title: detectedTitle, elements: elements, rawText: text)
    }
    
    private static func parseNumberedStep(_ line: String) -> GuideElementType? {
        let scanner = Scanner(string: line)
        var num: Int = 0
        if scanner.scanInt(&num) && (scanner.scanString(".") != nil || scanner.scanString(")") != nil) {
            let remainder = line.dropFirst(scanner.currentIndex.utf16Offset(in: line)).trimmingCharacters(in: .whitespaces)
            return .numberedStep(number: num, text: remainder)
        }
        return nil
    }
    
    private static func parseTimelineLine(_ line: String) -> GuideElementType? {
        let parts = line.components(separatedBy: ":")
        guard parts.count >= 2 else { return nil }
        let datePart = parts[0].trimmingCharacters(in: .whitespaces)
        let textPart = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
        
        // Check if datePart looks like a date, year, quarter, or milestone
        let dateKeywords = ["20", "19", "Q1", "Q2", "Q3", "Q4", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Sprint", "Phase", "Step", "Week", "Day"]
        if dateKeywords.contains(where: { datePart.contains($0) }) {
            return .timelineEvent(date: datePart, title: textPart, description: nil)
        }
        return nil
    }
}
