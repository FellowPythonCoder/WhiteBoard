//
//  InspectorPanel.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public struct InspectorPanel: View {
    @Binding public var strokeColor: ColorData
    @Binding public var fillColor: ColorData
    @Binding public var strokeWidth: Double
    @Binding public var opacity: Double
    @Binding public var cornerRadius: Double
    @Binding public var fontSize: Double
    public var selectedCount: Int
    public var isLocked: Bool
    public var onAlignLeft: () -> Void
    public var onAlignCenter: () -> Void
    public var onAlignRight: () -> Void
    public var onAlignTop: () -> Void
    public var onAlignMiddle: () -> Void
    public var onAlignBottom: () -> Void
    public var onDistributeH: () -> Void
    public var onDistributeV: () -> Void
    public var onBringToFront: () -> Void
    public var onSendToBack: () -> Void
    public var onBringForward: () -> Void
    public var onSendBackward: () -> Void
    public var onToggleLock: () -> Void
    public var onDuplicate: () -> Void
    public var onDelete: () -> Void
    public var onMakeGuide: () -> Void
    
    public init(
        strokeColor: Binding<ColorData>,
        fillColor: Binding<ColorData>,
        strokeWidth: Binding<Double>,
        opacity: Binding<Double>,
        cornerRadius: Binding<Double>,
        fontSize: Binding<Double>,
        selectedCount: Int,
        isLocked: Bool,
        onAlignLeft: @escaping () -> Void,
        onAlignCenter: @escaping () -> Void,
        onAlignRight: @escaping () -> Void,
        onAlignTop: @escaping () -> Void,
        onAlignMiddle: @escaping () -> Void,
        onAlignBottom: @escaping () -> Void,
        onDistributeH: @escaping () -> Void,
        onDistributeV: @escaping () -> Void,
        onBringToFront: @escaping () -> Void,
        onSendToBack: @escaping () -> Void,
        onBringForward: @escaping () -> Void,
        onSendBackward: @escaping () -> Void,
        onToggleLock: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onMakeGuide: @escaping () -> Void
    ) {
        self._strokeColor = strokeColor
        self._fillColor = fillColor
        self._strokeWidth = strokeWidth
        self._opacity = opacity
        self._cornerRadius = cornerRadius
        self._fontSize = fontSize
        self.selectedCount = selectedCount
        self.isLocked = isLocked
        self.onAlignLeft = onAlignLeft
        self.onAlignCenter = onAlignCenter
        self.onAlignRight = onAlignRight
        self.onAlignTop = onAlignTop
        self.onAlignMiddle = onAlignMiddle
        self.onAlignBottom = onAlignBottom
        self.onDistributeH = onDistributeH
        self.onDistributeV = onDistributeV
        self.onBringToFront = onBringToFront
        self.onSendToBack = onSendToBack
        self.onBringForward = onBringForward
        self.onSendBackward = onSendBackward
        self.onToggleLock = onToggleLock
        self.onDuplicate = onDuplicate
        self.onDelete = onDelete
        self.onMakeGuide = onMakeGuide
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("\(selectedCount) Selected")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onMakeGuide) {
                    Label("Make Guide", systemImage: "sparkles")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: onToggleLock) {
                    Image(systemName: isLocked ? "lock.fill" : "lock.open")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Lock / Unlock (⌘L)")
                
                Button(action: onDuplicate) {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Duplicate (⌘D)")
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Delete (⌫)")
            }
            
            Divider()
            
            // Stroke Color Palette
            VStack(alignment: .leading, spacing: 4) {
                Text("STROKE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(ColorData.defaultPalette, id: \.self) { color in
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle().stroke(strokeColor == color ? Color.primary : Color.clear, lineWidth: 1.5)
                            )
                            .onTapGesture { strokeColor = color }
                    }
                }
            }
            
            // Stroke Width & Opacity Sliders
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Width: \(Int(strokeWidth))pt")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Slider(value: $strokeWidth, in: 1...48, step: 1)
                        .controlSize(.mini)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Opacity: \(Int(opacity * 100))%")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Slider(value: $opacity, in: 0.1...1.0, step: 0.05)
                        .controlSize(.mini)
                }
            }
            
            Divider()
            
            // Alignment and Distribute Actions
            VStack(alignment: .leading, spacing: 4) {
                Text("ALIGN & DISTRIBUTE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    Button(action: onAlignLeft) { Image(systemName: "align.horizontal.left") }.buttonStyle(.plain)
                    Button(action: onAlignCenter) { Image(systemName: "align.horizontal.center") }.buttonStyle(.plain)
                    Button(action: onAlignRight) { Image(systemName: "align.horizontal.right") }.buttonStyle(.plain)
                    Spacer()
                    Button(action: onAlignTop) { Image(systemName: "align.vertical.top") }.buttonStyle(.plain)
                    Button(action: onAlignMiddle) { Image(systemName: "align.vertical.center") }.buttonStyle(.plain)
                    Button(action: onAlignBottom) { Image(systemName: "align.vertical.bottom") }.buttonStyle(.plain)
                    Spacer()
                    Button(action: onDistributeH) { Image(systemName: "distribute.horizontal.center") }.buttonStyle(.plain)
                    Button(action: onDistributeV) { Image(systemName: "distribute.vertical.center") }.buttonStyle(.plain)
                }
                .font(.system(size: 12))
            }
            
            Divider()
            
            // Z-Order Actions
            HStack(spacing: 8) {
                Button(action: onBringToFront) { Label("Front", systemImage: "square.2.layers.3d.top.filled") }
                Button(action: onBringForward) { Label("Forward", systemImage: "arrow.up") }
                Button(action: onSendBackward) { Label("Backward", systemImage: "arrow.down") }
                Button(action: onSendToBack) { Label("Back", systemImage: "square.2.layers.3d.bottom.filled") }
            }
            .buttonStyle(.plain)
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
        .padding(10)
        .frame(width: 240)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}
