//
//  PresentationOverlayView.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public struct PresentationOverlayView: View {
    @ObservedObject public var presentationManager: PresentationManager
    public var onExit: () -> Void
    
    public init(presentationManager: PresentationManager, onExit: @escaping () -> Void) {
        self.presentationManager = presentationManager
        self.onExit = onExit
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Button(action: { presentationManager.previousSlide() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(presentationManager.currentSlideIndex == 0)
            .opacity(presentationManager.currentSlideIndex == 0 ? 0.3 : 1.0)
            
            Text("Slide \(presentationManager.currentSlideIndex + 1) of \(max(1, presentationManager.orderedFrames.count))")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
            
            Button(action: { presentationManager.nextSlide() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(presentationManager.currentSlideIndex >= presentationManager.orderedFrames.count - 1)
            .opacity(presentationManager.currentSlideIndex >= presentationManager.orderedFrames.count - 1 ? 0.3 : 1.0)
            
            Divider().frame(height: 16)
            
            if let frame = presentationManager.currentFrame {
                Text(frame.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onExit) {
                Label("Exit", systemImage: "xmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 480)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.92))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}
