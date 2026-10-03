//
//  PresentationManager.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import Combine
import CoreGraphics

@MainActor
public final class PresentationManager: ObservableObject {
    @Published public var isPresenting: Bool = false
    @Published public var currentSlideIndex: Int = 0
    @Published public var orderedFrames: [FrameElement] = []
    
    public init() {}
    
    public func startPresentation(document: SlateDocument) {
        let frames = document.elements.compactMap { el -> FrameElement? in
            if case .frame(let f) = el { return f }
            return nil
        }.sorted { $0.orderIndex < $1.orderIndex }
        
        guard !frames.isEmpty else {
            // If no explicit frames exist, treat the whole board content as 1 slide
            self.orderedFrames = [FrameElement(title: document.metadata.title, origin: Point2D(x: Double(document.contentBounds.minX), y: Double(document.contentBounds.minY)), size: document.contentBounds.size)]
            self.currentSlideIndex = 0
            self.isPresenting = true
            return
        }
        
        self.orderedFrames = frames
        self.currentSlideIndex = 0
        self.isPresenting = true
    }
    
    public func endPresentation() {
        self.isPresenting = false
    }
    
    public func nextSlide() {
        guard isPresenting && !orderedFrames.isEmpty else { return }
        if currentSlideIndex < orderedFrames.count - 1 {
            currentSlideIndex += 1
        }
    }
    
    public func previousSlide() {
        guard isPresenting && !orderedFrames.isEmpty else { return }
        if currentSlideIndex > 0 {
            currentSlideIndex -= 1
        }
    }
    
    public var currentFrame: FrameElement? {
        guard isPresenting && currentSlideIndex >= 0 && currentSlideIndex < orderedFrames.count else { return nil }
        return orderedFrames[currentSlideIndex]
    }
}
