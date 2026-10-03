//
//  CameraPiPView.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public struct CameraPiPView: View {
    @ObservedObject public var cameraManager: CameraManager = .shared
    public var onOpenSettings: () -> Void
    
    public init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Live Preview Frame & Gesture Status Badge
            ZStack(alignment: .topTrailing) {
                // Background Preview Area
                ZStack {
                    Color.black.opacity(0.85)
                    
                    // Active Area Boundary
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .padding(12)
                    
                    // Fingertip cursor point
                    Circle()
                        .fill(cursorColor)
                        .frame(width: 10, height: 10)
                        .position(
                            x: 160 * cameraManager.fingertipCanvasPoint.x,
                            y: 100 * cameraManager.fingertipCanvasPoint.y
                        )
                }
                .frame(width: 160, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Status Badge
                HStack(spacing: 4) {
                    Image(systemName: cameraManager.currentGestureMode.iconName)
                        .font(.system(size: 9, weight: .bold))
                    Text(cameraManager.currentGestureMode.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(badgeBackgroundColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(6)
            }
            
            // Bottom Controls
            HStack {
                Text(cameraManager.activeProfile.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .frame(width: 176)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
    }
    
    private var badgeBackgroundColor: Color {
        switch cameraManager.currentGestureMode {
        case .draw: return Color(hex: "#059669")
        case .erase: return Color(hex: "#E05D52")
        case .hover: return Color(hex: "#475569")
        }
    }
    
    private var cursorColor: Color {
        switch cameraManager.currentGestureMode {
        case .draw: return .green
        case .erase: return .red
        case .hover: return .yellow
        }
    }
}

private extension Color {
    init(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") { cleanHex.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
