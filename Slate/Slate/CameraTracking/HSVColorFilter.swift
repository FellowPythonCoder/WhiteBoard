//
//  HSVColorFilter.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics
import simd

public struct HSVColor: Codable, Equatable, Sendable {
    public var hue: Double        // 0.0 ... 360.0
    public var saturation: Double // 0.0 ... 1.0
    public var value: Double      // 0.0 ... 1.0
    
    public init(hue: Double, saturation: Double, value: Double) {
        self.hue = hue
        self.saturation = max(0.0, min(1.0, saturation))
        self.value = max(0.0, min(1.0, value))
    }
    
    public init(red: Double, green: Double, blue: Double) {
        let maxV = max(red, max(green, blue))
        let minV = min(red, min(green, blue))
        let delta = maxV - minV
        
        self.value = maxV
        
        if maxV > 0.0001 {
            self.saturation = delta / maxV
        } else {
            self.saturation = 0.0
        }
        
        if delta < 0.0001 {
            self.hue = 0.0
        } else {
            var h: Double
            if red == maxV {
                h = (green - blue) / delta
            } else if green == maxV {
                h = 2.0 + (blue - red) / delta
            } else {
                h = 4.0 + (red - green) / delta
            }
            h *= 60.0
            if h < 0 { h += 360.0 }
            self.hue = h
        }
    }
    
    public func matches(target: HSVColor, hueTolerance: Double = 25.0, satTolerance: Double = 0.35, valTolerance: Double = 0.40) -> Bool {
        // Circular distance on hue circle
        var hueDiff = abs(self.hue - target.hue)
        if hueDiff > 180.0 { hueDiff = 360.0 - hueDiff }
        
        let satDiff = abs(self.saturation - target.saturation)
        let valDiff = abs(self.value - target.value)
        
        return hueDiff <= hueTolerance && satDiff <= satTolerance && valDiff <= valTolerance
    }
}

public final class HSVColorFilter {
    
    /// Converts an RGB image buffer into a binary mask buffer (1 for match, 0 for non-match)
    public static func generateMask(
        rgbBuffer: UnsafePointer<UInt8>,
        maskBuffer: UnsafeMutablePointer<UInt8>,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        targetHSV: HSVColor,
        hueTolerance: Double = 25.0,
        satTolerance: Double = 0.35,
        valTolerance: Double = 0.40
    ) {
        let totalPixels = width * height
        
        for y in 0..<height {
            let rowOffset = y * bytesPerRow
            let maskRowOffset = y * width
            
            for x in 0..<width {
                let px = rowOffset + x * 4 // Assuming BGRA or RGBA
                let r = Double(rgbBuffer[px]) / 255.0
                let g = Double(rgbBuffer[px + 1]) / 255.0
                let b = Double(rgbBuffer[px + 2]) / 255.0
                
                let hsv = HSVColor(red: r, green: g, blue: b)
                if hsv.matches(target: targetHSV, hueTolerance: hueTolerance, satTolerance: satTolerance, valTolerance: valTolerance) {
                    maskBuffer[maskRowOffset + x] = 1
                } else {
                    maskBuffer[maskRowOffset + x] = 0
                }
            }
        }
    }
}
