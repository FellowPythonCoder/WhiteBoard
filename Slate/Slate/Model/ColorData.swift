//
//  ColorData.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

/// A deterministic, serializable RGBA color value with conversions to/from NSColor and SwiftUI.Color.
public struct ColorData: Codable, Equatable, Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double
    
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = max(0.0, min(1.0, red))
        self.green = max(0.0, min(1.0, green))
        self.blue = max(0.0, min(1.0, blue))
        self.alpha = max(0.0, min(1.0, alpha))
    }
    
    public init(hex: String, alpha: Double = 1.0) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)
        
        if cleanHex.count == 6 {
            self.red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            self.green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            self.blue = Double(rgbValue & 0x0000FF) / 255.0
            self.alpha = alpha
        } else if cleanHex.count == 8 {
            self.red = Double((rgbValue & 0xFF000000) >> 24) / 255.0
            self.green = Double((rgbValue & 0x00FF0000) >> 16) / 255.0
            self.blue = Double((rgbValue & 0x0000FF00) >> 8) / 255.0
            self.alpha = Double(rgbValue & 0x000000FF) / 255.0
        } else {
            self.red = 0.0
            self.green = 0.0
            self.blue = 0.0
            self.alpha = alpha
        }
    }
    
    public var hexString: String {
        let r = Int(round(red * 255.0))
        let g = Int(round(green * 255.0))
        let b = Int(round(blue * 255.0))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    public var cgColor: CGColor {
        CGColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    #if canImport(AppKit)
    public var nsColor: NSColor {
        NSColor(calibratedRed: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    public init(nsColor: NSColor) {
        if let rgb = nsColor.usingColorSpace(.sRGB) {
            self.red = Double(rgb.redComponent)
            self.green = Double(rgb.greenComponent)
            self.blue = Double(rgb.blueComponent)
            self.alpha = Double(rgb.alphaComponent)
        } else {
            self.red = 0; self.green = 0; self.blue = 0; self.alpha = 1
        }
    }
    #endif
    
    #if canImport(SwiftUI)
    public var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    #endif
    
    // MARK: - Restrained, Minimalist Slate Palette
    public static let black = ColorData(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
    public static let white = ColorData(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    public static let clear = ColorData(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    
    public static let slateGray = ColorData(hex: "#64748B")
    public static let charcoal = ColorData(hex: "#1E293B")
    public static let mutedBorder = ColorData(hex: "#E2E8F0")
    
    // Editorial & Diagram Palette (Restrained, subtle)
    public static let ink = ColorData(hex: "#0F172A")
    public static let graphite = ColorData(hex: "#475569")
    public static let coral = ColorData(hex: "#E05D52")
    public static let amber = ColorData(hex: "#D97706")
    public static let emerald = ColorData(hex: "#059669")
    public static let teal = ColorData(hex: "#0D9488")
    public static let cobalt = ColorData(hex: "#2563EB")
    public static let indigo = ColorData(hex: "#4F46E5")
    public static let wine = ColorData(hex: "#9F1239")
    
    // Highlighter Yellow, Green, Pink, Blue
    public static let highlightYellow = ColorData(red: 0.98, green: 0.90, blue: 0.25, alpha: 0.35)
    public static let highlightGreen = ColorData(red: 0.30, green: 0.85, blue: 0.40, alpha: 0.35)
    public static let highlightPink = ColorData(red: 0.98, green: 0.40, blue: 0.60, alpha: 0.35)
    public static let highlightBlue = ColorData(red: 0.30, green: 0.70, blue: 0.95, alpha: 0.35)
    
    // Sticky Note Tints (Light pastel backgrounds)
    public static let stickyYellow = ColorData(hex: "#FEF08A")
    public static let stickyGreen = ColorData(hex: "#BBF7D0")
    public static let stickyBlue = ColorData(hex: "#BAE6FD")
    public static let stickyPink = ColorData(hex: "#FBCFE8")
    public static let stickyOrange = ColorData(hex: "#FED7AA")
    public static let stickyPurple = ColorData(hex: "#E9D5FF")
    public static let stickyGray = ColorData(hex: "#F1F5F9")
    
    public static let defaultPalette: [ColorData] = [
        .ink, .graphite, .coral, .amber, .emerald, .teal, .cobalt, .indigo, .wine
    ]
}
