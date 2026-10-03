//
//  CanvasElement.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public enum CanvasElement: Codable, Identifiable, Equatable, Sendable {
    case stroke(Stroke)
    case shape(ShapeElement)
    case text(TextElement)
    case sticky(StickyNoteElement)
    case connector(ConnectorElement)
    case frame(FrameElement)
    case image(ImageElement)
    
    public var id: UUID {
        switch self {
        case .stroke(let s): return s.id
        case .shape(let s): return s.id
        case .text(let t): return t.id
        case .sticky(let st): return st.id
        case .connector(let c): return c.id
        case .frame(let f): return f.id
        case .image(let img): return img.id
        }
    }
    
    public var zIndex: Int {
        get {
            switch self {
            case .stroke(let s): return s.zIndex
            case .shape(let s): return s.zIndex
            case .text(let t): return t.zIndex
            case .sticky(let st): return st.zIndex
            case .connector(let c): return c.zIndex
            case .frame(let f): return f.zIndex
            case .image(let img): return img.zIndex
            }
        }
        set {
            switch self {
            case .stroke(var s): s.zIndex = newValue; self = .stroke(s)
            case .shape(var s): s.zIndex = newValue; self = .shape(s)
            case .text(var t): t.zIndex = newValue; self = .text(t)
            case .sticky(var st): st.zIndex = newValue; self = .sticky(st)
            case .connector(var c): c.zIndex = newValue; self = .connector(c)
            case .frame(var f): f.zIndex = newValue; self = .frame(f)
            case .image(var img): img.zIndex = newValue; self = .image(img)
            }
        }
    }
    
    public var isLocked: Bool {
        get {
            switch self {
            case .stroke(let s): return s.isLocked
            case .shape(let s): return s.isLocked
            case .text(let t): return t.isLocked
            case .sticky(let st): return st.isLocked
            case .connector(let c): return c.isLocked
            case .frame(let f): return f.isLocked
            case .image(let img): return img.isLocked
            }
        }
        set {
            switch self {
            case .stroke(var s): s.isLocked = newValue; self = .stroke(s)
            case .shape(var s): s.isLocked = newValue; self = .shape(s)
            case .text(var t): t.isLocked = newValue; self = .text(t)
            case .sticky(var st): st.isLocked = newValue; self = .sticky(st)
            case .connector(var c): c.isLocked = newValue; self = .connector(c)
            case .frame(var f): f.isLocked = newValue; self = .frame(f)
            case .image(var img): img.isLocked = newValue; self = .image(img)
            }
        }
    }
    
    public var bounds: CGRect {
        switch self {
        case .stroke(let s): return s.bounds
        case .shape(let s): return s.bounds
        case .text(let t): return t.bounds
        case .sticky(let st): return st.bounds
        case .connector(let c): return c.bounds
        case .frame(let f): return f.bounds
        case .image(let img): return img.bounds
        }
    }
    
    public var groupId: UUID? {
        get {
            switch self {
            case .shape(let s): return s.groupId
            case .text(let t): return t.groupId
            case .sticky(let st): return st.groupId
            case .image(let img): return img.groupId
            default: return nil
            }
        }
        set {
            switch self {
            case .shape(var s): s.groupId = newValue; self = .shape(s)
            case .text(var t): t.groupId = newValue; self = .text(t)
            case .sticky(var st): st.groupId = newValue; self = .sticky(st)
            case .image(var img): img.groupId = newValue; self = .image(img)
            default: break
            }
        }
    }
    
    public func hits(point: Point2D) -> Bool {
        switch self {
        case .stroke(let s): return s.hits(point: point)
        case .shape(let s): return s.hits(point: point)
        case .text(let t): return t.hits(point: point)
        case .sticky(let st): return st.hits(point: point)
        case .connector(let c): return c.hits(point: point)
        case .frame(let f): return f.hits(point: point)
        case .image(let img): return img.hits(point: point)
        }
    }
    
    public func intersects(rect: CGRect) -> Bool {
        bounds.intersects(rect)
    }
    
    public func translated(by delta: CGPoint) -> CanvasElement {
        switch self {
        case .stroke(let s):
            return .stroke(s.translated(by: delta))
        case .shape(var s):
            s.origin = Point2D(x: s.origin.x + Double(delta.x), y: s.origin.y + Double(delta.y))
            if let sp = s.startPoint { s.startPoint = sp.translated(by: delta) }
            if let ep = s.endPoint { s.endPoint = ep.translated(by: delta) }
            return .shape(s)
        case .text(var t):
            t.origin = Point2D(x: t.origin.x + Double(delta.x), y: t.origin.y + Double(delta.y))
            return .text(t)
        case .sticky(var st):
            st.origin = Point2D(x: st.origin.x + Double(delta.x), y: st.origin.y + Double(delta.y))
            return .sticky(st)
        case .connector(var c):
            c.startAnchor.absolutePoint = c.startAnchor.absolutePoint.translated(by: delta)
            c.endAnchor.absolutePoint = c.endAnchor.absolutePoint.translated(by: delta)
            return .connector(c)
        case .frame(var f):
            f.origin = Point2D(x: f.origin.x + Double(delta.x), y: f.origin.y + Double(delta.y))
            return .frame(f)
        case .image(var img):
            img.origin = Point2D(x: img.origin.x + Double(delta.x), y: img.origin.y + Double(delta.y))
            return .image(img)
        }
    }
}
