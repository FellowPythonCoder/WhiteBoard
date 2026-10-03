//
//  StyleConstants.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public enum SlateStyle {
    public static let gridUnit: CGFloat = 8.0
    public static let hairline: CGFloat = 0.5
    public static let cornerRadiusSmall: CGFloat = 6.0
    public static let cornerRadiusMedium: CGFloat = 10.0
    public static let cornerRadiusLarge: CGFloat = 14.0
    
    public static let animationDuration: Double = 0.15
    public static let animationEase = Animation.easeOut(duration: animationDuration)
    
    public static let shadowColor = Color.black.opacity(0.08)
    public static let shadowRadius: CGFloat = 8.0
    public static let shadowY: CGFloat = 3.0
}
