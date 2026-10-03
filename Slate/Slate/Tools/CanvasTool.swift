//
//  CanvasTool.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation

public enum CanvasTool: String, CaseIterable, Identifiable, Sendable {
    // 20 Native Tools
    case select = "Select"
    case pen = "Pen"
    case highlighter = "Highlighter"
    case strokeEraser = "Stroke Eraser"
    case pixelEraser = "Pixel Eraser"
    case text = "Text"
    case rectangle = "Rectangle"
    case ellipse = "Ellipse"
    case line = "Line"
    case arrow = "Arrow"
    case diamond = "Diamond"
    case triangle = "Triangle"
    case sticky = "Sticky Note"
    case connector = "Connector"
    case laser = "Laser Pointer"
    case hand = "Hand"
    case frame = "Frame"
    case image = "Image"
    case lasso = "Lasso Select"
    case eyedropper = "Eyedropper"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .select: return "arrow.up.left"
        case .pen: return "pencil.tip"
        case .highlighter: return "highlighter"
        case .strokeEraser: return "eraser"
        case .pixelEraser: return "eraser.line.dashed"
        case .text: return "textformat"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .line: return "line.diagonal"
        case .arrow: return "arrow.right"
        case .diamond: return "rhombus"
        case .triangle: return "triangle"
        case .sticky: return "note.text"
        case .connector: return "point.topleft.down.to.point.bottomright.curvepath"
        case .laser: return "smallcircle.filled.circle"
        case .hand: return "hand.raised"
        case .frame: return "viewfinder"
        case .image: return "photo"
        case .lasso: return "lasso"
        case .eyedropper: return "eyedropper"
        }
    }
    
    public var shortcutKey: Character? {
        switch self {
        case .select: return "v"
        case .pen: return "p"
        case .highlighter: return "h"
        case .strokeEraser: return "e"
        case .pixelEraser: return "x"
        case .text: return "t"
        case .rectangle: return "r"
        case .ellipse: return "o"
        case .line: return "l"
        case .arrow: return "a"
        case .diamond: return "d"
        case .triangle: return "g"
        case .sticky: return "s"
        case .connector: return "c"
        case .laser: return "k"
        case .hand: return " " // Space
        case .frame: return "f"
        case .image: return "i"
        case .lasso: return "q"
        case .eyedropper: return "y"
        }
    }
    
    public var shortcutDisplay: String {
        switch self {
        case .select: return "V"
        case .pen: return "P"
        case .highlighter: return "H"
        case .strokeEraser: return "E"
        case .pixelEraser: return "X"
        case .text: return "T"
        case .rectangle: return "R"
        case .ellipse: return "O"
        case .line: return "L"
        case .arrow: return "A"
        case .diamond: return "D"
        case .triangle: return "G"
        case .sticky: return "S"
        case .connector: return "C"
        case .laser: return "K"
        case .hand: return "Space"
        case .frame: return "F"
        case .image: return "I"
        case .lasso: return "Q"
        case .eyedropper: return "Y"
        }
    }
}
