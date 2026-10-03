//
//  MetalCanvasView.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

#if canImport(AppKit) && canImport(MetalKit)
import AppKit
import MetalKit

public final class MetalCanvasView: MTKView {
    public var renderer: MetalRenderer?
    
    public init(frame frameRect: CGRect, device: MTLDevice?) {
        let dev = device ?? MTLCreateSystemDefaultDevice()
        super.init(frame: frameRect, device: dev)
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        if self.device == nil {
            self.device = MTLCreateSystemDefaultDevice()
        }
        commonInit()
    }
    
    private func commonInit() {
        guard let dev = self.device else { return }
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.preferredFramesPerSecond = 120 // 120fps on ProMotion Macs
        self.enableSetNeedsDisplay = false
        self.isPaused = false
        
        if let rend = MetalRenderer(device: dev) {
            self.renderer = rend
            self.delegate = rend
        }
    }
}
#endif
