//
//  MetalRenderer.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

#if canImport(Metal) && canImport(MetalKit)
import Metal
import MetalKit
import simd

public struct MetalUniforms {
    public var projectionMatrix: simd_float4x4
    public var viewportSize: SIMD2<Float>
    public var viewportOffset: SIMD2<Float>
    public var zoom: Float
    public var gridSpacing: Float
    public var gridType: Int32
    public var backgroundColor: SIMD4<Float>
    public var gridColor: SIMD4<Float>
}

public final class MetalRenderer: NSObject, MTKViewDelegate {
    public let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var library: MTLLibrary?
    
    private var backgroundPipelineState: MTLRenderPipelineState?
    private var strokePipelineState: MTLRenderPipelineState?
    private var highlighterPipelineState: MTLRenderPipelineState?
    private var laserPipelineState: MTLRenderPipelineState?
    
    public var liveStroke: Stroke?
    public var laserPoints: [LaserPoint] = []
    public var document: SlateDocument?
    public var isDarkMode: Bool = false
    
    public init?(device: MTLDevice) {
        self.device = device
        guard let queue = device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        super.init()
        setupPipelines()
    }
    
    private func setupPipelines() {
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            // Attempt to load from bundle or compile from source string if needed
            return
        }
        self.library = defaultLibrary
        
        let bgVertexFunc = defaultLibrary.makeFunction(name: "backgroundVertexShader")
        let bgFragFunc = defaultLibrary.makeFunction(name: "backgroundFragmentShader")
        let strokeVertexFunc = defaultLibrary.makeFunction(name: "strokeVertexShader")
        let strokeFragFunc = defaultLibrary.makeFunction(name: "strokeFragmentShader")
        let highlighterFragFunc = defaultLibrary.makeFunction(name: "highlighterFragmentShader")
        let laserFragFunc = defaultLibrary.makeFunction(name: "laserFragmentShader")
        
        // Background pipeline
        let bgDesc = MTLRenderPipelineDescriptor()
        bgDesc.vertexFunction = bgVertexFunc
        bgDesc.fragmentFunction = bgFragFunc
        bgDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        self.backgroundPipelineState = try? device.makeRenderPipelineState(descriptor: bgDesc)
        
