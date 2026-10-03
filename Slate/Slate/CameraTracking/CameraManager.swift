//
//  CameraManager.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics
import Combine
#if canImport(AVFoundation)
import AVFoundation
#endif

@MainActor
public final class CameraManager: NSObject, ObservableObject, CameraTrackingService {
    public static let shared = CameraManager()
    
    @Published public var isTrackingEnabled: Bool = false
    @Published public var currentGestureMode: CameraGestureMode = .hover
    @Published public var fingertipCanvasPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @Published public var activeProfile: ColorProfile = .greenSticker
    @Published public var isCameraAvailable: Bool = false
    @Published public var markerTrail: [CGPoint] = []
    
    public let stateMachine = GestureStateMachine()
    private let processingQueue = DispatchQueue(label: "com.slate.camera.processing", qos: .userInteractive)
    
    #if canImport(AVFoundation)
    private var captureSession: AVCaptureSession?
    #endif
    
    override public init() {
        super.init()
    }
    
    public func startTracking() {
        #if canImport(AVFoundation)
        setupCaptureSession()
        #endif
        isTrackingEnabled = true
    }
    
    public func stopTracking() {
        #if canImport(AVFoundation)
        captureSession?.stopRunning()
        captureSession = nil
        #endif
        isTrackingEnabled = false
        currentGestureMode = .hover
    }
    
    public func processFrame(
        rgbBuffer: UnsafePointer<UInt8>,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        timestamp: TimeInterval
    ) -> CameraFrameTrackingResult {
        var maskBuffer = [UInt8](repeating: 0, count: width * height)
        
        maskBuffer.withUnsafeMutableBufferPointer { maskPtr in
            HSVColorFilter.generateMask(
                rgbBuffer: rgbBuffer,
                maskBuffer: maskPtr.baseAddress!,
                width: width,
                height: height,
                bytesPerRow: bytesPerRow,
                targetHSV: activeProfile.targetHSV,
                hueTolerance: activeProfile.hueTolerance,
                satTolerance: activeProfile.satTolerance,
                valTolerance: activeProfile.valTolerance
            )
        }
        
        let blobs = maskBuffer.withUnsafeBufferPointer { maskPtr in
            BlobDetector.detectBlobs(maskBuffer: maskPtr.baseAddress!, width: width, height: height)
        }
        
        let (mode, pos) = stateMachine.update(blobs: blobs, timestamp: timestamp)
        return CameraFrameTrackingResult(gestureMode: mode, fingertipPosition: pos, rawBlobs: blobs, timestamp: timestamp)
    }
    
    #if canImport(AVFoundation)
    private func setupCaptureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.initCapturePipeline()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.initCapturePipeline() }
                }
            }
        default:
            break
        }
    }
    
    private func initCapturePipeline() {
        let session = AVCaptureSession()
        session.sessionPreset = .vga640x480
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: processingQueue)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        self.captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        self.isCameraAvailable = true
    }
    #endif
}

#if canImport(AVFoundation)
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        
        let typedPtr = baseAddress.assumingMemoryBound(to: UInt8.self)
        let result = processFrame(rgbBuffer: typedPtr, width: width, height: height, bytesPerRow: bytesPerRow, timestamp: ts)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentGestureMode = result.gestureMode
            self.fingertipCanvasPoint = result.fingertipPosition
            self.markerTrail.append(result.fingertipPosition)
            if self.markerTrail.count > 30 {
                self.markerTrail.removeFirst()
            }
        }
    }
}
#endif
