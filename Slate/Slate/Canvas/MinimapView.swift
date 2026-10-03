//
//  MinimapView.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI
import CoreGraphics

public struct MinimapView: View {
    @Binding public var document: SlateDocument
    public var onNavigate: (Point2D) -> Void
    
    private let minimapWidth: CGFloat = 180
    private let minimapHeight: CGFloat = 120
    
    public init(document: Binding<SlateDocument>, onNavigate: @escaping (Point2D) -> Void) {
        self._document = document
        self.onNavigate = onNavigate
    }
    
    public var body: some View {
        Canvas { context, size in
            let bounds = document.contentBounds
            guard bounds.width > 0 && bounds.height > 0 else { return }
            
            let scaleX = size.width / bounds.width
            let scaleY = size.height / bounds.height
            let scale = min(scaleX, scaleY) * 0.85
            
            let offsetX = (size.width - bounds.width * scale) / 2.0 - bounds.minX * scale
            let offsetY = (size.height - bounds.height * scale) / 2.0 - bounds.minY * scale
            
            // Draw element representations
            for el in document.elements {
                let elBounds = el.bounds
                let r = CGRect(
                    x: elBounds.minX * scale + offsetX,
                    y: elBounds.minY * scale + offsetY,
                    width: max(2, elBounds.width * scale),
                    height: max(2, elBounds.height * scale)
                )
                context.fill(Path(r), with: .color(.gray.opacity(0.4)))
            }
            
            // Draw Viewport Box
            let vpOriginX = (-document.viewportOffset.x) * scale + offsetX
            let vpOriginY = (-document.viewportOffset.y) * scale + offsetY
            let vpWidth = (size.width / CGFloat(document.viewportZoom)) * scale
            let vpHeight = (size.height / CGFloat(document.viewportZoom)) * scale
            
            let vpRect = CGRect(x: vpOriginX, y: vpOriginY, width: vpWidth, height: vpHeight)
            context.stroke(Path(vpRect), with: .color(.accentColor), lineWidth: 1.5)
        }
        .frame(width: minimapWidth, height: minimapHeight)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let bounds = document.contentBounds
                    let scaleX = minimapWidth / bounds.width
                    let scaleY = minimapHeight / bounds.height
                    let scale = min(scaleX, scaleY) * 0.85
                    
                    let targetX = (Double(value.location.x) / Double(scale)) + Double(bounds.minX)
                    let targetY = (Double(value.location.y) / Double(scale)) + Double(bounds.minY)
                    onNavigate(Point2D(x: -targetX, y: -targetY))
                }
        )
    }
}