        // Stroke vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2 // Position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4 // Color
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].format = .float2 // UV
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<StrokeVertex>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Standard Stroke Pipeline with Alpha Blending
        let strokeDesc = MTLRenderPipelineDescriptor()
        strokeDesc.vertexFunction = strokeVertexFunc
        strokeDesc.fragmentFunction = strokeFragFunc
        strokeDesc.vertexDescriptor = vertexDescriptor
        strokeDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        strokeDesc.colorAttachments[0].isBlendingEnabled = true
        strokeDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        strokeDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        strokeDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        strokeDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        self.strokePipelineState = try? device.makeRenderPipelineState(descriptor: strokeDesc)
        
        // Highlighter Pipeline (Multiply blend mode)
        let hlDesc = MTLRenderPipelineDescriptor()
        hlDesc.vertexFunction = strokeVertexFunc
        hlDesc.fragmentFunction = highlighterFragFunc
        hlDesc.vertexDescriptor = vertexDescriptor
        hlDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        hlDesc.colorAttachments[0].isBlendingEnabled = true
        hlDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        hlDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        self.highlighterPipelineState = try? device.makeRenderPipelineState(descriptor: hlDesc)
        
        // Laser Pipeline (Additive blend mode)
        let laserDesc = MTLRenderPipelineDescriptor()
        laserDesc.vertexFunction = strokeVertexFunc
        laserDesc.fragmentFunction = laserFragFunc
        laserDesc.vertexDescriptor = vertexDescriptor
        laserDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        laserDesc.colorAttachments[0].isBlendingEnabled = true
        laserDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        laserDesc.colorAttachments[0].destinationRGBBlendFactor = .one
        self.laserPipelineState = try? device.makeRenderPipelineState(descriptor: laserDesc)
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        guard let doc = document,
              let drawable = view.currentDrawable,
              let renderPassDesc = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        let viewportSize = SIMD2<Float>(Float(view.bounds.width), Float(view.bounds.height))
        let viewportOffset = SIMD2<Float>(Float(doc.viewportOffset.x), Float(doc.viewportOffset.y))
        let zoom = Float(doc.viewportZoom)
        
        var gridTypeInt: Int32 = 0
        switch doc.gridStyle {
        case .dots: gridTypeInt = 0
        case .grid: gridTypeInt = 1
        case .lines: gridTypeInt = 2
        case .blank: gridTypeInt = 3
        }
        
        let bgColorVec: SIMD4<Float> = isDarkMode
            ? SIMD4<Float>(0.11, 0.11, 0.12, 1.0)
            : SIMD4<Float>(Float(doc.canvasBackground.red), Float(doc.canvasBackground.green), Float(doc.canvasBackground.blue), 1.0)
        
        let gridColorVec: SIMD4<Float> = isDarkMode
            ? SIMD4<Float>(0.25, 0.25, 0.27, 0.6)
            : SIMD4<Float>(0.85, 0.88, 0.90, 0.7)
        
        var uniforms = MetalUniforms(
            projectionMatrix: matrix_identity_float4x4,
            viewportSize: viewportSize,
            viewportOffset: viewportOffset,
            zoom: zoom,
            gridSpacing: Float(doc.gridSize),
            gridType: gridTypeInt,
            backgroundColor: bgColorVec,
            gridColor: gridColorVec
        )
        
        renderPassDesc.colorAttachments[0].loadAction = .clear
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColor(
            red: Double(bgColorVec.x),
            green: Double(bgColorVec.y),
            blue: Double(bgColorVec.z),
            alpha: 1.0
        )
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else {
            return
        }
        
        // 1. Draw Background
        if let bgPipe = backgroundPipelineState {
            encoder.setRenderPipelineState(bgPipe)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 0)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
        
        // 2. Draw Committed Ink Strokes
        if let strokePipe = strokePipelineState {
            encoder.setRenderPipelineState(strokePipe)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
            
            for el in doc.elements {
                if case .stroke(let stroke) = el {
                    if stroke.isHighlighter { continue }
                    let vertices = StrokeTessellator.tessellate(stroke: stroke)
                    if !vertices.isEmpty {
                        encoder.setVertexBytes(vertices, length: vertices.count * MemoryLayout<StrokeVertex>.stride, index: 0)
                        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
                    }
                }
            }
        }
        
        // 3. Draw Highlighter Strokes
        if let hlPipe = highlighterPipelineState {
            encoder.setRenderPipelineState(hlPipe)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
            
            for el in doc.elements {
                if case .stroke(let stroke) = el, stroke.isHighlighter {
                    let vertices = StrokeTessellator.tessellate(stroke: stroke)
                    if !vertices.isEmpty {
                        encoder.setVertexBytes(vertices, length: vertices.count * MemoryLayout<StrokeVertex>.stride, index: 0)
                        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
                    }
                }
            }
        }
        
        // 4. Draw Live In-Progress Stroke (Sub-10ms latency)
        if let live = liveStroke, let strokePipe = live.isHighlighter ? highlighterPipelineState : strokePipelineState {
            encoder.setRenderPipelineState(strokePipe)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
            let vertices = StrokeTessellator.tessellate(stroke: live)
            if !vertices.isEmpty {
                encoder.setVertexBytes(vertices, length: vertices.count * MemoryLayout<StrokeVertex>.stride, index: 0)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
            }
        }
        
        // 5. Draw Laser Pointer Trail
        if !laserPoints.isEmpty, let laserPipe = laserPipelineState {
            encoder.setRenderPipelineState(laserPipe)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
            let now = ProcessInfo.processInfo.systemUptime
            
            var laserStrokes: [Stroke] = []
            for i in 0..<(laserPoints.count - 1) {
                let p1 = laserPoints[i]
                let p2 = laserPoints[i + 1]
                let alpha = p2.alpha(at: now)
                if alpha > 0.05 {
                    let s = Stroke(
                        points: [p1.position, p2.position],
                        color: ColorData(red: p2.color.red, green: p2.color.green, blue: p2.color.blue, alpha: alpha),
                        width: p2.initialRadius * 2.0,
                        opacity: alpha
                    )
                    laserStrokes.append(s)
                }
            }
            
            for s in laserStrokes {
                let vertices = StrokeTessellator.tessellate(stroke: s)
                if !vertices.isEmpty {
                    encoder.setVertexBytes(vertices, length: vertices.count * MemoryLayout<StrokeVertex>.stride, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
                }
            }
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
#endif
