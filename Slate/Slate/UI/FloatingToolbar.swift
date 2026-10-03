//
//  FloatingToolbar.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public struct FloatingToolbar: View {
    @Binding public var activeTool: CanvasTool
    @Binding public var strokeColor: ColorData
    @Binding public var strokeWidth: Double
    @Binding public var opacity: Double
    public var canUndo: Bool
    public var canRedo: Bool
    public var onUndo: () -> Void
    public var onRedo: () -> Void
    public var onToggleLibrary: () -> Void
    public var onToggleCamera: () -> Void
    public var isCameraActive: Bool
    public var isDrawing: Bool
    
    private let primaryTools: [CanvasTool] = [
        .select, .pen, .highlighter, .strokeEraser, .pixelEraser,
        .rectangle, .ellipse, .line, .arrow, .diamond, .triangle,
        .text, .sticky, .connector, .laser, .hand, .frame, .lasso, .eyedropper
    ]
    
    public init(
        activeTool: Binding<CanvasTool>,
        strokeColor: Binding<ColorData>,
        strokeWidth: Binding<Double>,
        opacity: Binding<Double>,
        canUndo: Bool,
        canRedo: Bool,
        onUndo: @escaping () -> Void,
        onRedo: @escaping () -> Void,
        onToggleLibrary: @escaping () -> Void,
        onToggleCamera: @escaping () -> Void,
        isCameraActive: Bool,
        isDrawing: Bool
    ) {
        self._activeTool = activeTool
        self._strokeColor = strokeColor
        self._strokeWidth = strokeWidth
        self._opacity = opacity
        self.canUndo = canUndo
        self.canRedo = canRedo
        self.onUndo = onUndo
        self.onRedo = onRedo
        self.onToggleLibrary = onToggleLibrary
        self.onToggleCamera = onToggleCamera
        self.isCameraActive = isCameraActive
        self.isDrawing = isDrawing
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            // Library Button
            Button(action: onToggleLibrary) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Board Library (⌘L)")
            
            Divider().frame(height: 16).padding(.horizontal, 2)
            
            // Undo / Redo
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 12))
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .disabled(!canUndo)
            .opacity(canUndo ? 1.0 : 0.35)
            .help("Undo (⌘Z)")
            
            Button(action: onRedo) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 12))
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .disabled(!canRedo)
            .opacity(canRedo ? 1.0 : 0.35)
            .help("Redo (⇧⌘Z)")
            
            Divider().frame(height: 16).padding(.horizontal, 2)
            
            // Core Tool Buttons
            ForEach(primaryTools, id: \.self) { tool in
                Button(action: { activeTool = tool }) {
                    Image(systemName: tool.iconName)
                        .font(.system(size: 13, weight: activeTool == tool ? .bold : .regular))
                        .foregroundColor(activeTool == tool ? .accentColor : .primary)
                        .frame(width: 28, height: 28)
                        .background(activeTool == tool ? Color.accentColor.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("\(tool.rawValue) (\(tool.shortcutDisplay))")
            }
            
            Divider().frame(height: 16).padding(.horizontal, 2)
            
            // Color Presets in Toolbar
            HStack(spacing: 3) {
                ForEach([ColorData.ink, ColorData.coral, ColorData.emerald, ColorData.cobalt], id: \.self) { color in
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(strokeColor == color ? Color.primary : Color.clear, lineWidth: 1.5)
                        )
                        .onTapGesture { strokeColor = color }
                }
            }
            .padding(.horizontal, 4)
            
            Divider().frame(height: 16).padding(.horizontal, 2)
            
            // Camera Tracking Toggle Button
            Button(action: onToggleCamera) {
                Image(systemName: isCameraActive ? "video.fill" : "video")
                    .font(.system(size: 13))
                    .foregroundColor(isCameraActive ? .green : .secondary)
                    .frame(width: 28, height: 28)
                    .background(isCameraActive ? Color.green.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .help("Toggle Camera Finger Tracking (⌥C)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: SlateStyle.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: SlateStyle.cornerRadiusMedium)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: SlateStyle.shadowColor, radius: SlateStyle.shadowRadius, x: 0, y: SlateStyle.shadowY)
        .opacity(isDrawing ? 0.25 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isDrawing)
    }
}
