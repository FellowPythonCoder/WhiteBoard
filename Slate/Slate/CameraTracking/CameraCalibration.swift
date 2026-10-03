//
//  CameraCalibration.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation

public struct ColorProfile: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name: String
    public var targetHSV: HSVColor
    public var hueTolerance: Double
    public var satTolerance: Double
    public var valTolerance: Double
    
    public init(name: String, targetHSV: HSVColor, hueTolerance: Double = 25.0, satTolerance: Double = 0.35, valTolerance: Double = 0.40) {
        self.name = name
        self.targetHSV = targetHSV
        self.hueTolerance = hueTolerance
        self.satTolerance = satTolerance
        self.valTolerance = valTolerance
    }
    
    // Built-in presets for common fingertip caps & markers
    public static let greenSticker = ColorProfile(
        name: "Green Sticker",
        targetHSV: HSVColor(hue: 130.0, saturation: 0.75, value: 0.80),
        hueTolerance: 28.0,
        satTolerance: 0.35,
        valTolerance: 0.45
    )
    
    public static let orangeCap = ColorProfile(
        name: "Orange Cap",
        targetHSV: HSVColor(hue: 25.0, saturation: 0.85, value: 0.90),
        hueTolerance: 22.0,
        satTolerance: 0.35,
        valTolerance: 0.45
    )
    
    public static let blueTape = ColorProfile(
        name: "Blue Tape",
        targetHSV: HSVColor(hue: 215.0, saturation: 0.80, value: 0.85),
        hueTolerance: 25.0,
        satTolerance: 0.35,
        valTolerance: 0.45
    )
    
    public static let defaultPresets: [ColorProfile] = [
        .greenSticker, .orangeCap, .blueTape
    ]
}
