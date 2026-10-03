//
//  CameraSettingsModal.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public struct CameraSettingsModal: View {
    @ObservedObject public var cameraManager: CameraManager = .shared
    public var onClose: () -> Void
    
    @State private var selectedPreset: String = "Green Sticker"
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Camera Tracking Calibration", systemImage: "video.badge.checkmark")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 14) {
                // Presets
                VStack(alignment: .leading, spacing: 6) {
                    Text("MARKER COLOR PRESETS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(ColorProfile.defaultPresets) { profile in
                            Button(action: {
                                cameraManager.activeProfile = profile
                                selectedPreset = profile.name
                            }) {
                                Text(profile.name)
                                    .font(.system(size: 12))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(cameraManager.activeProfile.name == profile.name ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                                    .foregroundColor(cameraManager.activeProfile.name == profile.name ? .accentColor : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // Tolerance Sliders
                VStack(alignment: .leading, spacing: 8) {
                    Text("HSV COLOR TOLERANCE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Hue Tolerance:")
                            .font(.system(size: 12))
                            .frame(width: 120, alignment: .leading)
                        Slider(value: $cameraManager.activeProfile.hueTolerance, in: 5...60, step: 1)
                        Text("\(Int(cameraManager.activeProfile.hueTolerance))°")
                            .font(.system(size: 12, design: .monospaced))
                            .frame(width: 36)
                    }
                    
                    HStack {
                        Text("Saturation Tol:")
                            .font(.system(size: 12))
                            .frame(width: 120, alignment: .leading)
                        Slider(value: $cameraManager.activeProfile.satTolerance, in: 0.1...0.6, step: 0.05)
                        Text("\(Int(cameraManager.activeProfile.satTolerance * 100))%")
                            .font(.system(size: 12, design: .monospaced))
                            .frame(width: 36)
                    }
                }
                
                Divider()
                
                // Pen Point Selection
                VStack(alignment: .leading, spacing: 6) {
                    Text("GESTURE RULES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Picker("Pen Point:", selection: $cameraManager.stateMachine.penPointMode) {
                        Text("Topmost Marker").tag(PenPointSelection.topmost)
                        Text("Midpoint of Markers").tag(PenPointSelection.midpoint)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Test Mode
                Toggle("Test Mode (Practice gestures with no ink)", isOn: $cameraManager.stateMachine.isTestModeNoInk)
                    .font(.system(size: 12))
            }
            .padding(16)
        }
        .frame(width: 420)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}
